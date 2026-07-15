#!/usr/bin/env bash
# scripts/scaffold-rust-core.sh
# Scaffold the gen_ui_core LAYERED Rust workspace (TJ-ARCH-MOB-001).
# C-001: replaces the former monolithic single-crate scaffold with a layered,
# wasm-capable, worktree-parallelizable workspace.
#
# Usage: bash scripts/scaffold-rust-core.sh <output-dir> [embedded|external]
#
# Layers (L(n) depends only on L(<n); leaves depend on anything):
#   L0  gen_ui_types      pure types + ALL cross-crate traits (frozen seams). wasm-safe.
#   L1  gen_ui_runtime    native Tokio / wasm spawn_local abstraction
#   L1  gen_ui_protocol   A2UI/AG-UI adapters over futures channels. wasm-safe.
#   L2  gen_ui_client     Anthropic + Flint HTTP/SSE behind Transport trait
#   L2  gen_ui_mcp        MCP client (sse wasm-safe; stdio native-only)
#   L2  gen_ui_db         relational (pg/sqlite) + graph (surreal) + sync
#   L2  gen_ui_inference  candle GGUF (native accel; wasm feature-gated off)
#   L3  gen_ui_agent      PMPO loop over L0-L2 abstractions
#   LEAF gen_ui_ffi              flutter_rust_bridge surface
#   LEAF tauri-plugin-gen-ui     Tauri 2 plugin
#   LEAF gen_ui_wasm             wasm-bindgen/web surface
#   ---  workspace-hack          cargo-hakari feature unification pin
set -euo pipefail

OUT="${1:-rust}"
UAR_MODE="${2:-embedded}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }

MARK="// TJ-ARCH-MOB-001 compliant"

step "Scaffolding layered gen_ui workspace: $OUT (UAR: $UAR_MODE)"
mkdir -p "$OUT/crates"

# ── Workspace root Cargo.toml ────────────────────────────────────────────────
cat > "$OUT/Cargo.toml" << 'EOF'
[workspace]
resolver = "2"
members = [
    "crates/gen_ui_types",
    "crates/gen_ui_runtime",
    "crates/gen_ui_protocol",
    "crates/gen_ui_client",
    "crates/gen_ui_mcp",
    "crates/gen_ui_db",
    "crates/gen_ui_inference",
    "crates/gen_ui_agent",
    "crates/gen_ui_ffi",
    "crates/tauri-plugin-gen-ui",
    "crates/gen_ui_wasm",
    "crates/workspace-hack",
]

[workspace.package]
version = "0.1.0"
edition = "2021"
# MSRV floor. 1.80 (the original TJ-ARCH-MOB-001 minimum) can no longer resolve the
# current dependency graph — transitive crates (e.g. chacha20 ≥0.10) now require the
# edition2024 Cargo feature, unparseable before Cargo 1.85. 1.93 is the realistic
# mid-2026 floor. Keep in sync with rust-toolchain.toml and CLAUDE.md tool versions.
rust-version = "1.93"
license = "MIT OR Apache-2.0"

[workspace.dependencies]
# --- shared, workspace-wide (each crate opts in via `.workspace = true`) ---
serde             = { version = "1.0",  features = ["derive"] }
serde_json        = "1.0"
thiserror         = "1.0"
anyhow            = "1.0"
futures           = "0.3"
async-trait       = "0.1"
tracing           = "0.1"
uuid              = { version = "1.10", features = ["v4", "fast-rng", "serde"] }
chrono            = { version = "0.4",  features = ["serde"] }
# --- native-heavy (feature/target gated inside crates) ---
tokio             = { version = "1.40", default-features = false }
tokio-stream      = { version = "0.1",  features = ["sync"] }
reqwest           = { version = "0.12", default-features = false, features = ["json", "stream", "rustls-tls"] }
reqwest-eventsource = "0.6"
surrealdb         = { version = "3.2",  default-features = false }
sqlx              = { version = "0.8",  default-features = false, features = ["runtime-tokio-rustls", "macros"] }
candle-core       = "0.7"
candle-nn         = "0.7"
candle-transformers = "0.7"
fastembed         = "5"
flutter_rust_bridge = { version = "2.12", features = ["anyhow"] }
dashmap           = "6.1"
parking_lot       = "0.12"
once_cell         = "1.20"

# Feature-unification pin (cargo-hakari): all real crates depend on this so a
# switch between desktop/mobile/wasm invocations doesn't churn shared deps.
# Regenerate with: cargo hakari generate
[workspace.dependencies.workspace-hack]
path = "crates/workspace-hack"

# ─────────────────────────── Compile profiles ───────────────────────────────
# Development: fast iteration on host. Deps compiled well once (opt-2) then cached;
# app code iterates at opt-0. line-tables-only + unpacked debuginfo = big macOS win.
[profile.dev]
opt-level = 0
debug = "line-tables-only"
split-debuginfo = "unpacked"
incremental = true

[profile.dev.package."*"]
opt-level = 2
debug = false

# Build scripts + proc-macros (serde_derive, frb support, sqlx macros) run at
# compile time — optimizing them speeds every downstream compile.
[profile.dev.build-override]
opt-level = 3

# Release: shipped desktop/mobile binaries.
# panic = "unwind" is REQUIRED: flutter_rust_bridge wraps handlers in catch_unwind
# to convert Rust panics into a catchable Dart PanicException. panic="abort" would
# hard-kill the entire mobile app process on any panic. (Do NOT change to abort.)
[profile.release]
opt-level = 3
lto = "thin"
codegen-units = 1
strip = "symbols"
panic = "unwind"
incremental = false

# WASM: size-optimized. panic=abort is safe & standard on wasm32.
[profile.wasm-release]
inherits = "release"
opt-level = "z"
lto = true
codegen-units = 1
panic = "abort"
strip = "debuginfo"

# Optional nightly host-only fast codegen. Enable per-invocation:
#   cargo +nightly build --profile dev-fast -Zcodegen-backend
# Cranelift works on aarch64-macOS host dev ONLY — never iOS/Android/wasm.
# (Left commented so stable builds are unaffected; uncomment cargo-features to use.)
# cargo-features = ["codegen-backend"]
# [profile.dev-fast]
# inherits = "dev"
# codegen-backend = "cranelift"
EOF
ok "workspace Cargo.toml (profiles: dev/release[unwind]/wasm-release)"

# ── .cargo/config.toml ───────────────────────────────────────────────────────
mkdir -p "$OUT/.cargo"
cat > "$OUT/.cargo/config.toml" << 'EOF'
# TJ-ARCH-MOB-001 — compile-speed configuration.
# See references/rust/compile-speed.md for the per-target rationale.

[build]
# rust-lld is the default linker on Linux x86_64 since Rust 1.90. macOS uses the
# fast default Xcode "ld-prime" linker; the biggest macOS link win is debuginfo
# tuning (set in the dev profile), not a third-party linker (mold/sold are dead
# on macOS). To try lld on macOS: brew install llvm, then uncomment below.

# [target.aarch64-apple-darwin]
# rustflags = ["-C", "link-arg=-fuse-ld=/opt/homebrew/opt/llvm/bin/ld64.lld"]

[target.x86_64-unknown-linux-gnu]
# mold is the fastest production linker on Linux (install: apt/brew install mold)
# linker = "clang"
# rustflags = ["-C", "link-arg=-fuse-ld=mold"]

# sccache: CI + branch-switching only (cannot cache incremental crates, so it is
# NOT an inner-loop tool). Enable in ~/.cargo/config.toml, not here:
#   [build] rustc-wrapper = "sccache"
EOF
ok ".cargo/config.toml"

# ── rust-toolchain.toml ──────────────────────────────────────────────────────
cat > "$OUT/rust-toolchain.toml" << 'EOF'
[toolchain]
channel = "1.93"
components = ["rustfmt", "clippy", "rust-src"]
targets = [
    "aarch64-apple-ios",
    "aarch64-linux-android",
    "wasm32-unknown-unknown",
]
EOF
ok "rust-toolchain.toml"

# ── bacon.toml (continuous clippy-driven inner loop) ─────────────────────────
cat > "$OUT/bacon.toml" << 'EOF'
# TJ-ARCH-MOB-001 inner loop. `cargo clippy` is the single loop driver — never
# alternate with bare `cargo check` (they don't share fingerprint caches, so
# alternating recompiles everything twice). Cross-target jobs catch cfg errors
# in seconds without full mobile/wasm builds.
default_job = "clippy"

[jobs.clippy]
command = ["cargo", "clippy", "--all-targets", "--all-features", "--", "-D", "warnings"]
need_stdout = false

[jobs.check-wasm]
command = ["cargo", "check", "--target", "wasm32-unknown-unknown", "-p", "gen_ui_wasm"]
need_stdout = false

[jobs.check-ios]
command = ["cargo", "check", "--target", "aarch64-apple-ios", "-p", "gen_ui_ffi"]
need_stdout = false

[keybindings]
c = "job:clippy"
w = "job:check-wasm"
i = "job:check-ios"
EOF
ok "bacon.toml (clippy driver + cross-target check jobs)"

# ── helper to emit a crate ───────────────────────────────────────────────────
emit_crate() {
  local name="$1" ctype="$2"; shift 2
  local dir="$OUT/crates/$name"
  mkdir -p "$dir/src"
  {
    echo "[package]"
    echo "name = \"$name\""
    echo "version.workspace = true"
    echo "edition.workspace = true"
    echo "rust-version.workspace = true"
    echo "license.workspace = true"
    echo ""
    if [[ -n "$ctype" ]]; then
      echo "[lib]"
      echo "crate-type = [$ctype]"
      echo ""
    fi
    echo "[dependencies]"
  } > "$dir/Cargo.toml"
  ok "crate: $name"
}

# ── L0 gen_ui_types — the frozen trait seams ─────────────────────────────────
emit_crate gen_ui_types ""
cat >> "$OUT/crates/gen_ui_types/Cargo.toml" << 'EOF'
serde.workspace       = true
serde_json.workspace  = true
thiserror.workspace   = true
uuid.workspace        = true
chrono.workspace      = true
async-trait.workspace = true
futures.workspace     = true

# uuid v4/fast-rng needs getrandom's wasm backend to compile for the browser.
# Without the "js" feature, getrandom has no wasm32-unknown-unknown source of
# entropy and the build fails (E0433). Native targets ignore this.
[target.'cfg(target_arch = "wasm32")'.dependencies]
uuid = { version = "1.10", features = ["v4", "js"] }
getrandom = { version = "0.2", features = ["js"] }
EOF
cat > "$OUT/crates/gen_ui_types/src/lib.rs" << EOF
$MARK
//! gen_ui_types (L0) — pure types + ALL cross-crate trait seams.
//! NO tokio, NO IO. Compiles on every target including wasm32.
//!
//! FROZEN after C-001 review: changing a trait here requires cross-lane sign-off
//! because every downstream crate depends on these signatures.
#![forbid(unsafe_code)]

pub mod content_block;
pub mod events;
pub mod view;
pub mod transport;
pub mod sync;
pub mod config;
pub mod error;

pub use content_block::ContentBlock;
pub use error::{CoreError, CoreResult};
EOF

# ContentBlock — the cross-platform UI contract (11 variants).
cat > "$OUT/crates/gen_ui_types/src/content_block.rs" << EOF
$MARK
//! ContentBlock — the cross-platform UI contract. Every A2UI event maps to
//! exactly one variant. Dart/TS compilers enforce exhaustiveness at the match site.
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", rename_all = "camelCase")]
pub enum ContentBlock {
    Text { text: String },
    Thinking { text: String },
    Code { language: String, code: String },
    Citation { source: String, quote: String },
    Memory { operation: String, key: String, value: Option<String> },
    ToolUse { id: String, name: String, input_json: String },
    ToolResult { tool_use_id: String, output_json: String, is_error: bool },
    Skill { name: String, status: String },
    Artifact { id: String, kind: String, content: String },
    Image { url: Option<String>, data_base64: Option<String>, mime: String },
    Divider,
}
EOF

# Events — StreamEvent + A2UI/AG-UI enums (pure data; adapters live in protocol).
cat > "$OUT/crates/gen_ui_types/src/events.rs" << EOF
$MARK
//! Raw stream + protocol event enums. Pure data — transformation logic is in
//! gen_ui_protocol (which depends on this crate).
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum StreamEvent {
    MessageStart,
    TextDelta { index: u32, delta: String },
    ThinkingDelta { index: u32, delta: String },
    ToolCallStarted { id: String, name: String },
    ToolCallDelta { id: String, delta: String },
    ToolCallComplete { id: String },
    Error { message: String },
    Done,
}

/// A2UI event surface (subset shown; full 27-variant set filled in gen_ui_protocol
/// consumers). Kept as an open enum contract here.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum A2uiEvent {
    RunStarted { run_id: String },
    Block { block: crate::content_block::ContentBlock },
    RunFinished { run_id: String },
    RunError { message: String },
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum AguiEvent {
    RunStarted { thread_id: String, run_id: String },
    TextMessageContent { delta: String },
    ToolCallStart { id: String, name: String },
    StateSnapshot { snapshot_json: String },
    RunFinished { run_id: String },
}
EOF

# View — ViewDescriptor / FilterSpec / SortSpec (mirrored to Dart/TS).
cat > "$OUT/crates/gen_ui_types/src/view.rs" << EOF
$MARK
//! Transport-agnostic query description. Compiles (in gen_ui_db) to SQL clauses,
//! REST params, or GraphQL variables. Mirrored 1:1 as Dart freezed unions / TS types.
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ViewDescriptor {
    pub entity_type: String,
    pub filters: Vec<FilterSpec>,
    pub sorts: Vec<SortSpec>,
    pub limit: Option<u32>,
    pub cursor: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct FilterSpec {
    pub field: String,
    pub op: FilterOp,
    pub value_json: String,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum FilterOp { Eq, Ne, Lt, Lte, Gt, Gte, In, Like }

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SortSpec { pub field: String, pub descending: bool }
EOF

# Transport trait — the entity data-access seam (impl'd by gen_ui_db, gen_ui_client).
cat > "$OUT/crates/gen_ui_types/src/transport.rs" << EOF
$MARK
//! EntityTransport — the entity data-access seam. Implemented per entity type in
//! gen_ui_db / gen_ui_client; exposed to Dart via gen_ui_ffi. UI never implements it.
use crate::error::CoreResult;
use crate::view::ViewDescriptor;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct EntityRecord { pub id: String, pub entity_type: String, pub data_json: String }

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ListResult { pub items: Vec<EntityRecord>, pub next_cursor: Option<String> }

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "op", rename_all = "snake_case")]
pub enum ChangeEvent {
    Upsert { record: EntityRecord },
    Delete { entity_type: String, id: String },
    Invalidate { entity_type: String, list_key: Option<String> },
}

#[async_trait]
pub trait EntityTransport: Send + Sync {
    async fn list(&self, view: &ViewDescriptor) -> CoreResult<ListResult>;
    async fn get(&self, entity_type: &str, id: &str) -> CoreResult<Option<EntityRecord>>;
    async fn create(&self, record: &EntityRecord) -> CoreResult<EntityRecord>;
    async fn update(&self, record: &EntityRecord) -> CoreResult<EntityRecord>;
    async fn delete(&self, entity_type: &str, id: &str) -> CoreResult<()>;
}
EOF

# Sync trait — the local-first sync seam (impl'd by gen_ui_db::sync; PES later).
cat > "$OUT/crates/gen_ui_types/src/sync.rs" << EOF
$MARK
//! SyncTransport — local-first sync seam. The DIY Electric-consumer + write-queue
//! (gen_ui_db::sync) implements this; a future prometheus-entity-sync (PES) client
//! can implement the same trait without touching callers.
use crate::error::CoreResult;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum SyncStatus {
    Offline,
    Syncing { pending_writes: u32 },
    Live,
    Error { message: String },
}

#[async_trait]
pub trait SyncTransport: Send + Sync {
    /// Begin read-path sync for a shape/bucket, writing into the local store.
    async fn start(&self) -> CoreResult<()>;
    /// Enqueue a local write for replay through the server API.
    async fn enqueue_write(&self, change_json: &str) -> CoreResult<()>;
    /// Current status (drives the UI sync chip).
    fn status(&self) -> SyncStatus;
}
EOF

cat > "$OUT/crates/gen_ui_types/src/config.rs" << EOF
$MARK
//! UAR mode + app configuration (pure, wasm-safe).
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq)]
#[serde(tag = "mode", rename_all = "snake_case")]
pub enum UarMode {
    #[default]
    Embedded,
    External { url: String, api_key: Option<String>, timeout_secs: u64 },
}

// (Default derived on the enum via #[default] on the Embedded variant.)
EOF

cat > "$OUT/crates/gen_ui_types/src/error.rs" << EOF
$MARK
//! Shared error taxonomy. Library crates map their errors into CoreError.
use thiserror::Error;

pub type CoreResult<T> = Result<T, CoreError>;

#[derive(Debug, Error)]
pub enum CoreError {
    #[error("not found: {0}")]
    NotFound(String),
    #[error("transient (retryable): {0}")]
    Transient(String),
    #[error("terminal (do not retry): {0}")]
    Terminal(String),
    #[error("serialization: {0}")]
    Serde(String),
    #[error("io: {0}")]
    Io(String),
}
EOF
ok "gen_ui_types: ContentBlock, events, view, EntityTransport, SyncTransport (FROZEN seams)"

# ── L1 gen_ui_runtime ────────────────────────────────────────────────────────
emit_crate gen_ui_runtime ""
cat >> "$OUT/crates/gen_ui_runtime/Cargo.toml" << 'EOF'
gen_ui_types = { path = "../gen_ui_types" }
futures.workspace = true

[target.'cfg(not(target_arch = "wasm32"))'.dependencies]
tokio = { workspace = true, features = ["rt-multi-thread", "time", "sync", "macros"] }
once_cell.workspace = true

[target.'cfg(target_arch = "wasm32")'.dependencies]
wasm-bindgen-futures = "0.4"
EOF
cat > "$OUT/crates/gen_ui_runtime/src/lib.rs" << EOF
$MARK
//! gen_ui_runtime (L1) — one runtime abstraction, two backends.
//! Native: global multi-thread Tokio (one per process). wasm: spawn_local.

#[cfg(not(target_arch = "wasm32"))]
mod native;
#[cfg(not(target_arch = "wasm32"))]
pub use native::{init, handle, spawn, spawn_blocking};

#[cfg(target_arch = "wasm32")]
mod web;
#[cfg(target_arch = "wasm32")]
pub use web::spawn;
EOF
cat > "$OUT/crates/gen_ui_runtime/src/native.rs" << EOF
$MARK
//! Native runtime: one global multi-thread Tokio per process (never create a second).
use once_cell::sync::OnceCell;
use tokio::runtime::{Builder, Handle, Runtime};

static RT: OnceCell<Runtime> = OnceCell::new();

pub fn init(worker_threads: Option<usize>) {
    let _ = RT.get_or_try_init(|| {
        let n = worker_threads.unwrap_or_else(|| {
            std::thread::available_parallelism().map(|n| n.get().max(2) - 1).unwrap_or(4)
        });
        Builder::new_multi_thread()
            .worker_threads(n)
            .max_blocking_threads(8)
            .thread_name("gen-ui-worker")
            .enable_all()
            .build()
    });
}

pub fn handle() -> Handle { RT.get().expect("runtime not initialised").handle().clone() }

pub fn spawn<F>(f: F) -> tokio::task::JoinHandle<F::Output>
where F: std::future::Future + Send + 'static, F::Output: Send + 'static {
    handle().spawn(f)
}

pub fn spawn_blocking<F, T>(f: F) -> tokio::task::JoinHandle<T>
where F: FnOnce() -> T + Send + 'static, T: Send + 'static {
    handle().spawn_blocking(f)
}
EOF
cat > "$OUT/crates/gen_ui_runtime/src/web.rs" << EOF
$MARK
//! wasm runtime: browser has no threads; drive futures on the JS microtask queue.
pub fn spawn<F>(f: F) where F: std::future::Future<Output = ()> + 'static {
    wasm_bindgen_futures::spawn_local(f);
}
EOF
ok "gen_ui_runtime: native Tokio / wasm spawn_local"

# ── L1 gen_ui_protocol ───────────────────────────────────────────────────────
emit_crate gen_ui_protocol ""
cat >> "$OUT/crates/gen_ui_protocol/Cargo.toml" << 'EOF'
gen_ui_types = { path = "../gen_ui_types" }
serde.workspace = true
serde_json.workspace = true
futures.workspace = true
EOF
cat > "$OUT/crates/gen_ui_protocol/src/lib.rs" << EOF
$MARK
//! gen_ui_protocol (L1) — A2UI/AG-UI adapters. Pure transformation over the L0
//! event enums; wasm-safe (no IO, no runtime dependency).
use gen_ui_types::events::{A2uiEvent, AguiEvent, StreamEvent};
use gen_ui_types::content_block::ContentBlock;

/// StreamEvent -> A2uiEvent(s). Feature-complete adapter to be filled per the
/// ContentBlock contract; C-001 lands the seam + a working text path.
pub struct A2uiAdapter { run_id: String }
impl A2uiAdapter {
    pub fn new(run_id: impl Into<String>) -> Self { Self { run_id: run_id.into() } }
    pub fn ingest(&mut self, ev: &StreamEvent) -> Vec<A2uiEvent> {
        match ev {
            StreamEvent::MessageStart => vec![A2uiEvent::RunStarted { run_id: self.run_id.clone() }],
            StreamEvent::TextDelta { delta, .. } =>
                vec![A2uiEvent::Block { block: ContentBlock::Text { text: delta.clone() } }],
            StreamEvent::Done => vec![A2uiEvent::RunFinished { run_id: self.run_id.clone() }],
            StreamEvent::Error { message } => vec![A2uiEvent::RunError { message: message.clone() }],
            _ => vec![],
        }
    }
}

/// A2uiEvent -> AguiEvent(s), bidirectional-capable.
pub struct AguiAdapter {
    thread_id: String,
    /// Retained for the bidirectional path (client→agent) filled in a later lane.
    #[allow(dead_code)]
    run_id: String,
}
impl AguiAdapter {
    pub fn new(thread_id: impl Into<String>, run_id: impl Into<String>) -> Self {
        Self { thread_id: thread_id.into(), run_id: run_id.into() }
    }
    pub fn translate(&mut self, ev: &A2uiEvent) -> Vec<AguiEvent> {
        match ev {
            A2uiEvent::RunStarted { run_id } =>
                vec![AguiEvent::RunStarted { thread_id: self.thread_id.clone(), run_id: run_id.clone() }],
            A2uiEvent::Block { block: ContentBlock::Text { text } } =>
                vec![AguiEvent::TextMessageContent { delta: text.clone() }],
            A2uiEvent::RunFinished { run_id } => vec![AguiEvent::RunFinished { run_id: run_id.clone() }],
            _ => vec![],
        }
    }
}
EOF
ok "gen_ui_protocol: A2UI/AG-UI adapters (wasm-safe)"

# ── L2 stubs (filled by Wave-1 lanes) ───────────────────────────────────────
emit_l2_stub() {
  local name="$1" summary="$2" owner="$3"
  cat >> "$OUT/crates/$name/Cargo.toml" << EOF
gen_ui_types   = { path = "../gen_ui_types" }
gen_ui_runtime = { path = "../gen_ui_runtime" }
async-trait.workspace = true
anyhow.workspace = true
EOF
  cat > "$OUT/crates/$name/src/lib.rs" << EOF
$MARK
//! $name (L2) — $summary
//! Trait seams (EntityTransport / SyncTransport / etc.) are defined in gen_ui_types.
//! IMPLEMENTATION OWNER: $owner (see plan.md). This is the C-001 seam stub.
EOF
}
emit_crate gen_ui_client ""
emit_l2_stub gen_ui_client "Anthropic + Flint HTTP/SSE behind a Transport trait (native reqwest / wasm fetch)." "C-006 flint-integration"
emit_crate gen_ui_mcp ""
emit_l2_stub gen_ui_mcp "MCP client registry (SSE wasm-safe; stdio native-only)." "C-006 flint-integration"
emit_crate gen_ui_db ""
emit_l2_stub gen_ui_db "relational (pg/sqlite) + graph (surreal) + sync + startup orchestrator." "C-003/C-004/C-005"
emit_crate gen_ui_inference ""
emit_l2_stub gen_ui_inference "candle GGUF engine (native accel; wasm feature-gated off)." "future inference lane"

# ── L3 gen_ui_agent ──────────────────────────────────────────────────────────
emit_crate gen_ui_agent ""
cat >> "$OUT/crates/gen_ui_agent/Cargo.toml" << 'EOF'
gen_ui_types    = { path = "../gen_ui_types" }
gen_ui_runtime  = { path = "../gen_ui_runtime" }
gen_ui_protocol = { path = "../gen_ui_protocol" }
gen_ui_client   = { path = "../gen_ui_client" }
gen_ui_mcp      = { path = "../gen_ui_mcp" }
async-trait.workspace = true
anyhow.workspace = true
EOF
cat > "$OUT/crates/gen_ui_agent/src/lib.rs" << EOF
$MARK
//! gen_ui_agent (L3) — PMPO loop (UAR embedded/external) over L0-L2 abstractions.
//! Seam stub for C-001; implemented later.
EOF
ok "gen_ui_agent: PMPO loop seam"

# ── LEAF crates ──────────────────────────────────────────────────────────────
emit_crate gen_ui_ffi '"cdylib", "staticlib"'
cat >> "$OUT/crates/gen_ui_ffi/Cargo.toml" << 'EOF'
gen_ui_types    = { path = "../gen_ui_types" }
gen_ui_runtime  = { path = "../gen_ui_runtime" }
gen_ui_protocol = { path = "../gen_ui_protocol" }
gen_ui_agent    = { path = "../gen_ui_agent" }
flutter_rust_bridge.workspace = true
anyhow.workspace = true

[target.'cfg(target_os = "android")'.dependencies]
android_logger = "0.14"
[target.'cfg(target_os = "ios")'.dependencies]
oslog = "0.2"
EOF
cat > "$OUT/crates/gen_ui_ffi/src/lib.rs" << EOF
$MARK
//! gen_ui_ffi (LEAF) — flutter_rust_bridge surface. Thin: editing app logic here
//! does not retrigger deep recompiles. Re-exports intent-level APIs + streams.
pub mod api;
EOF
cat > "$OUT/crates/gen_ui_ffi/src/api.rs" << EOF
$MARK
//! frb codegen target. Intent-level functions only (no raw SurrealQL / SQL across
//! the bridge). Filled by C-007; C-001 lands the init seam.
use flutter_rust_bridge::frb;

#[frb(init)]
pub fn init_core(worker_threads: Option<usize>) {
    #[cfg(not(target_arch = "wasm32"))]
    gen_ui_runtime::init(worker_threads);
    let _ = worker_threads;
}
EOF
ok "gen_ui_ffi: frb leaf"

emit_crate tauri-plugin-gen-ui ""
cat >> "$OUT/crates/tauri-plugin-gen-ui/Cargo.toml" << 'EOF'
gen_ui_types    = { path = "../gen_ui_types" }
gen_ui_runtime  = { path = "../gen_ui_runtime" }
gen_ui_agent    = { path = "../gen_ui_agent" }
serde.workspace = true
# tauri = { version = "2", features = [] }   # enabled by C-007
EOF
cat > "$OUT/crates/tauri-plugin-gen-ui/src/lib.rs" << EOF
$MARK
//! tauri-plugin-gen-ui (LEAF) — Tauri 2 plugin: commands, events, permissions.
//! npm guest-js bindings package added by C-007. C-001 lands the crate seam.
EOF
ok "tauri-plugin-gen-ui: plugin leaf"

emit_crate gen_ui_wasm '"cdylib", "rlib"'
cat >> "$OUT/crates/gen_ui_wasm/Cargo.toml" << 'EOF'
gen_ui_types    = { path = "../gen_ui_types" }
gen_ui_runtime  = { path = "../gen_ui_runtime" }
gen_ui_protocol = { path = "../gen_ui_protocol" }
wasm-bindgen = "0.2"
serde.workspace = true
serde_json.workspace = true
EOF
cat > "$OUT/crates/gen_ui_wasm/src/lib.rs" << EOF
$MARK
//! gen_ui_wasm (LEAF) — wasm-bindgen/web surface for browser embedding.
//! Built with: cargo build --profile wasm-release --target wasm32-unknown-unknown
//! then wasm-opt. Filled by C-002/C-007; C-001 lands the seam.
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn gen_ui_version() -> String { env!("CARGO_PKG_VERSION").to_string() }
EOF
ok "gen_ui_wasm: web leaf"

# ── workspace-hack (cargo-hakari pin) ────────────────────────────────────────
emit_crate workspace-hack ""
cat > "$OUT/crates/workspace-hack/src/lib.rs" << EOF
$MARK
//! workspace-hack — cargo-hakari feature-unification pin. Regenerate with
//! \`cargo hakari generate\` after adding deps so switching between desktop/mobile/
//! wasm invocations doesn't churn shared dependency rebuilds. Empty until generated.
EOF
ok "workspace-hack: hakari pin"

step "Verifying workspace metadata"
if command -v cargo >/dev/null 2>&1; then
  (cd "$OUT" && cargo metadata --no-deps --format-version 1 >/dev/null 2>&1 \
    && echo "  cargo metadata OK (12 crates)" \
    || echo "  (cargo metadata reported issues — run 'cargo check' in $OUT)")
else
  echo "  (cargo not found — install Rust to verify)"
fi

echo ""
echo -e "${GREEN}✅ Layered gen_ui workspace scaffolded in $OUT${NC}"
echo ""
echo "  Layers: types → runtime/protocol → client/mcp/db/inference → agent → ffi/tauri/wasm"
echo "  Inner loop:   cd $OUT && bacon        (clippy driver)"
echo "  Cross-target: bacon check-wasm | check-ios"
echo "  Wave-1 lanes implement: gen_ui_db (C-003/004/005), gen_ui_client+mcp (C-006), leaves (C-007)"
echo ""
echo "  ⚠ gen_ui_types trait seams are FROZEN after C-001 review — changes need cross-lane sign-off."
