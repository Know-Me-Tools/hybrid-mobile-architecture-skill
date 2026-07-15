# Rust Core Patterns Reference
> gen_ui_core · Rust 1.93+ · Tokio 1.40 · candle 0.7 · **SurrealDB 3.2** · flutter_rust_bridge 2.12 · Tauri 2.x

## Workspace layout (layered — compile-cache friendly)

The Rust code is a **layered workspace**, not a single crate. Trait boundaries live in
`gen_ui_types` (frozen after c001) so downstream crates develop in parallel worktrees without
conflicts, and heavy dependencies (SurrealDB, candle) sit in leaf crates that cache
independently. See `references/rust/compile-speed.md` for the caching rationale — SurrealDB is
isolated in its own crate specifically because `surrealdb-core`'s `build.rs` re-run issue
(#6954) causes long recompiles otherwise.

```
rust/
  gen_ui_types/        # shared traits + newtypes + enums (FROZEN seam — c001)
  gen_ui_protocol/     # A2UI / AG-UI adapters, ProtocolPipeline
  gen_ui_client/       # Anthropic HTTP/2 + SSE client
  gen_ui_inference/    # candle InferenceEngine (CPU-bound → spawn_blocking)
  gen_ui_mcp/          # McpClient + McpRegistry (SSE / stdio transports)
  gen_ui_db/           # SurrealDB 3.2 (MemoryStore, EntityGraph) — ISOLATED for caching
  gen_ui_agent/        # PMPO loop (UAR embedded)
  gen_ui_core/         # composition crate: runtime, config, re-exports for leaves
  gen_ui_ffi/          # flutter_rust_bridge surface (leaf)
  tauri-plugin-gen-ui/ # Tauri commands/events/permissions (leaf)
  gen_ui_wasm/         # wasm-bindgen surface (leaf)
```

Core crates (`gen_ui_types` … `gen_ui_agent`) compile to **native AND wasm32**. Leaves are
platform-specific. Isolating `gen_ui_db` keeps SurrealDB's slow build out of the app-code
inner loop.

## Cargo.toml (workspace — current July 2026)

```toml
[workspace]
members = [
  "rust/gen_ui_types", "rust/gen_ui_protocol", "rust/gen_ui_client",
  "rust/gen_ui_inference", "rust/gen_ui_mcp", "rust/gen_ui_db",
  "rust/gen_ui_agent", "rust/gen_ui_core", "rust/gen_ui_ffi",
  "rust/tauri-plugin-gen-ui", "rust/gen_ui_wasm",
]
resolver = "2"

[workspace.package]
version = "0.1.0"
edition = "2021"
rust-version = "1.93"

[workspace.dependencies]
tokio          = { version = "1.40",  features = ["full"] }
tokio-stream   = { version = "0.1",   features = ["sync"] }
futures        = "0.3"
flutter_rust_bridge = { version = "2.12", features = ["dart-opaque", "anyhow"] }
reqwest        = { version = "0.12",  features = ["json", "stream", "rustls-tls"], default-features = false }
reqwest-eventsource = "0.6"
serde          = { version = "1.0",   features = ["derive"] }
serde_json     = "1.0"
candle-core    = { version = "0.7",   features = ["metal", "accelerate"] }
candle-nn      = "0.7"
candle-transformers = "0.7"
hf-hub         = { version = "0.3",   features = ["tokio"] }
tokenizers     = { version = "0.20",  features = ["http"] }
# SurrealDB 3.2 — native uses kv-rocksdb; wasm32 uses kv-indxdb (set per-crate/target).
surrealdb      = { version = "3.2",   features = ["kv-rocksdb"] }
rayon          = "1.10"
dashmap        = "6.1"
parking_lot    = "0.12"
tracing        = "0.1"
anyhow         = "1.0"
thiserror      = "1.0"
uuid           = { version = "1.10",  features = ["v4", "fast-rng"] }
chrono         = { version = "0.4",   features = ["serde"] }
once_cell      = "1.20"
async-trait    = "0.1"
```

For the wasm32 target, `gen_ui_db` selects the indxdb engine instead of rocksdb:

```toml
# rust/gen_ui_db/Cargo.toml
[target.'cfg(not(target_arch = "wasm32"))'.dependencies]
surrealdb = { workspace = true, features = ["kv-rocksdb"] }

[target.'cfg(target_arch = "wasm32")'.dependencies]
surrealdb = { version = "3.2", default-features = false, features = ["kv-indxdb"] }
```

## gen_ui_core module structure (composition crate)

The single-crate layout below still describes `gen_ui_core`'s internal modules; in the
layered workspace, `protocol/`, `inference/`, `mcp/`, and `db/` are separate crates that
`gen_ui_core` composes and re-exports.

```
gen_ui_core/src/
  lib.rs              # module declarations / re-exports
  api.rs              # (moved to gen_ui_ffi) FFI surface for Flutter
                      # (moved to tauri-plugin-gen-ui) Tauri commands/events for desktop
  api_http.rs         # Anthropic HTTP/2 client (gen_ui_client)
  runtime.rs          # global Tokio runtime (one per process)
  streaming.rs        # SSE parser → StreamEvent sealed enum
  config.rs           # UarMode, feature flags
  protocol/           # → gen_ui_protocol
    mod.rs            # ProtocolPipeline (dual broadcast channels)
    a2ui.rs           # A2UI adapter + 27-variant event enum
    agui.rs           # AG-UI adapter + bidirectional events
  agent/mod.rs        # → gen_ui_agent — PMPO loop (UAR embedded)
  inference/          # → gen_ui_inference
    mod.rs            # InferenceEngine, ModelId, ChatTemplate
    sampler.rs        # temperature / top-p / top-k
  mcp/                # → gen_ui_mcp
    mod.rs            # McpClient + McpRegistry
    sse_transport.rs  # HTTP SSE transport
    stdio_transport.rs
  db/mod.rs           # → gen_ui_db — SurrealDB 3.2 (MemoryStore, EntityGraph)
```

## FFI surface rules (api.rs)

The FFI surface is the ONLY file flutter_rust_bridge processes. Keep it clean:

```rust
// ✓ Correct: clean FFI types, no complex lifetimes
pub struct FrbAgentConfig {
    pub model: String,
    pub max_tokens: u32,
    // ... simple owned types only
}

// ✓ Correct: async fn → Dart Future
pub async fn stream_agent_a2ui(
    messages: Vec<String>,
    user_message: String,
    config: FrbAgentConfig,
    sink: flutter_rust_bridge::StreamSink<FrbA2uiEvent>,
) -> anyhow::Result<()> { ... }

// ✗ Wrong: complex types, references, Box<dyn>
pub fn bad_api(handler: Box<dyn Fn()>) -> &str { ... }
```

## Tauri commands (for desktop builds)

```rust
// src-tauri/src/commands.rs — Tauri-specific API surface
// (separate from api.rs which is for Flutter FFI)

#[tauri::command]
async fn stream_agent_a2ui(
    app: tauri::AppHandle,
    state: tauri::State<'_, AppState>,
    user_message: String,
    messages: Vec<String>,
    config: FrbAgentConfig,
) -> Result<(), String> {
    let (raw_tx, raw_rx) = mpsc::channel::<StreamEvent>(256);
    let pipeline = ProtocolPipeline::new(Uuid::new_v4().to_string());
    let mut a2ui_rx = pipeline.subscribe_a2ui();

    runtime::spawn(async move { pipeline.drive(raw_rx).await });

    let client = state.anthropic_client.clone();
    runtime::spawn(async move {
        let agent = AgentRuntime::new(/* ... */);
        let _ = agent.run(pairs(messages), user_message, raw_tx).await;
    });

    // Forward A2UI events via Tauri emit
    loop {
        match a2ui_rx.recv().await {
            Ok(ev) => {
                let done = matches!(ev, A2uiEvent::RunFinished { .. });
                app.emit("a2ui_event", FrbA2uiEvent::from(ev)).map_err(|e| e.to_string())?;
                if done { break; }
            }
            Err(_) => break,
        }
    }
    Ok(())
}
```

## UAR configuration

```rust
// config.rs
#[derive(Debug, Clone, serde::Deserialize)]
pub enum UarMode {
    /// PMPO loop, MCP registry, and protocol pipeline run in-process
    Embedded,
    /// Connect to external UAR service via HTTP
    External {
        url: String,
        api_key: Option<String>,
        timeout_secs: u64,
    },
}

pub struct AppConfig {
    pub uar_mode: UarMode,
    pub anthropic_api_key: String,
    pub data_dir: std::path::PathBuf,
    pub db_path: Option<std::path::PathBuf>,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            uar_mode: UarMode::Embedded, // default: embedded
            anthropic_api_key: std::env::var("ANTHROPIC_API_KEY").unwrap_or_default(),
            data_dir: dirs::data_dir().unwrap_or_default().join("gen_ui"),
            db_path: None,
        }
    }
}
```

## Adding a new ContentBlock type (full stack — 7 steps)

See the complete guide in `references/rust/new-block-type.md`.

**Summary:**
1. Add `StreamEvent` variant in `streaming.rs`
2. Add `A2uiEvent` variant in `protocol/a2ui.rs` + ingestion in `A2uiAdapter::ingest()`
3. Add AG-UI translation in `protocol/agui.rs` + `AguiAdapter::translate()`
4. Run `flutter_rust_bridge_codegen generate` (Flutter) or update Tauri commands
5. Add Dart sealed class in `bridge/a2ui/a2ui_event.dart` (Flutter)
   OR TypeScript type in `bridge/a2ui/types.ts` (Tauri)
6. Add driver case in `A2uiContentDriver._handle()` ← compiler enforces
7. Add `ContentBlock` variant → widget/component ← compiler enforces

## Local model catalog

| Rust ModelId | HF Repo | GGUF Size | Best for |
|---|---|---|---|
| `Qwen2_5_0_5B` | Qwen/Qwen2.5-0.5B-Instruct-GGUF | ~400MB | Ultra-fast |
| `Qwen2_5_1_5B` | Qwen/Qwen2.5-1.5B-Instruct-GGUF | ~1.0GB | Quality+speed |
| `Phi3_5Mini` | bartowski/Phi-3.5-mini-instruct-GGUF | ~2.2GB | Best reasoning |
| `Llama3_2_1B` | bartowski/Llama-3.2-1B-Instruct-GGUF | ~650MB | Llama compact |
| `Llama3_2_3B` | bartowski/Llama-3.2-3B-Instruct-GGUF | ~1.8GB | Strong 3B |
| `Gemma2_2B` | bartowski/gemma-2-2b-it-GGUF | ~1.5GB | Google instruction |
| `SmolLm2_1_7B` | HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF | ~1.1GB | Compact+capable |

## SurrealDB 3.2 embedded graph RAG (`gen_ui_db`)

SurrealDB provides the graph + vector + full-text layer for memory and the entity graph on
every target: `kv-rocksdb` native (iOS / Android / desktop), `kv-indxdb` on wasm32. It lives
in its own crate (`gen_ui_db`) for compile caching (build.rs issue #6954).

### 2.x → 3.x breaking changes that touch our schema / DDL

The reference schemas and scaffold templates must use the **3.x** forms — the 2.x forms below
no longer compile against SurrealDB 3.2:

| Concern | 2.x (removed) | **3.2 (use this)** |
|---|---|---|
| Vector index | `MTREE` | **`HNSW`** — `DEFINE INDEX … HNSW DIMENSION 384 DIST COSINE` |
| Full-text | `SEARCH ANALYZER` | **`FULLTEXT ANALYZER`** |
| Record ctor fn | `type::thing(...)` | **`type::record(...)`** |
| Random id fn | `rand::guid()` | **`rand::id()`** |
| Variables | (optional) | **`LET` required** |
| KNN operator | — | **`<|K,EF|>`** (e.g. `<|8,64|>`) |

Writes are **synced by default** in 3.x (slower but durable); keep bulk ingestion off the hot
path. There is **no in-place 2.x→3.x RocksDB upgrade** — migrate via in-app export→import.

### Schema (3.2 DDL)

```sql
-- entity table with a 384-dim embedding (matryoshka-truncated ok)
DEFINE TABLE entity SCHEMAFULL;
DEFINE FIELD name      ON entity TYPE string;
DEFINE FIELD kind      ON entity TYPE string;
DEFINE FIELD embedding ON entity TYPE array<float>;
DEFINE FIELD body      ON entity TYPE option<string>;

-- HNSW vector index (replaces MTREE); COSINE distance, 384 dims
DEFINE INDEX entity_hnsw ON entity FIELDS embedding HNSW DIMENSION 384 DIST COSINE;

-- BM25 full-text lane (FULLTEXT replaces SEARCH ANALYZER)
DEFINE ANALYZER content_analyzer TOKENIZERS blank,class FILTERS lowercase,ascii;
DEFINE INDEX entity_ft ON entity FIELDS body FULLTEXT ANALYZER content_analyzer BM25;

-- graph edge
DEFINE TABLE relates_to SCHEMALESS TYPE RELATION IN entity OUT entity;
```

### Graph RAG pattern (verified)

HNSW vector recall → `RELATE` graph expansion (recursive) → BM25 full-text lane →
reciprocal-rank fusion **in Rust**:

```sql
-- vector recall: KNN operator with ef search width
LET $q = $query_embedding;
SELECT id, name, vector::distance::knn() AS dist
FROM entity
WHERE embedding <|8,64|> $q
ORDER BY dist ASC;

-- graph expansion (recursive 1..3 hops)
SELECT * FROM entity:⟨seed⟩.{1..3}(->relates_to->entity);

-- full-text lane
SELECT id, name, search::score(0) AS score
FROM entity WHERE body @0@ $terms ORDER BY score DESC;
```

Fuse the three result sets (reciprocal-rank fusion) in Rust; do not push fusion into
SurrealQL.

### FFI / layer contract (BLOCKING)

**Dart never sees raw SurrealQL.** There is no embedded Dart SDK (the pub.dev community
package is WebSocket-only). `gen_ui_db` exposes **intent-level functions** over the FFI
surface — `memory_search(query, k)`, `graph_expand(id, depth)`, `upsert_entity(...)` — and
those are what `gen_ui_ffi` / `tauri-plugin-gen-ui` re-export. Raw query strings stay in Rust.

```rust
// gen_ui_db intent API — the ONLY graph surface the UI layers see
pub async fn memory_search(query: &str, k: usize) -> anyhow::Result<Vec<EntityHit>>;
pub async fn graph_expand(id: &RecordId, depth: u8) -> anyhow::Result<Vec<EntityHit>>;
pub async fn upsert_entity(name: &str, kind: &str, embedding: Vec<f32>) -> anyhow::Result<RecordId>;
```
