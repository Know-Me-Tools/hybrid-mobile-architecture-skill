# Rust Core Patterns Reference
> gen_ui_core · Rust 1.80+ · Tokio 1.40 · candle 0.7 · SurrealDB 2.0 · Tauri 2.x

## Cargo.toml (workspace — current March 2026)

```toml
[workspace]
members = ["gen_ui_core"]
resolver = "2"

[workspace.package]
version = "0.1.0"
edition = "2021"
rust-version = "1.80"

[workspace.dependencies]
tokio          = { version = "1.40",  features = ["full"] }
tokio-stream   = { version = "0.1",   features = ["sync"] }
futures        = "0.3"
flutter_rust_bridge = { version = "2.3", features = ["dart-opaque", "anyhow"] }
reqwest        = { version = "0.12",  features = ["json", "stream", "rustls-tls"], default-features = false }
reqwest-eventsource = "0.6"
serde          = { version = "1.0",   features = ["derive"] }
serde_json     = "1.0"
candle-core    = { version = "0.7",   features = ["metal", "accelerate"] }
candle-nn      = "0.7"
candle-transformers = "0.7"
hf-hub         = { version = "0.3",   features = ["tokio"] }
tokenizers     = { version = "0.20",  features = ["http"] }
surrealdb      = { version = "2.0",   features = ["kv-rocksdb"] }
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

## Module structure

```
gen_ui_core/src/
  lib.rs              # module declarations
  api.rs              # FFI surface (frb codegen target for Flutter)
                      # OR Tauri commands/events for desktop
  api_http.rs         # Anthropic HTTP/2 client
  runtime.rs          # global Tokio runtime (one per process)
  streaming.rs        # SSE parser → StreamEvent sealed enum
  config.rs           # UarMode, feature flags
  protocol/
    mod.rs            # ProtocolPipeline (dual broadcast channels)
    a2ui.rs           # A2UI adapter + 27-variant event enum
    agui.rs           # AG-UI adapter + bidirectional events
  agent/mod.rs        # PMPO loop (UAR embedded)
  inference/
    mod.rs            # InferenceEngine, ModelId, ChatTemplate
    sampler.rs        # temperature / top-p / top-k
  mcp/
    mod.rs            # McpClient + McpRegistry
    sse_transport.rs  # HTTP SSE transport
    stdio_transport.rs
  db/mod.rs           # SurrealDB (MemoryStore, ToolCache, EntityGraph)
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
