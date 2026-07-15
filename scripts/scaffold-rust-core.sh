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
#   L2  gen_ui_client     Flint gate(auth)/forge(Quarry+MCP+AG-UI)/frf(spine, feat)
#   L2  gen_ui_mcp        MCP client registry (JSON-RPC 2.0 + HTTP/SSE; forge a2ui seam)
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
    "crates/gen_ui_db_graph",
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
# mid-2026 floor. 1.93 can no longer build the SurrealDB 3.2 graph crate (C-004):
# its transitive fastnum ≥0.7.5 requires rustc 1.94+, so the floor moves to 1.95
# (the mid-2026 stable that satisfies it). Keep in sync with rust-toolchain.toml
# and CLAUDE.md tool versions.
rust-version = "1.95"
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
# --- Flint platform SDK (FRF realtime spine). Nothing is published to crates.io —
#     all FRF inter-crate deps are PATH deps in-repo, and the repo is private, so a
#     fresh scaffold cannot resolve them. They are therefore left COMMENTED here (as
#     C-001 leaves `tauri` commented for C-007): the default gate+forge build has NO
#     FRF dependency and stays wasm-safe + offline-resolvable. To enable the `frf` /
#     `peer-crdt` features, UNCOMMENT below and point at your vendored checkout —
#     a `git`+`rev` pin (reproducible) or a `path` to a local clone:
#       frf-sdk-rust = { git = "ssh://git@github.com/prometheusags/flint-realtime-fabric", rev = "9ba04ae6ce41be796ae149609414b17a0d0d376b" }
#     ── VERIFIED HEAD (2026-07-15): 9ba04ae6ce41be796ae149609414b17a0d0d376b ──
# frf-sdk-rust      = { git = "ssh://git@github.com/prometheusags/flint-realtime-fabric", rev = "9ba04ae6ce41be796ae149609414b17a0d0d376b", default-features = false }
# frf-crdt          = { git = "ssh://git@github.com/prometheusags/flint-realtime-fabric", rev = "9ba04ae6ce41be796ae149609414b17a0d0d376b", default-features = false }
# frf-store-redb    = { git = "ssh://git@github.com/prometheusags/flint-realtime-fabric", rev = "9ba04ae6ce41be796ae149609414b17a0d0d376b", default-features = false }
# JWT decode (inspect exp/role/tenant_id from gate-minted tokens; no local verify —
# gate/forge own verification via JWKS). validation disabled for pure claim reads.
jsonwebtoken      = { version = "9", default-features = false }
surrealdb         = { version = "3.2",  default-features = false }
sqlx              = { version = "0.8",  default-features = false, features = ["runtime-tokio-rustls", "macros", "migrate"] }
pglite-oxide       = { version = "0.5.1", default-features = false }
refinery           = { version = "0.8", default-features = false }
sqlite-vec         = "0.1"
libsqlite3-sys     = "0.30"
virtual-net        = "=0.702.0-alpha.3"
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
# 1.95 floor: SurrealDB 3.2 (gen_ui_db_graph, C-004) pulls fastnum ≥0.7.5 which
# requires rustc 1.94+. 1.95 is the mid-2026 stable that satisfies it. Keep in
# sync with the workspace rust-version in Cargo.toml.
channel = "1.95"
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

# ── C-006 emitters (gen_ui_mcp real seam + gen_ui_client flint integration) ──
# Defined here (after emit_l2_stub) and invoked below in place of the stub calls.

emit_flint_mcp() {
  cat >> "$OUT/crates/gen_ui_mcp/Cargo.toml" << 'EOF'
gen_ui_types   = { path = "../gen_ui_types" }
gen_ui_runtime = { path = "../gen_ui_runtime" }
async-trait.workspace = true
serde.workspace       = true
serde_json.workspace  = true
futures.workspace     = true
parking_lot.workspace = true
reqwest.workspace     = true
tracing.workspace     = true
reqwest-eventsource.workspace = true

[features]
default = []
# stdio transport spawns a child process — native-only, opt-in (Claude Desktop etc.).
stdio = []
EOF
  cat > "$OUT/crates/gen_ui_mcp/src/lib.rs" << EOF
$MARK
//! gen_ui_mcp (L2) — MCP (Model Context Protocol) client registry.
//! JSON-RPC 2.0 over HTTP POST + an SSE event channel (open standard, Rule 12).
//! flint-forge exposes its A2UI registry AS an MCP server at \`/mcp/v1/a2ui\`;
//! the flint client (gen_ui_client) registers that server into [\`McpRegistry\`].
//!
//! The registry + JSON-RPC envelopes are pure and cross-target. The HTTP+SSE
//! transport uses reqwest, whose wasm \`Response\` future is NOT \`Send\`; because the
//! MCP transport seam is object-safe with \`Send\` futures (registry holds
//! \`Box<dyn McpTransport>\` across threads on native), the concrete [\`SseTransport\`]
//! is native-only. On the browser the A2UI/MCP surface is driven from JS
//! (Connect-web / \`@flint/react\`) per the layer contract, not this crate.
#![cfg_attr(target_arch = "wasm32", allow(dead_code))]

pub mod jsonrpc;
pub mod registry;
#[cfg(not(target_arch = "wasm32"))]
pub mod sse_transport;

pub use registry::{McpRegistry, McpServerHandle, McpTool, McpTransport};
#[cfg(not(target_arch = "wasm32"))]
pub use sse_transport::SseTransport;
EOF
  cat > "$OUT/crates/gen_ui_mcp/src/jsonrpc.rs" << EOF
$MARK
//! Minimal JSON-RPC 2.0 request/response envelopes for MCP.
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize)]
pub struct JsonRpcRequest {
    pub jsonrpc: &'static str,
    pub id: u64,
    pub method: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub params: Option<serde_json::Value>,
}

impl JsonRpcRequest {
    pub fn new(id: u64, method: impl Into<String>, params: Option<serde_json::Value>) -> Self {
        Self { jsonrpc: "2.0", id, method: method.into(), params }
    }
}

#[derive(Debug, Clone, Deserialize)]
pub struct JsonRpcResponse {
    #[allow(dead_code)]
    pub jsonrpc: String,
    pub id: u64,
    #[serde(default)]
    pub result: Option<serde_json::Value>,
    #[serde(default)]
    pub error: Option<JsonRpcError>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct JsonRpcError {
    pub code: i64,
    pub message: String,
}
EOF
  cat > "$OUT/crates/gen_ui_mcp/src/registry.rs" << EOF
$MARK
//! MCP server registry. One [\`McpRegistry\`] per process holds the connected
//! servers keyed by name; \`tools/list\` results are cached per server so the agent
//! loop can enumerate available tools without a round-trip on every turn.
use async_trait::async_trait;
use gen_ui_types::CoreResult;
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;

/// The transport seam a registered MCP server speaks over. Object-safe so the
/// registry holds \`Box<dyn McpTransport>\`. The HTTP+SSE impl ([\`super::SseTransport\`])
/// is native-only (reqwest wasm response is !Send); a wasm build registers no
/// concrete transport (the browser drives MCP from JS).
#[async_trait]
pub trait McpTransport: Send + Sync {
    async fn request(&self, method: &str, params: Option<serde_json::Value>) -> CoreResult<serde_json::Value>;
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct McpTool {
    pub name: String,
    #[serde(default)]
    pub description: Option<String>,
    /// JSON-Schema of the tool's input (\`inputSchema\` in the MCP spec).
    #[serde(default, rename = "inputSchema")]
    pub input_schema: serde_json::Value,
}

/// A connected MCP server: the transport plus its last-known tool inventory.
pub struct McpServerHandle {
    pub name: String,
    transport: Box<dyn McpTransport>,
    tools: RwLock<Vec<McpTool>>,
}

impl McpServerHandle {
    pub fn new(name: impl Into<String>, transport: Box<dyn McpTransport>) -> Self {
        Self { name: name.into(), transport, tools: RwLock::new(Vec::new()) }
    }

    /// Refresh the cached tool inventory via \`tools/list\`.
    pub async fn refresh_tools(&self) -> CoreResult<Vec<McpTool>> {
        let value = self.transport.request("tools/list", None).await?;
        let tools: Vec<McpTool> = value
            .get("tools")
            .and_then(|t| serde_json::from_value(t.clone()).ok())
            .unwrap_or_default();
        *self.tools.write() = tools.clone();
        Ok(tools)
    }

    /// Invoke a tool via \`tools/call\`.
    pub async fn call_tool(&self, name: &str, arguments: serde_json::Value) -> CoreResult<serde_json::Value> {
        self.transport
            .request("tools/call", Some(serde_json::json!({ "name": name, "arguments": arguments })))
            .await
    }

    pub fn cached_tools(&self) -> Vec<McpTool> { self.tools.read().clone() }
}

#[derive(Default, Clone)]
pub struct McpRegistry {
    servers: Arc<RwLock<HashMap<String, Arc<McpServerHandle>>>>,
}

impl McpRegistry {
    pub fn new() -> Self { Self::default() }

    /// Register a server (e.g. flint-forge's \`/mcp/v1/a2ui\`) under its name.
    pub fn register(&self, handle: McpServerHandle) -> Arc<McpServerHandle> {
        let handle = Arc::new(handle);
        self.servers.write().insert(handle.name.clone(), handle.clone());
        handle
    }

    pub fn get(&self, name: &str) -> Option<Arc<McpServerHandle>> {
        self.servers.read().get(name).cloned()
    }

    pub fn server_names(&self) -> Vec<String> {
        self.servers.read().keys().cloned().collect()
    }
}
EOF
  cat > "$OUT/crates/gen_ui_mcp/src/sse_transport.rs" << EOF
$MARK
//! HTTP+SSE implementation of [\`crate::registry::McpTransport\`]. The SSE channel
//! carries server→client notifications; requests are JSON-RPC 2.0 over HTTP POST.
//! Bearer auth is supplied by the caller (the flint client injects the gate JWT).
//! Native-only: reqwest's wasm \`Response\` future is not \`Send\`.
use crate::jsonrpc::{JsonRpcRequest, JsonRpcResponse};
use crate::registry::McpTransport;
use async_trait::async_trait;
use gen_ui_types::{CoreError, CoreResult};
use std::sync::atomic::{AtomicU64, Ordering};

pub struct SseTransport {
    http: reqwest::Client,
    endpoint: String,
    bearer: Option<String>,
    next_id: AtomicU64,
}

impl SseTransport {
    /// \`endpoint\` is the JSON-RPC POST URL (e.g. \`https://forge/mcp/v1/a2ui\`).
    pub fn new(http: reqwest::Client, endpoint: impl Into<String>, bearer: Option<String>) -> Self {
        Self { http, endpoint: endpoint.into(), bearer, next_id: AtomicU64::new(1) }
    }
}

#[async_trait]
impl McpTransport for SseTransport {
    async fn request(&self, method: &str, params: Option<serde_json::Value>) -> CoreResult<serde_json::Value> {
        let id = self.next_id.fetch_add(1, Ordering::Relaxed);
        let body = JsonRpcRequest::new(id, method, params);
        let mut req = self.http.post(&self.endpoint).json(&body);
        if let Some(token) = &self.bearer {
            req = req.bearer_auth(token);
        }
        let resp = req.send().await.map_err(|e| CoreError::Transient(e.to_string()))?;
        if !resp.status().is_success() {
            return Err(CoreError::Terminal(format!("mcp http {}", resp.status())));
        }
        let parsed: JsonRpcResponse = resp.json().await.map_err(|e| CoreError::Serde(e.to_string()))?;
        if let Some(err) = parsed.error {
            return Err(CoreError::Terminal(format!("jsonrpc {}: {}", err.code, err.message)));
        }
        parsed.result.ok_or_else(|| CoreError::Terminal("jsonrpc: empty result".into()))
    }
}
EOF
  ok "gen_ui_mcp: JSON-RPC 2.0 + HTTP/SSE transport + registry (forge /mcp/v1/a2ui seam)"
}

emit_flint_client() {
  # ── Cargo.toml ──────────────────────────────────────────────────────────────
  cat >> "$OUT/crates/gen_ui_client/Cargo.toml" << 'EOF'
gen_ui_types    = { path = "../gen_ui_types" }
gen_ui_runtime  = { path = "../gen_ui_runtime" }
gen_ui_protocol = { path = "../gen_ui_protocol" }
gen_ui_mcp      = { path = "../gen_ui_mcp" }
async-trait.workspace = true
serde.workspace       = true
serde_json.workspace  = true
futures.workspace     = true
parking_lot.workspace = true
tracing.workspace     = true
reqwest.workspace     = true
reqwest-eventsource.workspace = true
jsonwebtoken.workspace = true

[features]
default = []
# FRF peer-sync spine (tonic gRPC over HTTP/2). Native-only — tonic's transport does
# not build for wasm32-unknown-unknown. The browser surface uses frf-wasm/Connect-web
# from the JS side (see references), NOT this crate. Off by default so the common
# gate+forge path stays wasm-safe and fast to compile.
#
# The feature FLAGS are declared (so `cfg(feature = "frf")` is a known cfg and the
# offline gate+forge build is clippy-clean) but activate NO deps here, because the
# FRF crates are private/unpublished (see workspace Cargo.toml). To actually enable
# the spine: uncomment the three FRF workspace deps + the optional-dep block below,
# then change these two lines to pull them in:
#     frf = ["dep:frf-sdk-rust"]
#     peer-crdt = ["frf", "dep:frf-crdt", "dep:frf-store-redb"]
frf = []
peer-crdt = ["frf"]

# [target.'cfg(not(target_arch = "wasm32"))'.dependencies]
# frf-sdk-rust   = { workspace = true, optional = true }
# frf-crdt       = { workspace = true, optional = true }
# frf-store-redb = { workspace = true, optional = true }

[dev-dependencies]
jsonwebtoken.workspace = true
serde_json.workspace   = true
EOF

  # ── lib.rs ──────────────────────────────────────────────────────────────────
  { echo "$MARK"; cat << 'RUST'; } > "$OUT/crates/gen_ui_client/src/lib.rs"
//! gen_ui_client (L2) — Flint platform integration for gen_ui_core.
//!
//! Owns ALL outbound connections (TJ-ARCH-MOB-001: networking lives only here, never
//! in Dart/TS). Three planes, one façade [`flint::FlintClient`]:
//!   * gate   — Kratos/JWT auth, token lifecycle, Cedar `@require_approval` polling.
//!   * forge  — Quarry REST (`EntityTransport`), A2UI-registry MCP server, AG-UI runs.
//!   * frf    — realtime spine (Spine subscribe/ack, EntityService watch) [feature = "frf"].
//!
//! Verified against flint-gate/forge/FRF HEADs 2026-07-15 (see the C-006 done log for
//! SHAs). gate + forge are plain HTTP/SSE/JSON-RPC (reqwest); FRF is tonic gRPC and is
//! therefore native-only + feature-gated so the default build stays wasm-safe.
#![cfg_attr(target_arch = "wasm32", allow(dead_code))]

pub mod flint;

// The FlintClient façade is native-only (reqwest/tonic IO); the browser reaches the
// same planes from JS per the layer contract. Token types are cross-target.
#[cfg(not(target_arch = "wasm32"))]
pub use flint::{FlintClient, FlintConfig};
pub use flint::token;
RUST

  mkdir -p "$OUT/crates/gen_ui_client/src/flint"

  emit_flint_token
  emit_flint_gate
  emit_flint_forge
  emit_flint_frf
  emit_flint_mod
  emit_flint_tests

  ok "gen_ui_client/flint: gate (auth+token+approval) · forge (Quarry/MCP/AG-UI) · frf (Spine, feat)"
}

emit_flint_token() {
  { echo "$MARK"; cat << 'RUST'; } > "$OUT/crates/gen_ui_client/src/flint/token.rs"
//! Token lifecycle for the gate auth flow.
//!
//! The gate mints short-lived (default 300s) JWTs; there is no refresh endpoint, so
//! "refresh" means re-authenticating from the held credential (anon key or Kratos
//! session). We model the ladder as a state enum so the caller cannot, e.g., call an
//! agent-scoped endpoint while still on the anon boot token.
//!
//! Claims mirror flint-forge `forge-identity::Claims` EXACTLY: only `sub`/`role`/
//! `tenant_id` are first-class; everything else (`act`, `agent_id`, `workflow_id`,
//! `principal_type`, `scope`) rides the untyped `extra` map — the platform itself
//! keeps them untyped, so typing them here would be a fiction that drifts.
use gen_ui_types::{CoreError, CoreResult};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// The role ladder. `service_role` bypasses Postgres RLS and never rides a client.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Role {
    Anon,
    Authenticated,
    Agent,
    ServiceRole,
}

impl Role {
    fn from_claim(s: Option<&str>) -> Self {
        match s {
            Some("authenticated") => Role::Authenticated,
            Some("agent") => Role::Agent,
            Some("service_role") => Role::ServiceRole,
            // forge-identity coerces an absent/unknown role to "anon".
            _ => Role::Anon,
        }
    }
}

/// Decoded gate/forge JWT claims. Only the three typed fields are guaranteed; the
/// rest are read out of `extra` by key when a caller needs them (e.g. `agent_id`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    #[serde(default)]
    pub role: Option<String>,
    #[serde(default)]
    pub tenant_id: Option<String>,
    #[serde(default)]
    pub exp: Option<i64>,
    #[serde(flatten)]
    pub extra: BTreeMap<String, serde_json::Value>,
}

impl Claims {
    pub fn role(&self) -> Role {
        Role::from_claim(self.role.as_deref())
    }
    /// An untyped extra claim by key (`act`, `agent_id`, `workflow_id`, ...).
    pub fn extra_str(&self, key: &str) -> Option<&str> {
        self.extra.get(key).and_then(|v| v.as_str())
    }
    /// Decode WITHOUT signature verification — gate/forge own verification (JWKS).
    /// We only need to read `exp`/`role`/`tenant_id` to drive the client state.
    pub fn decode_unverified(jwt: &str) -> CoreResult<Self> {
        let mut validation = jsonwebtoken::Validation::default();
        validation.insecure_disable_signature_validation();
        validation.validate_exp = false;
        validation.required_spec_claims.clear();
        let key = jsonwebtoken::DecodingKey::from_secret(&[]);
        jsonwebtoken::decode::<Claims>(jwt, &key, &validation)
            .map(|d| d.claims)
            .map_err(|e| CoreError::Terminal(format!("jwt decode: {e}")))
    }
}

/// A token plus its decoded claims. `is_expired` uses `exp` with a small skew.
#[derive(Debug, Clone)]
pub struct Token {
    pub raw: String,
    pub claims: Claims,
}

impl Token {
    const SKEW_SECS: i64 = 10;

    pub fn parse(raw: impl Into<String>) -> CoreResult<Self> {
        let raw = raw.into();
        let claims = Claims::decode_unverified(&raw)?;
        Ok(Self { raw, claims })
    }

    /// Expired relative to `now_unix` (caller supplies time — this crate does no IO
    /// and stays wasm-safe; the runtime layer provides the clock).
    pub fn is_expired(&self, now_unix: i64) -> bool {
        match self.claims.exp {
            Some(exp) => now_unix + Self::SKEW_SECS >= exp,
            None => false,
        }
    }

    pub fn role(&self) -> Role {
        self.claims.role()
    }
}

/// The auth state machine. Illegal transitions (agent call while Anon) are
/// unrepresentable: a caller pattern-matches to get the active token.
#[derive(Debug, Clone, Default)]
pub enum AuthState {
    /// No credential yet.
    #[default]
    Unauthenticated,
    /// Booted with the static publishable anon key.
    Anon { token: Token },
    /// Exchanged a Kratos session for an authenticated/agent JWT.
    Authenticated { token: Token },
}

impl AuthState {
    /// The Bearer token to attach to an outbound request, if any.
    pub fn bearer(&self) -> Option<&str> {
        match self {
            AuthState::Unauthenticated => None,
            AuthState::Anon { token } | AuthState::Authenticated { token } => Some(&token.raw),
        }
    }

    pub fn role(&self) -> Role {
        match self {
            AuthState::Unauthenticated | AuthState::Anon { .. } => Role::Anon,
            AuthState::Authenticated { token } => token.role(),
        }
    }

    /// True when the active token has expired and a re-auth is due.
    pub fn needs_refresh(&self, now_unix: i64) -> bool {
        match self {
            AuthState::Unauthenticated => false,
            AuthState::Anon { token } | AuthState::Authenticated { token } => token.is_expired(now_unix),
        }
    }
}
RUST
  ok "flint/token.rs: Role ladder · Claims (forge-identity mirror) · AuthState machine"
}

emit_flint_gate() {
  { echo "$MARK"; cat << 'RUST'; } > "$OUT/crates/gen_ui_client/src/flint/gate.rs"
//! flint-gate client — auth boot, Kratos session exchange, Cedar approval polling.
//!
//! VERIFIED contract (gate HEAD 2026-07-15):
//!  * There is NO anon-token issuance endpoint. `FLINT_ANON_KEY` is a static,
//!    pre-shared publishable JWT — boot = hold it and send `Authorization: Bearer`.
//!  * Kratos is proxied: gate resolves a session via `GET /sessions/whoami` with the
//!    `ory_kratos_session` cookie; the authenticated/agent JWT is then minted by gate
//!    per-request. No mint endpoint, no refresh endpoint (refresh = re-auth).
//!  * `@require_approval` (human-in-the-loop) surfaces via the ADMIN approvals API
//!    (`/approvals/:id` → `decision` field, null = pending). No `isApprovalRequired`
//!    boolean and no per-request status/header at this HEAD.
use crate::flint::token::{AuthState, Token};
use gen_ui_types::{CoreError, CoreResult};
use serde::Deserialize;

/// Gate endpoints. Proxy (:4456) carries app traffic; admin (:4457) is private and
/// only reachable from trusted backends — the approvals poll is an admin call.
#[derive(Debug, Clone)]
pub struct GateConfig {
    pub proxy_base: String,
    pub admin_base: Option<String>,
    /// Static publishable anon key (FLINT_ANON_KEY).
    pub anon_key: Option<String>,
}

pub struct GateClient {
    http: reqwest::Client,
    config: GateConfig,
}

/// A pending Cedar approval as surfaced by the admin API. `decision` is `None` while
/// pending; a caller polls until it flips to approved/rejected.
#[derive(Debug, Clone, Deserialize)]
pub struct ApprovalStatus {
    pub id: String,
    /// "approved" | "rejected" | null(pending).
    #[serde(default)]
    pub decision: Option<String>,
    #[serde(default)]
    pub reason: Option<String>,
}

impl ApprovalStatus {
    pub fn is_pending(&self) -> bool {
        self.decision.is_none()
    }
    pub fn is_approved(&self) -> bool {
        self.decision.as_deref() == Some("approved")
    }
}

impl GateClient {
    pub fn new(http: reqwest::Client, config: GateConfig) -> Self {
        Self { http, config }
    }

    /// Boot with the static anon key. Errors if none is configured — a client with no
    /// credential cannot reach RLS-guarded planes.
    pub fn boot_anon(&self) -> CoreResult<AuthState> {
        let key = self
            .config
            .anon_key
            .as_deref()
            .ok_or_else(|| CoreError::Terminal("flint: no FLINT_ANON_KEY configured".into()))?;
        let token = Token::parse(key)?;
        Ok(AuthState::Anon { token })
    }

    /// Exchange a Kratos session cookie for an authenticated/agent JWT.
    ///
    /// Gate resolves the session (`/sessions/whoami`) and mints the outbound JWT via
    /// its `claims_enhancement` hook; we read the minted token from the response. The
    /// exact carrier (body field vs `Authorization` on the response) is route-config
    /// dependent — we accept both shapes.
    pub async fn exchange_kratos_session(&self, kratos_cookie: &str) -> CoreResult<AuthState> {
        let url = format!("{}/sessions/whoami", self.config.proxy_base.trim_end_matches('/'));
        let resp = self
            .http
            .get(&url)
            .header(reqwest::header::COOKIE, format!("ory_kratos_session={kratos_cookie}"))
            .send()
            .await
            .map_err(|e| CoreError::Transient(e.to_string()))?;

        if resp.status() == reqwest::StatusCode::UNAUTHORIZED
            || resp.status() == reqwest::StatusCode::FORBIDDEN
        {
            return Err(CoreError::Terminal("flint: kratos session invalid".into()));
        }
        if !resp.status().is_success() {
            return Err(CoreError::Transient(format!("flint gate whoami http {}", resp.status())));
        }

        // Preferred: minted JWT echoed on a response header.
        if let Some(hv) = resp.headers().get(reqwest::header::AUTHORIZATION) {
            if let Ok(s) = hv.to_str() {
                let raw = s.strip_prefix("Bearer ").unwrap_or(s);
                let token = Token::parse(raw)?;
                return Ok(AuthState::Authenticated { token });
            }
        }
        // Fallback: JSON body { "token": "..." } or { "jwt": "..." }.
        #[derive(Deserialize)]
        struct MintBody {
            #[serde(alias = "jwt")]
            token: Option<String>,
        }
        let body: MintBody = resp.json().await.map_err(|e| CoreError::Serde(e.to_string()))?;
        let raw = body
            .token
            .ok_or_else(|| CoreError::Terminal("flint: gate returned no minted token".into()))?;
        Ok(AuthState::Authenticated { token: Token::parse(raw)? })
    }

    /// Poll a Cedar approval by id (admin API). One shot — the caller drives the wait
    /// loop with the runtime's timer so this stays IO-only and testable.
    pub async fn approval_status(&self, approval_id: &str) -> CoreResult<ApprovalStatus> {
        let admin = self
            .config
            .admin_base
            .as_deref()
            .ok_or_else(|| CoreError::Terminal("flint: no gate admin_base for approvals".into()))?;
        let url = format!("{}/approvals/{approval_id}", admin.trim_end_matches('/'));
        let resp = self
            .http
            .get(&url)
            .send()
            .await
            .map_err(|e| CoreError::Transient(e.to_string()))?;
        if resp.status() == reqwest::StatusCode::NOT_FOUND {
            return Err(CoreError::NotFound(format!("approval {approval_id}")));
        }
        if !resp.status().is_success() {
            return Err(CoreError::Transient(format!("flint approval http {}", resp.status())));
        }
        resp.json().await.map_err(|e| CoreError::Serde(e.to_string()))
    }
}
RUST
  ok "flint/gate.rs: anon boot · Kratos exchange · approval polling"
}

emit_flint_forge() {
  { echo "$MARK"; cat << 'RUST'; } > "$OUT/crates/gen_ui_client/src/flint/forge.rs"
//! flint-forge client — Quarry data plane, A2UI-registry MCP server, AG-UI runs.
//!
//! VERIFIED contract (forge HEAD 2026-07-15, binary `fdb-gateway`, default :8080):
//!  * Quarry REST paths are `/<schema>/<table>` (PostgREST grammar), NOT `/rest/v1`.
//!    RLS tenant scoping rides the Bearer JWT ONLY (no X-Tenant header).
//!  * A2UI registry is an MCP server at `POST /mcp/v1/a2ui` (JSON-RPC 2.0) with a
//!    keep-alive SSE at `/mcp/v1/a2ui/sse`. We register it into gen_ui_mcp::McpRegistry.
//!  * AG-UI runs: `POST /agents/v1/runs` → `GET /agents/v1/{run_id}/events` (SSE).
//!    Event frames are `event:<name>` + `data:<AgUiEvent json>` tagged by `type`.
use crate::flint::token::AuthState;
use gen_ui_mcp::{McpRegistry, McpServerHandle, SseTransport};
use gen_ui_types::content_block::ContentBlock;
use gen_ui_types::events::A2uiEvent;
use gen_ui_types::transport::{EntityRecord, EntityTransport, ListResult};
use gen_ui_types::view::{FilterOp, ViewDescriptor};
use gen_ui_types::{CoreError, CoreResult};
use serde::Deserialize;
use std::sync::Arc;

#[derive(Debug, Clone)]
pub struct ForgeConfig {
    /// e.g. `http://localhost:8080`.
    pub base: String,
    /// Postgres schema the entity tables live in (default `public`).
    pub schema: String,
}

impl Default for ForgeConfig {
    fn default() -> Self {
        Self { base: "http://localhost:8080".into(), schema: "public".into() }
    }
}

/// Shared auth handle so a refreshed token is seen by every request without rebuilding
/// the client. The gate/agent layer swaps the inner state; forge reads the Bearer.
pub type SharedAuth = Arc<parking_lot::RwLock<AuthState>>;

pub struct ForgeClient {
    http: reqwest::Client,
    config: ForgeConfig,
    auth: SharedAuth,
}

impl ForgeClient {
    pub fn new(http: reqwest::Client, config: ForgeConfig, auth: SharedAuth) -> Self {
        Self { http, config, auth }
    }

    fn bearer(&self) -> Option<String> {
        self.auth.read().bearer().map(str::to_owned)
    }

    /// Register forge's A2UI registry as an MCP server into the shared registry.
    /// The gate JWT is snapshotted at registration; callers re-register after a
    /// long-lived token rotation (tokens are short-lived — see token.rs).
    pub fn register_a2ui_mcp(&self, registry: &McpRegistry) -> Arc<McpServerHandle> {
        let endpoint = format!("{}/mcp/v1/a2ui", self.config.base.trim_end_matches('/'));
        let transport = SseTransport::new(self.http.clone(), endpoint, self.bearer());
        registry.register(McpServerHandle::new("flint-a2ui-registry", Box::new(transport)))
    }

    fn table_url(&self, entity_type: &str) -> String {
        format!("{}/{}/{}", self.config.base.trim_end_matches('/'), self.config.schema, entity_type)
    }

    fn apply_bearer(&self, req: reqwest::RequestBuilder) -> reqwest::RequestBuilder {
        match self.bearer() {
            Some(token) => req.bearer_auth(token),
            None => req,
        }
    }
}

/// PostgREST operator string for a FilterOp (`?field=eq.value`).
fn postgrest_op(op: FilterOp) -> &'static str {
    match op {
        FilterOp::Eq => "eq",
        FilterOp::Ne => "neq",
        FilterOp::Lt => "lt",
        FilterOp::Lte => "lte",
        FilterOp::Gt => "gt",
        FilterOp::Gte => "gte",
        FilterOp::In => "in",
        FilterOp::Like => "like",
    }
}

#[async_trait::async_trait]
impl EntityTransport for ForgeClient {
    async fn list(&self, view: &ViewDescriptor) -> CoreResult<ListResult> {
        let mut req = self.apply_bearer(self.http.get(self.table_url(&view.entity_type)));
        // PostgREST filter grammar: one query pair per filter.
        for f in &view.filters {
            let raw: serde_json::Value =
                serde_json::from_str(&f.value_json).unwrap_or(serde_json::Value::String(f.value_json.clone()));
            let val = raw.as_str().map(str::to_owned).unwrap_or_else(|| raw.to_string());
            req = req.query(&[(f.field.as_str(), format!("{}.{}", postgrest_op(f.op), val))]);
        }
        if !view.sorts.is_empty() {
            let order = view
                .sorts
                .iter()
                .map(|s| format!("{}.{}", s.field, if s.descending { "desc" } else { "asc" }))
                .collect::<Vec<_>>()
                .join(",");
            req = req.query(&[("order", order)]);
        }
        if let Some(limit) = view.limit {
            req = req.query(&[("limit", limit.to_string())]);
        }
        let resp = req.send().await.map_err(|e| CoreError::Transient(e.to_string()))?;
        if !resp.status().is_success() {
            return Err(map_status(resp.status()));
        }
        let rows: Vec<serde_json::Value> = resp.json().await.map_err(|e| CoreError::Serde(e.to_string()))?;
        let items = rows.into_iter().map(|row| row_to_record(&view.entity_type, row)).collect();
        Ok(ListResult { items, next_cursor: None })
    }

    async fn get(&self, entity_type: &str, id: &str) -> CoreResult<Option<EntityRecord>> {
        let req = self
            .apply_bearer(self.http.get(self.table_url(entity_type)))
            .query(&[("id", format!("eq.{id}")), ("limit", "1".into())]);
        let resp = req.send().await.map_err(|e| CoreError::Transient(e.to_string()))?;
        if !resp.status().is_success() {
            return Err(map_status(resp.status()));
        }
        let mut rows: Vec<serde_json::Value> = resp.json().await.map_err(|e| CoreError::Serde(e.to_string()))?;
        Ok(rows.pop().map(|row| row_to_record(entity_type, row)))
    }

    async fn create(&self, record: &EntityRecord) -> CoreResult<EntityRecord> {
        let value: serde_json::Value =
            serde_json::from_str(&record.data_json).map_err(|e| CoreError::Serde(e.to_string()))?;
        let resp = self
            .apply_bearer(self.http.post(self.table_url(&record.entity_type)))
            .header("Prefer", "return=representation")
            .json(&value)
            .send()
            .await
            .map_err(|e| CoreError::Transient(e.to_string()))?;
        if !resp.status().is_success() {
            return Err(map_status(resp.status()));
        }
        let mut rows: Vec<serde_json::Value> = resp.json().await.map_err(|e| CoreError::Serde(e.to_string()))?;
        let row = rows.pop().ok_or_else(|| CoreError::Terminal("forge create: empty representation".into()))?;
        Ok(row_to_record(&record.entity_type, row))
    }

    async fn update(&self, record: &EntityRecord) -> CoreResult<EntityRecord> {
        let value: serde_json::Value =
            serde_json::from_str(&record.data_json).map_err(|e| CoreError::Serde(e.to_string()))?;
        let url = format!("{}/{}", self.table_url(&record.entity_type), record.id);
        let resp = self
            .apply_bearer(self.http.patch(url))
            .header("Prefer", "return=representation")
            .json(&value)
            .send()
            .await
            .map_err(|e| CoreError::Transient(e.to_string()))?;
        if !resp.status().is_success() {
            return Err(map_status(resp.status()));
        }
        let mut rows: Vec<serde_json::Value> = resp.json().await.map_err(|e| CoreError::Serde(e.to_string()))?;
        let row = rows.pop().ok_or_else(|| CoreError::Terminal("forge update: empty representation".into()))?;
        Ok(row_to_record(&record.entity_type, row))
    }

    async fn delete(&self, entity_type: &str, id: &str) -> CoreResult<()> {
        let url = format!("{}/{}", self.table_url(entity_type), id);
        let resp = self
            .apply_bearer(self.http.delete(url))
            .send()
            .await
            .map_err(|e| CoreError::Transient(e.to_string()))?;
        if !resp.status().is_success() {
            return Err(map_status(resp.status()));
        }
        Ok(())
    }
}

fn row_to_record(entity_type: &str, row: serde_json::Value) -> EntityRecord {
    let id = row
        .get("id")
        .map(|v| v.as_str().map(str::to_owned).unwrap_or_else(|| v.to_string()))
        .unwrap_or_default();
    EntityRecord { id, entity_type: entity_type.to_owned(), data_json: row.to_string() }
}

fn map_status(status: reqwest::StatusCode) -> CoreError {
    use reqwest::StatusCode;
    match status {
        StatusCode::NOT_FOUND => CoreError::NotFound(status.to_string()),
        StatusCode::UNAUTHORIZED | StatusCode::FORBIDDEN => CoreError::Terminal(format!("forge auth: {status}")),
        s if s.is_server_error() || s == StatusCode::TOO_MANY_REQUESTS => CoreError::Transient(s.to_string()),
        s => CoreError::Terminal(format!("forge http {s}")),
    }
}

// ── AG-UI event mapping ─────────────────────────────────────────────────────
// forge emits internally-tagged `AgUiEvent` (`{"type":"TextMessageContent",...}`).
// We translate the subset the ContentBlock contract needs into our A2uiEvent surface
// so the ProtocolPipeline (gen_ui_protocol) folds them into ContentBlocks unchanged.
#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "type")]
pub enum AgUiEvent {
    RunStarted { #[serde(default)] run_id: String },
    TextMessageContent { #[serde(default)] delta: String },
    ToolCallStart { #[serde(default)] tool_call_id: String, #[serde(default)] tool_name: String },
    RunFinished { #[serde(default)] run_id: String },
    RunError { #[serde(default)] message: String },
    #[serde(other)]
    Other,
}

/// Map a forge AG-UI event to zero or more of our A2UI events. Unhandled variants
/// (state deltas, custom surfaces) yield nothing here and are handled by the A2UI
/// surface layer directly — this path only feeds the streaming ContentBlock fold.
pub fn agui_to_a2ui(ev: &AgUiEvent) -> Vec<A2uiEvent> {
    match ev {
        AgUiEvent::RunStarted { run_id } => vec![A2uiEvent::RunStarted { run_id: run_id.clone() }],
        AgUiEvent::TextMessageContent { delta } => {
            vec![A2uiEvent::Block { block: ContentBlock::Text { text: delta.clone() } }]
        }
        AgUiEvent::ToolCallStart { tool_call_id, tool_name } => vec![A2uiEvent::Block {
            block: ContentBlock::ToolUse { id: tool_call_id.clone(), name: tool_name.clone(), input_json: "{}".into() },
        }],
        AgUiEvent::RunFinished { run_id } => vec![A2uiEvent::RunFinished { run_id: run_id.clone() }],
        AgUiEvent::RunError { message } => vec![A2uiEvent::RunError { message: message.clone() }],
        AgUiEvent::Other => vec![],
    }
}

/// Parse one SSE `data:` payload (a JSON AgUiEvent) into A2UI events. Returns an empty
/// vec for keep-alives / unparseable frames rather than erroring the whole stream.
pub fn parse_agui_frame(data: &str) -> Vec<A2uiEvent> {
    match serde_json::from_str::<AgUiEvent>(data) {
        Ok(ev) => agui_to_a2ui(&ev),
        Err(_) => vec![],
    }
}
RUST
  ok "flint/forge.rs: Quarry EntityTransport · MCP registration · AG-UI→A2UI mapping"
}

emit_flint_frf() {
  { echo "$MARK"; cat << 'RUST'; } > "$OUT/crates/gen_ui_client/src/flint/frf.rs"
//! flint-realtime-fabric (FRF) Spine wrapper — feature = "frf", native-only.
//!
//! FRF is tonic gRPC over HTTP/2, which does not build for wasm32-unknown-unknown;
//! the browser surface uses frf-wasm / Connect-web from the JS side instead. This
//! module is compiled only when the `frf` feature is on AND the target is not wasm.
//!
//! VERIFIED (FRF HEAD 2026-07-15): SDK crate `frf-sdk-rust`, entry `FrfClient::connect
//! (endpoint, token)`; `SpineService` publish/subscribe(channel_id,consumer_id,from)/
//! ack over `EventEnvelope`; `EntityService::WatchEntity` streams `EntityChange`.
//! Peer-sync (feature = "peer-crdt") layers `frf-crdt` (Loro) + `frf-store-redb`.
//!
//! We keep this to a thin façade over the SDK so a `SyncTransport` impl (gen_ui_db::
//! sync, C-005) or the agent loop can drive the spine without re-learning proto types.

use gen_ui_types::sync::SyncStatus;

/// FRF connection parameters. `token` is the gate-minted Bearer the SDK's
/// `AuthInterceptor` injects on every RPC.
#[derive(Debug, Clone)]
pub struct FrfConfig {
    pub endpoint: String,
    pub token: Option<String>,
    pub tenant_id: String,
}

/// Thin handle around `frf_sdk_rust::FrfClient`. Constructed lazily by the façade so
/// a build without a reachable spine (offline-first boot) does not fail at startup.
pub struct FrfSpine {
    config: FrfConfig,
    #[cfg(feature = "frf")]
    client: parking_lot::Mutex<Option<frf_sdk_rust::FrfClient>>,
    status: parking_lot::RwLock<SyncStatus>,
}

impl FrfSpine {
    pub fn new(config: FrfConfig) -> Self {
        Self {
            config,
            #[cfg(feature = "frf")]
            client: parking_lot::Mutex::new(None),
            status: parking_lot::RwLock::new(SyncStatus::Offline),
        }
    }

    pub fn status(&self) -> SyncStatus {
        self.status.read().clone()
    }

    pub fn tenant_id(&self) -> &str {
        &self.config.tenant_id
    }

    /// Connect (or reconnect) the Spine client. Only compiled with `frf`.
    #[cfg(feature = "frf")]
    pub async fn connect(&self) -> gen_ui_types::CoreResult<()> {
        use gen_ui_types::CoreError;
        let client = frf_sdk_rust::FrfClient::connect(self.config.endpoint.clone(), self.config.token.clone())
            .await
            .map_err(|e| CoreError::Transient(format!("frf connect: {e}")))?;
        *self.client.lock() = Some(client);
        *self.status.write() = SyncStatus::Live;
        Ok(())
    }

    /// Placeholder connect for builds without the `frf` feature — the offline path.
    #[cfg(not(feature = "frf"))]
    pub async fn connect(&self) -> gen_ui_types::CoreResult<()> {
        Err(gen_ui_types::CoreError::Terminal(
            "frf feature not enabled (native-only spine)".into(),
        ))
    }
}

// Peer CRDT op-log lane (feature = "peer-crdt"): re-export the on-device store + Loro
// applier so gen_ui_db::sync (C-005) can build the OFP-style peer path without adding
// FRF as a direct dependency. Kept behind the feature so redb never enters the default
// dependency graph.
#[cfg(feature = "peer-crdt")]
pub mod peer {
    pub use frf_crdt::LoroDeltaApplier;
    pub use frf_store_redb::RedbOpStore;
}
RUST
  ok "flint/frf.rs: Spine façade (feature=frf, native-only) · peer-crdt re-exports"
}

emit_flint_mod() {
  { echo "$MARK"; cat << 'RUST'; } > "$OUT/crates/gen_ui_client/src/flint/mod.rs"
//! Flint integration façade. One [`FlintClient`] wires the three planes together and
//! shares a single auth handle (a refreshed token is seen everywhere at once).
//!
//! `token` (JWT claims/lifecycle) is pure and cross-target. The IO planes (`gate`,
//! `forge`, `frf`) and the `FlintClient` façade are reqwest/tonic-driven and native-
//! only — on the browser the same planes are reached from JS (Connect-web / PGlite /
//! `@flint/react`) per the TJ-ARCH-MOB-001 layer contract.
pub mod token;

pub use token::{AuthState as FlintAuthState, Claims, Role, Token};

#[cfg(not(target_arch = "wasm32"))]
pub mod gate;
#[cfg(not(target_arch = "wasm32"))]
pub mod forge;
#[cfg(not(target_arch = "wasm32"))]
pub mod frf;

#[cfg(not(target_arch = "wasm32"))]
pub use client_impl::{FlintClient, FlintConfig};

#[cfg(not(target_arch = "wasm32"))]
mod client_impl {
use super::forge::{ForgeClient, ForgeConfig, SharedAuth};
use super::gate::{GateClient, GateConfig};
use super::frf;
use super::token::{AuthState, Role};
use gen_ui_mcp::McpRegistry;
use gen_ui_types::CoreResult;
use std::sync::Arc;

/// Everything needed to talk to a Flint deployment. Ports/paths carry verified
/// defaults (gate :4456/:4457, forge :8080) — override per environment.
#[derive(Debug, Clone)]
pub struct FlintConfig {
    pub gate: GateConfig,
    pub forge: ForgeConfig,
    pub frf: Option<frf::FrfConfig>,
}

/// The single entry point the agent loop / db-sync lane depends on. Owns the shared
/// auth state; `gate()`/`forge()` hand out plane clients bound to it.
pub struct FlintClient {
    http: reqwest::Client,
    config: FlintConfig,
    auth: SharedAuth,
    registry: McpRegistry,
}

impl FlintClient {
    pub fn new(config: FlintConfig) -> Self {
        Self {
            http: reqwest::Client::new(),
            config,
            auth: Arc::new(parking_lot::RwLock::new(AuthState::Unauthenticated)),
            registry: McpRegistry::new(),
        }
    }

    pub fn gate(&self) -> GateClient {
        GateClient::new(self.http.clone(), self.config.gate.clone())
    }

    pub fn forge(&self) -> ForgeClient {
        ForgeClient::new(self.http.clone(), self.config.forge.clone(), self.auth.clone())
    }

    pub fn registry(&self) -> &McpRegistry {
        &self.registry
    }

    /// Boot with the static anon key so unauthenticated (public) surfaces work
    /// immediately; a later Kratos exchange upgrades the same shared auth handle.
    pub fn boot_anon(&self) -> CoreResult<()> {
        let state = self.gate().boot_anon()?;
        *self.auth.write() = state;
        Ok(())
    }

    /// Exchange a Kratos session for an authenticated/agent JWT and store it.
    pub async fn login_with_kratos(&self, kratos_cookie: &str) -> CoreResult<Role> {
        let state = self.gate().exchange_kratos_session(kratos_cookie).await?;
        let role = state.role();
        *self.auth.write() = state;
        Ok(role)
    }

    /// Register forge's A2UI registry as an MCP server into this client's registry.
    pub fn register_forge_mcp(&self) -> Arc<gen_ui_mcp::McpServerHandle> {
        self.forge().register_a2ui_mcp(&self.registry)
    }

    pub fn auth_role(&self) -> Role {
        self.auth.read().role()
    }
}
} // mod client_impl (native-only)
RUST
  ok "flint/mod.rs: FlintClient façade (shared auth · gate/forge/registry wiring)"
}

emit_flint_tests() {
  # Behavior tests at the crate's PUBLIC boundary (CLAUDE.md philosophy: features
  # first, 3-5 boundary tests at completion, no internal mocks, pure I/O-free).
  # One integration binary per crate (tests/it.rs) — separate files link separately.
  mkdir -p "$OUT/crates/gen_ui_client/tests"
  { echo "$MARK"; cat << 'RUST'; } > "$OUT/crates/gen_ui_client/tests/it.rs"
//! Boundary tests for the flint client. No network, no mocks — the observable
//! behavior is: (1) a gate JWT decodes to the right role/tenant and expiry drives the
//! AuthState machine; (2) forge AG-UI SSE frames fold into the ContentBlock contract.
#![cfg(not(target_arch = "wasm32"))]

use gen_ui_client::flint::token::{AuthState, Role, Token};
use gen_ui_client::flint::forge::{parse_agui_frame, AgUiEvent, agui_to_a2ui};
use gen_ui_types::content_block::ContentBlock;
use gen_ui_types::events::A2uiEvent;

/// Mint an unsigned-payload HS256 JWT for the given claims (test-only; the client
/// decodes WITHOUT verification, mirroring the real "gate/forge own verification").
fn mint(claims: serde_json::Value) -> String {
    use jsonwebtoken::{encode, EncodingKey, Header};
    encode(&Header::default(), &claims, &EncodingKey::from_secret(b"test")).expect("encode")
}

#[test]
fn token_decodes_role_and_tenant_from_gate_claims() {
    // Mirrors forge-identity::Claims: typed sub/role/tenant_id + untyped extra.
    let jwt = mint(serde_json::json!({
        "sub": "user-42", "role": "agent", "tenant_id": "acme",
        "exp": 9_999_999_999i64, "agent_id": "planner", "act": "user-42",
    }));
    let token = Token::parse(&jwt).expect("parse");
    assert_eq!(token.role(), Role::Agent);
    assert_eq!(token.claims.tenant_id.as_deref(), Some("acme"));
    // `act`/`agent_id` are untyped per the platform contract — read from `extra`.
    assert_eq!(token.claims.extra_str("agent_id"), Some("planner"));
    assert_eq!(token.claims.extra_str("act"), Some("user-42"));
}

#[test]
fn absent_role_coerces_to_anon() {
    let jwt = mint(serde_json::json!({ "sub": "x", "exp": 9_999_999_999i64 }));
    let token = Token::parse(&jwt).expect("parse");
    assert_eq!(token.role(), Role::Anon);
}

#[test]
fn auth_state_machine_tracks_bearer_and_refresh() {
    let fresh = mint(serde_json::json!({ "sub": "a", "role": "authenticated", "exp": 9_999_999_999i64 }));
    let state = AuthState::Authenticated { token: Token::parse(&fresh).unwrap() };
    assert_eq!(state.role(), Role::Authenticated);
    assert!(state.bearer().is_some());
    assert!(!state.needs_refresh(1_000)); // far from exp
    assert!(state.needs_refresh(9_999_999_999)); // at/after exp (with skew)

    // Unauthenticated carries no bearer and is never "refreshable".
    let empty = AuthState::Unauthenticated;
    assert!(empty.bearer().is_none());
    assert!(!empty.needs_refresh(9_999_999_999));
}

#[test]
fn agui_text_delta_folds_to_content_block_text() {
    let frame = r#"{"type":"TextMessageContent","delta":"hello"}"#;
    let events = parse_agui_frame(frame);
    assert_eq!(events.len(), 1);
    match &events[0] {
        A2uiEvent::Block { block: ContentBlock::Text { text } } => assert_eq!(text, "hello"),
        other => panic!("expected Text block, got {other:?}"),
    }
}

#[test]
fn agui_run_lifecycle_and_toolcall_map_to_a2ui() {
    // RunStarted → A2uiEvent::RunStarted.
    let started = agui_to_a2ui(&AgUiEvent::RunStarted { run_id: "r1".into() });
    assert!(matches!(started.as_slice(), [A2uiEvent::RunStarted { run_id }] if run_id == "r1"));

    // ToolCallStart → a ToolUse ContentBlock (name + id preserved).
    let tool = parse_agui_frame(r#"{"type":"ToolCallStart","tool_call_id":"t9","tool_name":"search"}"#);
    match tool.as_slice() {
        [A2uiEvent::Block { block: ContentBlock::ToolUse { id, name, .. } }] => {
            assert_eq!(id, "t9");
            assert_eq!(name, "search");
        }
        other => panic!("expected ToolUse block, got {other:?}"),
    }

    // Unknown/keepalive frames yield nothing rather than erroring the stream.
    assert!(parse_agui_frame(":keep-alive").is_empty());
    assert!(parse_agui_frame(r#"{"type":"StateDelta","delta":[]}"#).is_empty());
}
RUST
  ok "flint tests: token lifecycle · AuthState machine · AG-UI→ContentBlock folding"
}

# ── L2 gen_ui_mcp — MCP client registry (C-006) ─────────────────────────────
# Minimal MCP (Model Context Protocol) client: JSON-RPC 2.0 over HTTP POST with an
# SSE event channel. This is the seam flint-forge's A2UI-registry-as-MCP-server
# (/mcp/v1/a2ui) registers into. SSE transport is wasm-safe (fetch/EventSource);
# stdio transport is native-only and feature-gated off by default.

# emit_graph_rag_crate — C-004. Full gen_ui_db_graph crate: SurrealDB 3.2 embedded
# hybrid graph-RAG. All Rust bodies use quoted heredocs (<< 'RUST') so SurrealQL
# $bind placeholders and Rust expressions are written verbatim; the compliance
# marker is inlined literally rather than via $MARK for the same reason.
emit_graph_rag_crate() {
  emit_crate gen_ui_db_graph ""
  local d="$OUT/crates/gen_ui_db_graph"
  mkdir -p "$d/src" "$d/tests/it"

  cat >> "$d/Cargo.toml" << 'EOF'
gen_ui_types   = { path = "../gen_ui_types" }
gen_ui_runtime = { path = "../gen_ui_runtime" }
workspace-hack = { path = "../workspace-hack" }
async-trait.workspace = true
serde.workspace = true
serde_json.workspace = true
thiserror.workspace = true
tracing.workspace = true
futures.workspace = true

# SurrealDB engine is target-split so the native build gets RocksDB (persistent,
# incl. iOS/Android) and wasm gets IndexedDB — the only embedded KV that links on
# wasm32. Both share the same SurrealQL surface, so store.rs is target-agnostic.
[target.'cfg(not(target_arch = "wasm32"))'.dependencies]
surrealdb = { workspace = true, features = ["kv-rocksdb", "kv-mem"] }
# fastembed pulls ONNX Runtime — native only. On wasm the embedder is supplied by
# the host (JS transformers.js) through the Embedder trait, so fastembed is absent.
fastembed = { workspace = true, optional = true }

[target.'cfg(target_arch = "wasm32")'.dependencies]
surrealdb = { workspace = true, features = ["kv-indxdb"] }

[features]
# `embed-native` wires the on-device fastembed model. Off by default so the crate
# (and its boundary tests) build without downloading an ONNX model; leaves that
# ship inference enable it. wasm never gets it.
default = []
embed-native = ["dep:fastembed"]

[dev-dependencies]
tokio = { workspace = true, features = ["rt", "macros"] }

# One integration-test binary (tests/it/main.rs) — every extra tests/*.rs is a
# separately linked binary and linking dominates the SurrealDB compile cycle.
[[test]]
name = "it"
path = "tests/it/main.rs"
EOF

  # ── lib.rs ──────────────────────────────────────────────────────────────────
  cat > "$d/src/lib.rs" << 'RUST'
// TJ-ARCH-MOB-001 compliant
//! gen_ui_db_graph (L2) — SurrealDB 3.2 embedded hybrid graph-RAG store.
//!
//! Owns the knowledge-graph half of the data layer (relational + sync live in
//! `gen_ui_db`). SurrealDB is isolated here on purpose: surrealdb-core's build.rs
//! re-runs on any downstream change (surrealdb#6954), so keeping it in its own
//! crate keeps the rest of the workspace off that slow recompile path.
//!
//! Engines: `kv-rocksdb` on native (persistent, incl. iOS/Android), `kv-indxdb`
//! on wasm32 (the only embedded KV that links in the browser).
//!
//! The public surface is INTENT-LEVEL, never raw SurrealQL — there is no official
//! Dart SurrealDB SDK, so `gen_ui_ffi` re-exports these functions and Dart calls
//! `memory_search` / `graph_expand` / `memory_ingest`, not queries. Keeping SurrealQL
//! private also means the schema can change without breaking the FFI contract.
//!
//! Hybrid retrieval pipeline (`memory_search`):
//!   1. HNSW vector recall  — semantic nearest neighbours (384-dim embeddings)
//!   2. BM25 full-text lane — lexical matches the vector lane misses
//!   3. `search::rrf()`     — reciprocal-rank fusion of (1) and (2) IN the DB
//!   4. graph expansion     — RELATE-edge neighbours of the fused hits, re-fused
//!      in Rust (`rrf`) because it is not one SurrealQL statement
#![forbid(unsafe_code)]

mod embed;
mod error;
mod rrf;
mod schema;
mod store;

pub use embed::{Embedder, EmbeddingModelInfo, EMBED_DIM};
pub use error::GraphError;
pub use rrf::{rrf_fuse, RrfConfig};
pub use store::{GraphStore, GraphStoreConfig, MemoryHit, MemoryRecord, RelatedEntity};

#[cfg(feature = "embed-native")]
pub use embed::FastEmbedder;

/// Result alias for graph-store operations. `GraphError` maps cleanly into the
/// workspace-wide `gen_ui_types::CoreError` via `From`, so callers at the FFI
/// boundary propagate one error taxonomy.
pub type GraphResult<T> = Result<T, GraphError>;
RUST

  # ── error.rs ────────────────────────────────────────────────────────────────
  cat > "$d/src/error.rs" << 'RUST'
// TJ-ARCH-MOB-001 compliant
//! Error taxonomy for the graph store, with a lossless map into the shared
//! `gen_ui_types::CoreError` so the FFI boundary sees one error type.
use gen_ui_types::CoreError;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum GraphError {
    #[error("surreal: {0}")]
    Surreal(String),
    #[error("embedding: {0}")]
    Embedding(String),
    #[error("serialize: {0}")]
    Serialize(String),
    #[error("invalid input: {0}")]
    Invalid(String),
    #[error("not found: {0}")]
    NotFound(String),
}

impl From<surrealdb::Error> for GraphError {
    fn from(e: surrealdb::Error) -> Self {
        GraphError::Surreal(e.to_string())
    }
}

impl From<serde_json::Error> for GraphError {
    fn from(e: serde_json::Error) -> Self {
        GraphError::Serialize(e.to_string())
    }
}

impl From<GraphError> for CoreError {
    fn from(e: GraphError) -> Self {
        match e {
            // A dead embedded DB / locked file is worth a retry; a bad query is not.
            GraphError::Surreal(m) => CoreError::Transient(m),
            GraphError::Embedding(m) => CoreError::Transient(m),
            GraphError::Serialize(m) => CoreError::Serde(m),
            GraphError::Invalid(m) => CoreError::Terminal(m),
            GraphError::NotFound(m) => CoreError::NotFound(m),
        }
    }
}
RUST

  # ── embed.rs ────────────────────────────────────────────────────────────────
  cat > "$d/src/embed.rs" << 'RUST'
// TJ-ARCH-MOB-001 compliant
//! On-device text embedding behind a trait, so the store depends on the
//! *capability* not on fastembed. Native leaves enable `embed-native` for the
//! real ONNX model; wasm hosts inject a JS-backed embedder; tests inject a
//! deterministic fake and never touch the network.
use crate::error::GraphError;

/// Embedding width. 384 = all-MiniLM-L6-v2 / bge-small class. Standardised across
/// every engine (SQLite-vec, pgvector, SurrealDB HNSW) so vectors replicate cleanly
/// — the HNSW index in `schema.rs` is defined `DIMENSION 384` to match.
pub const EMBED_DIM: usize = 384;

/// Model provenance, surfaced so a store can refuse to mix embeddings from
/// different models in one index (silent dimension/space drift is a classic RAG bug).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EmbeddingModelInfo {
    pub name: String,
    pub dim: usize,
}

/// The embedding capability the store needs. `embed` is batch-oriented because
/// fastembed and every ONNX backend amortise best over a batch; a single string
/// is just a one-element batch.
///
/// Implementors run CPU-bound inference — callers on the async path must invoke
/// them inside `gen_ui_runtime::spawn_blocking` (see `store::GraphStore::embed_blocking`).
pub trait Embedder: Send + Sync {
    fn model_info(&self) -> EmbeddingModelInfo;
    fn embed(&self, texts: &[String]) -> Result<Vec<Vec<f32>>, GraphError>;
}

#[cfg(feature = "embed-native")]
mod native {
    use super::*;
    use fastembed::{EmbeddingModel, TextEmbedding, TextInitOptions};
    use std::sync::Mutex;

    /// fastembed-backed embedder (all-MiniLM-L6-v2, 384-dim). Downloads the ONNX
    /// model to `FASTEMBED_CACHE_DIR` on first use, then runs fully offline.
    /// `TextEmbedding` is not `Sync`, so it sits behind a `Mutex`; embedding is
    /// short and always called off the async runtime via `spawn_blocking`.
    pub struct FastEmbedder {
        inner: Mutex<TextEmbedding>,
    }

    impl FastEmbedder {
        /// Load the default 384-dim model. Blocking (may download) — construct at
        /// startup off the async runtime.
        pub fn new() -> Result<Self, GraphError> {
            let model = TextEmbedding::try_new(
                TextInitOptions::new(EmbeddingModel::AllMiniLML6V2),
            )
            .map_err(|e| GraphError::Embedding(e.to_string()))?;
            Ok(Self { inner: Mutex::new(model) })
        }
    }

    impl Embedder for FastEmbedder {
        fn model_info(&self) -> EmbeddingModelInfo {
            EmbeddingModelInfo { name: "all-MiniLM-L6-v2".into(), dim: EMBED_DIM }
        }

        fn embed(&self, texts: &[String]) -> Result<Vec<Vec<f32>>, GraphError> {
            let mut model = self
                .inner
                .lock()
                .map_err(|_| GraphError::Embedding("embedder mutex poisoned".into()))?;
            let out = model
                .embed(texts.to_vec(), None)
                .map_err(|e| GraphError::Embedding(e.to_string()))?;
            for v in &out {
                if v.len() != EMBED_DIM {
                    return Err(GraphError::Embedding(format!(
                        "model returned dim {}, expected {EMBED_DIM}",
                        v.len()
                    )));
                }
            }
            Ok(out)
        }
    }
}

#[cfg(feature = "embed-native")]
pub use native::FastEmbedder;
RUST

  # ── schema.rs ───────────────────────────────────────────────────────────────
  cat > "$d/src/schema.rs" << 'RUST'
// TJ-ARCH-MOB-001 compliant
//! SurrealDB 3.2 schema DDL. Kept as `OVERWRITE`/`IF NOT EXISTS` statements so
//! `GraphStore::init` is idempotent — safe to run on every boot (greenfield; no
//! in-place 2.x→3.x migration path per the analysis, which is fine for new stores).
//!
//! 3.x syntax notes (breaking vs 2.x, verified against SurrealDB 3.2 docs):
//!   * vector index is `HNSW DIMENSION n DIST COSINE` (MTREE was removed in 3.0)
//!   * full-text index is `FULLTEXT ANALYZER <a> BM25` (was `SEARCH ANALYZER`)
//!   * `search::rrf([...], k, limit)` fuses ranked lists natively (added in 3.0)

/// Analyzer + entity/memory tables + HNSW and BM25 indexes + the RELATE edge table.
/// One string so `init` runs it in a single `.query()` round-trip.
pub const SCHEMA_DDL: &str = r#"
-- Full-text analyzer: whitespace + class + camelCase splitting, English stemming.
DEFINE ANALYZER OVERWRITE gu_simple
    TOKENIZERS blank, class, camel, punct
    FILTERS lowercase, snowball(english);

-- entity: nodes in the knowledge graph (projects, notes, people, ...).
DEFINE TABLE IF NOT EXISTS entity SCHEMALESS;
DEFINE FIELD IF NOT EXISTS entity_type ON entity TYPE string;
DEFINE FIELD IF NOT EXISTS label       ON entity TYPE string;
DEFINE FIELD IF NOT EXISTS data        ON entity FLEXIBLE TYPE option<object>;

-- memory: retrievable text with its embedding; optionally linked to an entity.
DEFINE TABLE IF NOT EXISTS memory SCHEMALESS;
DEFINE FIELD IF NOT EXISTS text      ON memory TYPE string;
DEFINE FIELD IF NOT EXISTS kind      ON memory TYPE string DEFAULT 'note';
DEFINE FIELD IF NOT EXISTS entity    ON memory TYPE option<record<entity>>;
DEFINE FIELD IF NOT EXISTS embedding ON memory TYPE array<float>;
DEFINE FIELD IF NOT EXISTS created   ON memory TYPE datetime DEFAULT time::now();

-- HNSW vector index — semantic recall. 384 dims to match all-MiniLM-L6-v2 / bge-small.
DEFINE INDEX OVERWRITE memory_hnsw ON memory
    FIELDS embedding HNSW DIMENSION 384 DIST COSINE;

-- BM25 full-text index — lexical recall the vector lane misses.
DEFINE INDEX OVERWRITE memory_ft ON memory
    FIELDS text FULLTEXT ANALYZER gu_simple BM25;

-- relates_to: typed graph edges between entities, traversed by graph_expand.
DEFINE TABLE IF NOT EXISTS relates_to SCHEMALESS TYPE RELATION FROM entity TO entity;
DEFINE FIELD IF NOT EXISTS rel ON relates_to TYPE string DEFAULT 'related';
"#;

/// Hybrid recall: vector lane + BM25 lane, fused by native `search::rrf`.
/// Binds: `$qvec` (query embedding), `$q` (query text), `$k` (neighbours).
/// Returns one ranked list of `{ id, text, kind, entity, score }`.
///
/// `<|$k,64|>` = return `$k` HNSW neighbours exploring up to 64 candidates.
/// RRF k=60 is the standard smoothing constant; limit 128 caps fusion input.
pub const HYBRID_SEARCH_QUERY: &str = r#"
LET $vs = SELECT id, text, kind, entity, vector::distance::knn() AS distance
    FROM memory WHERE embedding <|$k,64|> $qvec
    ORDER BY distance ASC LIMIT 64;
LET $ft = SELECT id, text, kind, entity, search::score(0) AS ft_score
    FROM memory WHERE text @0@ $q
    ORDER BY ft_score DESC LIMIT 64;
SELECT meta::id(id) AS id, text, kind, rrf_score AS score
    FROM search::rrf([$vs, $ft], 60, 128)
    LIMIT $k;
"#;
RUST

  # ── rrf.rs ──────────────────────────────────────────────────────────────────
  cat > "$d/src/rrf.rs" << 'RUST'
// TJ-ARCH-MOB-001 compliant
//! Reciprocal-Rank Fusion in Rust — used for the graph-expansion lane, which
//! cannot be expressed as one SurrealQL statement (the DB's `search::rrf` fuses
//! the vector+BM25 lanes; the RELATE-neighbour lane is fused here).
//!
//! RRF score for an item = Σ over lists of `1 / (k + rank)`, rank 0-based. `k`
//! damps the contribution of low-ranked items; 60 is the canonical default.

/// Fusion tuning. `k` is the RRF smoothing constant; `limit` caps the output.
#[derive(Debug, Clone, Copy)]
pub struct RrfConfig {
    pub k: f32,
    pub limit: usize,
}

impl Default for RrfConfig {
    fn default() -> Self {
        Self { k: 60.0, limit: 20 }
    }
}

/// Fuse several ranked lists of ids into one, highest RRF score first.
/// Each inner slice is one lane already in rank order (best first). Ids may repeat
/// across lanes; their contributions sum. Ties break on id for determinism (so
/// snapshot tests are stable).
pub fn rrf_fuse(lanes: &[Vec<String>], cfg: RrfConfig) -> Vec<(String, f32)> {
    use std::collections::HashMap;
    let mut scores: HashMap<&str, f32> = HashMap::new();
    for lane in lanes {
        for (rank, id) in lane.iter().enumerate() {
            *scores.entry(id.as_str()).or_insert(0.0) += 1.0 / (cfg.k + rank as f32);
        }
    }
    let mut fused: Vec<(String, f32)> =
        scores.into_iter().map(|(id, s)| (id.to_string(), s)).collect();
    fused.sort_by(|a, b| {
        b.1.partial_cmp(&a.1)
            .unwrap_or(std::cmp::Ordering::Equal)
            .then_with(|| a.0.cmp(&b.0))
    });
    fused.truncate(cfg.limit);
    fused
}
RUST

  # ── store.rs ────────────────────────────────────────────────────────────────
  cat > "$d/src/store.rs" << 'RUST'
// TJ-ARCH-MOB-001 compliant
//! `GraphStore` — the intent-level API over SurrealDB. Callers (FFI, agent) use
//! `memory_ingest` / `memory_search` / `graph_expand`; SurrealQL never leaves this
//! module.
use crate::embed::{Embedder, EMBED_DIM};
use crate::error::GraphError;
use crate::rrf::{rrf_fuse, RrfConfig};
use crate::schema::{HYBRID_SEARCH_QUERY, SCHEMA_DDL};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use surrealdb::engine::any::{connect, Any};
use surrealdb::types::SurrealValue;
use surrealdb::Surreal;

/// Where the embedded store lives and how it is embedded.
pub struct GraphStoreConfig {
    /// SurrealDB connection endpoint. Native persistent: `rocksdb://<path>`.
    /// Tests / ephemeral: `memory`. wasm: `indxdb://<name>`.
    pub endpoint: String,
    pub namespace: String,
    pub database: String,
    /// Embedding backend. Behind `Arc` so it can be shared across concurrent calls.
    pub embedder: Arc<dyn Embedder>,
}

/// A memory row as ingested. `id` is `None` on the way in (DB assigns it).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MemoryRecord {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    pub text: String,
    #[serde(default = "default_kind")]
    pub kind: String,
    /// Optional owning entity record id (e.g. `entity:project_x`).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub entity: Option<String>,
}

fn default_kind() -> String {
    "note".to_string()
}

/// One hybrid-search hit. `score` is the fused RRF score (higher = better).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MemoryHit {
    pub id: String,
    pub text: String,
    pub kind: String,
    pub score: f32,
}

/// A neighbour reached by graph expansion, with the RRF score from re-fusing the
/// expansion lanes.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RelatedEntity {
    pub id: String,
    pub label: String,
    pub entity_type: String,
    pub score: f32,
}

impl GraphStore {
    /// Open (or create) the embedded store, select ns/db, and apply the schema.
    /// Idempotent: safe on every boot.
    pub async fn open(cfg: GraphStoreConfig) -> Result<Self, GraphError> {
        let model = cfg.embedder.model_info();
        if model.dim != EMBED_DIM {
            return Err(GraphError::Invalid(format!(
                "embedder dim {} != index dim {EMBED_DIM} ({})",
                model.dim, model.name
            )));
        }
        let db = connect(&cfg.endpoint).await?;
        db.use_ns(&cfg.namespace).use_db(&cfg.database).await?;
        let store = Self { db, embedder: cfg.embedder };
        store.init().await?;
        Ok(store)
    }

    async fn init(&self) -> Result<(), GraphError> {
        let mut res = self.db.query(SCHEMA_DDL).await?;
        // DDL errors surface per-statement, not as a query-level Err — surface the
        // first so a bad schema fails loudly at boot instead of at first search.
        if let Some((idx, err)) = res.take_errors().into_iter().next() {
            return Err(GraphError::Surreal(format!("schema stmt {idx}: {err}")));
        }
        Ok(())
    }

    /// Run the (synchronous, CPU-bound) embedder off the async runtime.
    async fn embed_blocking(&self, texts: Vec<String>) -> Result<Vec<Vec<f32>>, GraphError> {
        let embedder = Arc::clone(&self.embedder);
        gen_ui_runtime::spawn_blocking(move || embedder.embed(&texts))
            .await
            .map_err(|e| GraphError::Embedding(format!("embed task join: {e}")))?
    }

    /// INTENT: ingest a memory. Embeds `text`, stores row + vector, returns the id.
    pub async fn memory_ingest(&self, record: MemoryRecord) -> Result<String, GraphError> {
        if record.text.trim().is_empty() {
            return Err(GraphError::Invalid("memory text is empty".into()));
        }
        let embedding = self
            .embed_blocking(vec![record.text.clone()])
            .await?
            .into_iter()
            .next()
            .ok_or_else(|| GraphError::Embedding("embedder returned no vector".into()))?;

        let mut res = self
            .db
            .query(
                "CREATE memory SET text = $text, kind = $kind, embedding = $embedding, \
                 entity = IF $entity != NONE THEN type::record($entity) ELSE NONE END \
                 RETURN meta::id(id) AS id;",
            )
            .bind(("text", record.text))
            .bind(("kind", record.kind))
            .bind(("embedding", embedding))
            .bind(("entity", record.entity))
            .await?;
        let ids: Vec<IdRow> = res.take(0)?;
        ids.into_iter()
            .next()
            .map(|r| r.id)
            .ok_or_else(|| GraphError::Surreal("ingest returned no id".into()))
    }

    /// INTENT: create (or upsert) a graph entity node. `id` is the record key
    /// (e.g. `project_x`); `label`/`entity_type` are indexed graph metadata.
    pub async fn create_entity(
        &self,
        id: &str,
        entity_type: &str,
        label: &str,
    ) -> Result<String, GraphError> {
        if id.trim().is_empty() {
            return Err(GraphError::Invalid("entity id is empty".into()));
        }
        let mut res = self
            .db
            .query(
                "UPSERT type::thing('entity', $id) \
                 SET entity_type = $etype, label = $label \
                 RETURN meta::id(id) AS id;",
            )
            .bind(("id", id.to_string()))
            .bind(("etype", entity_type.to_string()))
            .bind(("label", label.to_string()))
            .await?;
        let ids: Vec<IdRow> = res.take(0)?;
        ids.into_iter()
            .next()
            .map(|r| r.id)
            .ok_or_else(|| GraphError::Surreal("create_entity returned no id".into()))
    }

    /// INTENT: create a directed RELATE edge `from -> to` with a relation label.
    /// Edges are what `graph_expand` traverses.
    pub async fn relate(&self, from: &str, to: &str, rel: &str) -> Result<(), GraphError> {
        if from.trim().is_empty() || to.trim().is_empty() {
            return Err(GraphError::Invalid("relate endpoints must be non-empty".into()));
        }
        self.db
            .query(
                "RELATE type::thing('entity', $from)->relates_to->type::thing('entity', $to) \
                 SET rel = $rel;",
            )
            .bind(("from", from.to_string()))
            .bind(("to", to.to_string()))
            .bind(("rel", rel.to_string()))
            .await?;
        Ok(())
    }

    /// INTENT: hybrid semantic + lexical search. Embeds `query`, runs the vector
    /// and BM25 lanes, fuses them with native `search::rrf`, returns top-`k`.
    pub async fn memory_search(&self, query: &str, k: usize) -> Result<Vec<MemoryHit>, GraphError> {
        if query.trim().is_empty() {
            return Err(GraphError::Invalid("search query is empty".into()));
        }
        let qvec = self
            .embed_blocking(vec![query.to_string()])
            .await?
            .into_iter()
            .next()
            .ok_or_else(|| GraphError::Embedding("embedder returned no vector".into()))?;

        let mut res = self
            .db
            .query(HYBRID_SEARCH_QUERY)
            .bind(("qvec", qvec))
            .bind(("q", query.to_string()))
            .bind(("k", k as i64))
            .await?;
        // The SELECT is the last statement in the multi-statement query. Bind the
        // index first — `take(&mut self)` and `num_statements(&self)` can't borrow
        // `res` in the same expression.
        let last = res.num_statements().saturating_sub(1);
        let rows: Vec<HitRow> = res.take(last)?;
        Ok(rows.into_iter().map(HitRow::into_hit).collect())
    }

    /// INTENT: expand the graph outward from `entity_id` up to `depth` RELATE hops,
    /// fusing per-depth neighbour lists with Rust RRF (nearer hops rank higher).
    pub async fn graph_expand(
        &self,
        entity_id: &str,
        depth: u8,
    ) -> Result<Vec<RelatedEntity>, GraphError> {
        if depth == 0 {
            return Err(GraphError::Invalid("depth must be >= 1".into()));
        }
        // One lane per hop distance; closer hops fuse to higher RRF scores.
        let mut lanes: Vec<Vec<String>> = Vec::with_capacity(depth as usize);
        let mut frontier = vec![entity_id.to_string()];
        let mut seen = std::collections::HashSet::new();
        seen.insert(entity_id.to_string());

        for _ in 0..depth {
            let mut res = self
                .db
                .query(
                    "SELECT VALUE ->relates_to->entity.map(|$e| meta::id($e)) \
                     FROM $frontier.map(|$id| type::thing('entity', $id));",
                )
                .bind(("frontier", frontier.clone()))
                .await?;
            let hops: Vec<Vec<String>> = res.take(0)?;
            let next: Vec<String> = hops
                .into_iter()
                .flatten()
                .filter(|id| seen.insert(id.clone()))
                .collect();
            if next.is_empty() {
                break;
            }
            lanes.push(next.clone());
            frontier = next;
        }

        let fused = rrf_fuse(&lanes, RrfConfig::default());
        if fused.is_empty() {
            return Ok(vec![]);
        }
        // Hydrate the fused ids into labelled entities, preserving fusion order.
        let ids: Vec<String> = fused.iter().map(|(id, _)| id.clone()).collect();
        let mut res = self
            .db
            .query(
                "SELECT meta::id(id) AS id, label, entity_type \
                 FROM entity WHERE meta::id(id) IN $ids;",
            )
            .bind(("ids", ids))
            .await?;
        let rows: Vec<EntityRow> = res.take(0)?;
        let by_id: std::collections::HashMap<String, EntityRow> =
            rows.into_iter().map(|r| (r.id.clone(), r)).collect();
        Ok(fused
            .into_iter()
            .filter_map(|(id, score)| {
                by_id.get(&id).map(|r| RelatedEntity {
                    id: id.clone(),
                    label: r.label.clone(),
                    entity_type: r.entity_type.clone(),
                    score,
                })
            })
            .collect())
    }
}

/// Handle to the embedded SurrealDB plus the shared embedder.
pub struct GraphStore {
    db: Surreal<Any>,
    embedder: Arc<dyn Embedder>,
}

// SurrealDB 3.2's `IndexedResults::take` deserializes into `SurrealValue`, not
// serde — so the row structs read back from `.query()` derive `SurrealValue`.
// (The public API types — MemoryRecord/MemoryHit/RelatedEntity — stay serde-based
// because they cross the FFI boundary as JSON.) Every field is projected as a
// primitive (`meta::id(id)` → String) so no RecordId handling is needed here.
#[derive(SurrealValue)]
struct IdRow {
    id: String,
}

#[derive(SurrealValue)]
struct HitRow {
    id: String,
    text: String,
    kind: String,
    score: f32,
}

impl HitRow {
    fn into_hit(self) -> MemoryHit {
        MemoryHit { id: self.id, text: self.text, kind: self.kind, score: self.score }
    }
}

#[derive(SurrealValue)]
struct EntityRow {
    id: String,
    label: String,
    entity_type: String,
}
RUST

  # ── tests/it/main.rs (boundary tests, features-first) ────────────────────────
  cat > "$d/tests/it/main.rs" << 'RUST'
// TJ-ARCH-MOB-001 compliant
//! Boundary tests for gen_ui_db_graph — exercised at the public intent API over a
//! real in-memory SurrealDB (`memory` engine) with a deterministic fake embedder,
//! so no ONNX download and no flakiness. Per CLAUDE.md: 3–5 behaviour tests at the
//! API surface, no internal mocks, features-first.
mod fake_embedder;

use fake_embedder::HashEmbedder;
use gen_ui_db_graph::{GraphStore, GraphStoreConfig, MemoryRecord};
use std::sync::Arc;

async fn open_store() -> GraphStore {
    GraphStore::open(GraphStoreConfig {
        endpoint: "memory".into(),
        namespace: "test".into(),
        database: "graph".into(),
        embedder: Arc::new(HashEmbedder),
    })
    .await
    .expect("store opens and applies schema")
}

/// Ingest → hybrid search returns the ingested memory ranked first for its own text.
#[tokio::test]
async fn ingest_then_search_finds_the_memory() {
    let store = open_store().await;
    let id = store
        .memory_ingest(MemoryRecord {
            id: None,
            text: "the octopus is a highly intelligent cephalopod".into(),
            kind: "note".into(),
            entity: None,
        })
        .await
        .expect("ingest succeeds");
    assert!(!id.is_empty());

    let hits = store
        .memory_search("octopus intelligent cephalopod", 5)
        .await
        .expect("search succeeds");
    assert!(!hits.is_empty(), "expected at least one hit");
    assert!(
        hits[0].text.contains("octopus"),
        "top hit should be the ingested memory, got {:?}",
        hits[0].text
    );
}

/// BM25 lexical lane finds an exact-term match even when semantics are thin.
#[tokio::test]
async fn lexical_lane_matches_rare_term() {
    let store = open_store().await;
    for text in [
        "quarterly revenue grew in the fiscal report",
        "the platypus lays eggs despite being a mammal",
    ] {
        store
            .memory_ingest(MemoryRecord {
                id: None,
                text: text.into(),
                kind: "note".into(),
                entity: None,
            })
            .await
            .expect("ingest");
    }
    let hits = store.memory_search("platypus", 5).await.expect("search");
    assert!(
        hits.iter().any(|h| h.text.contains("platypus")),
        "BM25 lane should surface the platypus memory"
    );
}

/// Empty inputs are rejected at the boundary (terminal, not a silent empty result).
#[tokio::test]
async fn empty_inputs_are_rejected() {
    let store = open_store().await;
    assert!(store
        .memory_ingest(MemoryRecord {
            id: None,
            text: "   ".into(),
            kind: "note".into(),
            entity: None,
        })
        .await
        .is_err());
    assert!(store.memory_search("", 5).await.is_err());
    // depth 0 is a caller error, not an empty traversal.
    assert!(store.graph_expand("entity:anything", 0).await.is_err());
}

/// RELATE edges are traversed and fused by graph_expand, nearer hops ranking higher.
#[tokio::test]
async fn graph_expand_traverses_relate_edges() {
    let store = open_store().await;
    // Seed a small graph: a -> b -> c, plus a -> d directly.
    for (id, label) in [("a", "Alpha"), ("b", "Beta"), ("c", "Gamma"), ("d", "Delta")] {
        store.create_entity(id, "node", label).await.expect("create entity");
    }
    for (from, to) in [("a", "b"), ("b", "c"), ("a", "d")] {
        store.relate(from, to, "related").await.expect("relate");
    }
    let related = store
        .graph_expand("a", 2)
        .await
        .expect("graph_expand succeeds");
    let ids: Vec<&str> = related.iter().map(|r| r.id.as_str()).collect();
    assert!(ids.contains(&"b"), "1-hop neighbour b should be present: {ids:?}");
    assert!(ids.contains(&"d"), "1-hop neighbour d should be present: {ids:?}");
    assert!(ids.contains(&"c"), "2-hop neighbour c should be present: {ids:?}");
    // b (1 hop) must outrank c (2 hops) under RRF.
    let rank = |want: &str| related.iter().position(|r| r.id == want).unwrap();
    assert!(rank("b") < rank("c"), "nearer hop b should outrank farther hop c");
}
RUST

  cat > "$d/tests/it/fake_embedder.rs" << 'RUST'
// TJ-ARCH-MOB-001 compliant
//! Deterministic, network-free embedder for boundary tests. Hashes each token into
//! a 384-dim bag-of-words vector and L2-normalises it, so texts that share words
//! land near each other under cosine distance — enough to exercise the HNSW lane
//! without an ONNX model.
use gen_ui_db_graph::{Embedder, EmbeddingModelInfo, EMBED_DIM};

pub struct HashEmbedder;

impl Embedder for HashEmbedder {
    fn model_info(&self) -> EmbeddingModelInfo {
        EmbeddingModelInfo { name: "test-hash".into(), dim: EMBED_DIM }
    }

    fn embed(&self, texts: &[String]) -> Result<Vec<Vec<f32>>, gen_ui_db_graph::GraphError> {
        Ok(texts.iter().map(|t| embed_one(t)).collect())
    }
}

fn embed_one(text: &str) -> Vec<f32> {
    let mut v = vec![0.0f32; EMBED_DIM];
    for token in text.to_lowercase().split_whitespace() {
        let mut h: u64 = 1469598103934665603; // FNV-1a offset basis
        for b in token.bytes() {
            h ^= b as u64;
            h = h.wrapping_mul(1099511628211);
        }
        v[(h as usize) % EMBED_DIM] += 1.0;
    }
    let norm = v.iter().map(|x| x * x).sum::<f32>().sqrt();
    if norm > 0.0 {
        for x in &mut v {
            *x /= norm;
        }
    }
    v
}
RUST

  ok "gen_ui_db_graph: SurrealDB 3.2 hybrid graph-RAG (HNSW+BM25+RRF, intent API)"
}

emit_crate gen_ui_mcp ""
emit_flint_mcp

# ── L2 gen_ui_client — Anthropic + Flint (gate/forge/FRF) (C-006) ────────────
emit_crate gen_ui_client ""
emit_flint_client

# ── gen_ui_db (L2) — UNIFIED emitter: C-003 relational + C-005 sync ───────────
# Two parallel worktree lanes each rewrote this crate from the same base. This
# integrator composes both into ONE crate:
#   relational → C-003 (sqlx pg/sqlite + migrations + typestate startup orchestrator)
#   sync       → C-005 (Electric shape consumer + DIY write queue + SyncTransport)
# Graph RAG stays in its own crate (gen_ui_db_graph, C-004). Every heredoc body is
# preserved verbatim from the lane that authored and verified it.
emit_gen_ui_db() {
  local dir="$OUT/crates/gen_ui_db"

  # ── Unioned Cargo.toml ──────────────────────────────────────────────────────
  # Shared deps (both lanes): gen_ui_types/gen_ui_runtime paths + async-trait,
  # serde, serde_json, tracing. C-003 adds anyhow/thiserror/sqlx/refinery/reqwest +
  # the sqlite-vec/pglite-oxide optional stack and the pg/sqlite/pglite features.
  # C-005 adds futures + a native-only (cfg(not(wasm32))) tokio/tokio-stream block;
  # its reqwest need is already covered by C-003's unconditional reqwest, so the
  # target block carries only tokio + tokio-stream (reqwest dedup'd).
  cat >> "$dir/Cargo.toml" << 'EOF'
gen_ui_types   = { path = "../gen_ui_types" }
gen_ui_runtime = { path = "../gen_ui_runtime" }
async-trait.workspace = true
anyhow.workspace      = true
serde.workspace       = true
serde_json.workspace  = true
thiserror.workspace   = true
futures.workspace     = true
tracing.workspace     = true
sqlx.workspace        = true
refinery.workspace    = true
reqwest.workspace     = true
sqlite-vec = { workspace = true, optional = true }
libsqlite3-sys = { workspace = true, optional = true }
pglite-oxide = { workspace = true, optional = true }
virtual-net = { workspace = true, optional = true }

[features]
default = []
pg = ["sqlx/postgres"]
sqlite = ["sqlx/sqlite", "dep:sqlite-vec", "dep:libsqlite3-sys"]
pglite = ["pg", "dep:pglite-oxide", "dep:virtual-net"]

[target.'cfg(not(target_arch = "wasm32"))'.dependencies]
tokio        = { workspace = true, features = ["rt", "sync", "time", "macros"] }
tokio-stream = { workspace = true }

[dev-dependencies]
tempfile = "3"
tokio = { workspace = true, features = ["macros", "rt"] }
EOF

  mkdir -p "$dir/src/relational" \
    "$dir/src/sync" \
    "$dir/migrations/postgres" \
    "$dir/migrations/sqlite" \
    "$dir/tests"

  # ── lib.rs — both module trees (C-005 doc comment, both `pub mod`s) ──────────
  cat > "$dir/src/lib.rs" << EOF
$MARK
//! gen_ui_db (L2) — relational (pg/sqlite) + sync + startup orchestrator.
//! Graph RAG lives in the sibling gen_ui_db_graph crate (C-004).
//! Trait seams (EntityTransport / SyncTransport) are defined in gen_ui_types.
//!
//! Module ownership (parallel worktree lanes, see plan.md):
//!   relational  → C-003 (sqlx pg/sqlite + migrations + typestate startup)
//!   sync        → C-005 (Electric shape consumer + DIY write queue)
//!
//! The sync engine writes read-path rows into a \`sync::LocalStore\` and flushes the
//! local write queue through a \`sync::WriteSink\` (forge Quarry API). Both are trait
//! seams so C-003's concrete store and C-006's forge client wire in without sync
//! depending on their crates — and a future prometheus-entity-sync (PES / PSyncV1)
//! client can replace the whole engine behind the same \`SyncTransport\` seam.

pub mod relational;
pub mod sync;
EOF

  # ══════════════════════════════════════════════════════════════════════════════
  # C-003 relational modules (verbatim) — src/relational/*.rs + migrations/
  # ══════════════════════════════════════════════════════════════════════════════
  cat > "$dir/src/relational/mod.rs" << EOF
$MARK
//! Feature-gated relational storage and ordered application startup.
//! Enable exactly one of \`pg\` or \`sqlite\`; add \`pglite\` for embedded desktop PG.

mod error;
mod seed;
mod startup;

#[cfg(feature = "pg")]
mod postgres;
#[cfg(feature = "sqlite")]
mod sqlite;

pub use error::{RelationalError, RelationalResult};
#[cfg(feature = "pglite")]
pub use postgres::PgliteStore;
#[cfg(feature = "pg")]
pub use postgres::PostgresStore;
pub use seed::{SeedBundle, SeedSource};
#[cfg(feature = "sqlite")]
pub use sqlite::SqliteStore;
pub use startup::{Migrated, Ready, Startup, Uninitialized};

#[cfg(all(feature = "pg", feature = "sqlite"))]
compile_error!("gen_ui_db relational dialect features are mutually exclusive");
EOF
  cat > "$dir/src/relational/error.rs" << EOF
$MARK
//! Typed errors for the relational library boundary.

#[derive(Debug, thiserror::Error)]
pub enum RelationalError {
    #[error("database operation failed: {0}")]
    Database(#[from] sqlx::Error),
    #[error("migration failed: {0}")]
    Migration(#[from] sqlx::migrate::MigrateError),
    #[error("seed bundle {name} could not be fetched: {source}")]
    SeedFetch { name: String, source: reqwest::Error },
    #[error("seed bundle {name} has invalid UTF-8: {source}")]
    SeedEncoding { name: String, source: std::str::Utf8Error },
    #[error("seed bundle {name} has an empty IPFS CID")]
    EmptyCid { name: String },
    #[error("sync attach failed: {0}")]
    Sync(String),
    #[cfg(feature = "pglite")]
    #[error("embedded PGlite server failed: {0}")]
    PgliteServer(#[from] anyhow::Error),
}

pub type RelationalResult<T> = Result<T, RelationalError>;
EOF
  cat > "$dir/src/relational/seed.rs" << EOF
$MARK
//! Versioned seed/lookup bundles. Network retrieval stays in the shared Rust core.

use super::{RelationalError, RelationalResult};

#[derive(Debug, Clone)]
pub enum SeedSource {
    Bundled(&'static str),
    Http { url: String },
    Ipfs { cid: String, gateway: String },
}

#[derive(Debug, Clone)]
pub struct SeedBundle {
    pub name: String,
    pub version: u32,
    pub source: SeedSource,
}

impl SeedBundle {
    pub async fn sql(&self, client: &reqwest::Client) -> RelationalResult<String> {
        match &self.source {
            SeedSource::Bundled(sql) => Ok((*sql).to_owned()),
            SeedSource::Http { url } => self.fetch(client, url).await,
            SeedSource::Ipfs { cid, gateway } => {
                if cid.trim().is_empty() {
                    return Err(RelationalError::EmptyCid { name: self.name.clone() });
                }
                let url = format!("{}/{cid}", gateway.trim_end_matches('/'));
                self.fetch(client, &url).await
            }
        }
    }

    async fn fetch(&self, client: &reqwest::Client, url: &str) -> RelationalResult<String> {
        let bytes = client
            .get(url)
            .header(reqwest::header::IF_NONE_MATCH, format!("\"{}-{}\"", self.name, self.version))
            .send()
            .await
            .and_then(reqwest::Response::error_for_status)
            .map_err(|source| RelationalError::SeedFetch { name: self.name.clone(), source })?
            .bytes()
            .await
            .map_err(|source| RelationalError::SeedFetch { name: self.name.clone(), source })?;
        std::str::from_utf8(&bytes)
            .map(str::to_owned)
            .map_err(|source| RelationalError::SeedEncoding { name: self.name.clone(), source })
    }
}
EOF
  cat > "$dir/src/relational/startup.rs" << EOF
$MARK
//! Typestate startup orchestration: migrations -> seeds -> sync attach.

use std::{marker::PhantomData, sync::Arc};

use gen_ui_types::sync::SyncTransport;

use super::{RelationalResult, SeedBundle};

pub struct Uninitialized;
pub struct Migrated;
pub struct Ready;

#[async_trait::async_trait]
pub trait StartupStore: Send + Sync {
    async fn migrate(&self) -> RelationalResult<()>;
    async fn execute_seed(&self, sql: &str) -> RelationalResult<()>;
}

pub struct Startup<S, State> {
    store: S,
    http: reqwest::Client,
    _state: PhantomData<State>,
}

impl<S> Startup<S, Uninitialized>
where
    S: StartupStore,
{
    pub fn new(store: S) -> Self {
        Self { store, http: reqwest::Client::new(), _state: PhantomData }
    }

    pub async fn migrate(self) -> RelationalResult<Startup<S, Migrated>> {
        self.store.migrate().await?;
        Ok(Startup { store: self.store, http: self.http, _state: PhantomData })
    }
}

impl<S> Startup<S, Migrated>
where
    S: StartupStore,
{
    pub async fn seed_and_attach(
        self,
        bundles: &[SeedBundle],
        sync: Arc<dyn SyncTransport>,
    ) -> RelationalResult<Startup<S, Ready>> {
        for bundle in bundles {
            let sql = bundle.sql(&self.http).await?;
            self.store.execute_seed(&sql).await?;
        }
        sync.start().await.map_err(|error| super::RelationalError::Sync(error.to_string()))?;
        Ok(Startup { store: self.store, http: self.http, _state: PhantomData })
    }
}

impl<S> Startup<S, Ready> {
    pub fn into_store(self) -> S { self.store }
}
EOF
  cat > "$dir/src/relational/postgres.rs" << EOF
$MARK
//! PostgreSQL store for cloud Postgres and pglite-oxide's local wire server.

// \`Path\` is only used by the pglite embedded-server constructor below; gating the
// import keeps a plain \`pg\` build (no \`pglite\`) warning-free under the clippy gate.
#[cfg(feature = "pglite")]
use std::path::Path;

use sqlx::{PgPool, postgres::PgPoolOptions};

use super::{RelationalResult, startup::StartupStore};

static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("./migrations/postgres");

#[derive(Clone)]
pub struct PostgresStore { pool: PgPool }

impl PostgresStore {
    pub async fn connect(url: &str) -> RelationalResult<Self> {
        let pool = PgPoolOptions::new().max_connections(5).connect(url).await?;
        Ok(Self { pool })
    }

    pub fn pool(&self) -> &PgPool { &self.pool }
}

#[async_trait::async_trait]
impl StartupStore for PostgresStore {
    async fn migrate(&self) -> RelationalResult<()> { MIGRATOR.run(&self.pool).await.map_err(Into::into) }
    async fn execute_seed(&self, sql: &str) -> RelationalResult<()> {
        sqlx::raw_sql(sql).execute(&self.pool).await?;
        Ok(())
    }
}

#[cfg(feature = "pglite")]
pub struct PgliteStore {
    store: PostgresStore,
    _server: pglite_oxide::PgliteServer,
}

#[cfg(feature = "pglite")]
impl PgliteStore {
    pub async fn open(path: impl AsRef<Path>) -> RelationalResult<Self> {
        let server = pglite_oxide::PgliteServer::builder().path(path.as_ref()).start()?;
        let url = server.database_url();
        let store = PostgresStore::connect(&url).await?;
        Ok(Self { store, _server: server })
    }

    pub fn store(&self) -> &PostgresStore { &self.store }
}
EOF
  cat > "$dir/src/relational/sqlite.rs" << EOF
$MARK
//! Mobile SQLite store. sqlite-vec is registered before any SQLx connection opens.

use std::{path::Path, str::FromStr, sync::Once};

use sqlx::{SqlitePool, sqlite::{SqliteConnectOptions, SqlitePoolOptions}};

use super::{RelationalResult, startup::StartupStore};

static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("./migrations/sqlite");
static REGISTER_VEC: Once = Once::new();

#[derive(Clone)]
pub struct SqliteStore { pool: SqlitePool }

impl SqliteStore {
    pub async fn open(path: impl AsRef<Path>) -> RelationalResult<Self> {
        REGISTER_VEC.call_once(|| {
            // SAFETY: sqlite-vec exposes SQLite's documented extension entry point.
            // Register it once, before SQLx opens any connection; both crates link
            // the same libsqlite3-sys version through Cargo feature unification.
            unsafe {
                libsqlite3_sys::sqlite3_auto_extension(Some(std::mem::transmute::<
                    *const (),
                    unsafe extern "C" fn(
                        *mut libsqlite3_sys::sqlite3,
                        *mut *mut std::ffi::c_char,
                        *const libsqlite3_sys::sqlite3_api_routines,
                    ) -> std::ffi::c_int,
                >(
                    sqlite_vec::sqlite3_vec_init as *const (),
                )));
            }
        });
        let options = SqliteConnectOptions::from_str(&format!("sqlite://{}", path.as_ref().display()))?
            .create_if_missing(true)
            .foreign_keys(true);
        let pool = SqlitePoolOptions::new().max_connections(1).connect_with(options).await?;
        Ok(Self { pool })
    }

    pub fn pool(&self) -> &SqlitePool { &self.pool }
}

#[async_trait::async_trait]
impl StartupStore for SqliteStore {
    async fn migrate(&self) -> RelationalResult<()> { MIGRATOR.run(&self.pool).await.map_err(Into::into) }
    async fn execute_seed(&self, sql: &str) -> RelationalResult<()> {
        sqlx::raw_sql(sql).execute(&self.pool).await?;
        Ok(())
    }
}
EOF
  cat > "$dir/migrations/postgres/0001_relational.sql" << 'EOF'
-- TJ-ARCH-MOB-001 compliant
CREATE TABLE IF NOT EXISTS app_seed_versions (
    name TEXT PRIMARY KEY,
    version BIGINT NOT NULL CHECK (version >= 0),
    applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
EOF
  cat > "$dir/migrations/sqlite/0001_relational.sql" << 'EOF'
-- TJ-ARCH-MOB-001 compliant
CREATE TABLE IF NOT EXISTS app_seed_versions (
    name TEXT PRIMARY KEY,
    version INTEGER NOT NULL CHECK (version >= 0),
    applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
) STRICT;
EOF

  # ══════════════════════════════════════════════════════════════════════════════
  # C-005 sync modules (verbatim) — src/sync/*.rs + README
  # ══════════════════════════════════════════════════════════════════════════════
  # ── sync/mod.rs — engine assembly + public re-exports ──────────────────────
  cat > "$dir/src/sync/mod.rs" << EOF
$MARK
//! Local-first sync engine (C-005).
//!
//! Native path (desktop/mobile): a Rust Electric **shape consumer** long-polls the
//! Electric HTTP API and writes rows into a [\`LocalStore\`]; a DIY **write queue**
//! replays local mutations through a [\`WriteSink\`] (forge Quarry API) with idempotent
//! keys, exponential backoff, and a poison handler. A [\`SyncStatus\`] broadcast drives
//! the UI sync chip.
//!
//! Web path: the browser uses \`@electric-sql/pglite-sync\` (JS side) — see
//! \`sync/README.md\`. This module compiles to a documented no-op on \`wasm32\` so the
//! workspace still builds for the browser leaf.
//!
//! Everything sits behind the frozen [\`gen_ui_types::sync::SyncTransport\`] seam, so
//! PES (PSyncV1) can replace the engine later without touching callers.

mod status;

#[cfg(not(target_arch = "wasm32"))]
mod config;
#[cfg(not(target_arch = "wasm32"))]
mod seam;
#[cfg(not(target_arch = "wasm32"))]
mod shapes;
#[cfg(not(target_arch = "wasm32"))]
mod write_queue;
#[cfg(not(target_arch = "wasm32"))]
mod engine;

pub use status::{SyncStatusHandle, SyncStatusStream};
// Re-export the frozen seam types so callers use one import path.
pub use gen_ui_types::sync::{SyncStatus, SyncTransport};

#[cfg(not(target_arch = "wasm32"))]
pub use config::{ShapeSpec, SyncConfig};
#[cfg(not(target_arch = "wasm32"))]
pub use engine::SyncEngine;
#[cfg(not(target_arch = "wasm32"))]
pub use seam::{LocalStore, PendingWrite, RowChange, RowOp, WriteOutcome, WriteSink};

/// wasm32 stub. The browser sync path is \`pglite-sync\` (JS); no Rust engine runs
/// in-browser. Kept so \`cargo check --target wasm32-unknown-unknown -p gen_ui_wasm\`
/// stays green and callers get a clear compile error if they try to build the
/// native engine for the web.
#[cfg(target_arch = "wasm32")]
pub mod web_note {
    //! Browser sync is configured JS-side via \`@electric-sql/pglite-sync\`.
    //! See \`crates/gen_ui_db/src/sync/README.md\`.
}
EOF

  # ── sync/README.md — the web (pglite-sync) configuration, JS side ──────────
  cat > "$dir/src/sync/README.md" << 'EOF'
# gen_ui_db::sync — read-path + write-path local-first sync (C-005)

Native (desktop/mobile) uses the Rust engine in this module. Web uses
`@electric-sql/pglite-sync` on the JS side — the Rust engine is compiled out on
`wasm32` (see `mod.rs`).

## Web path — `@electric-sql/pglite-sync` (JS)

The browser holds a PGlite database and subscribes to the same Electric shapes the
Rust consumer reads. Configure it in the web app (NOT in Rust):

```ts
import { PGlite } from '@electric-sql/pglite'
import { electricSync } from '@electric-sql/pglite-sync'

const pg = await PGlite.create({
  dataDir: 'idb://gen-ui',        // relaxedDurability + multi-tab worker per analysis §2
  extensions: { electric: electricSync() },
})

// One syncShapeToTable per synced table. Table/columns MUST already exist
// (boot order invariant: migrations → seeds → shapes attach).
const sub = await pg.electric.syncShapeToTable({
  shape: { url: `${ELECTRIC_URL}/v1/shape`, params: { table: 'entities' } },
  table: 'entities',
  primaryKey: ['id'],
  shapeKey: 'entities',           // persisted so a reload resumes from the stored offset
})

// Writes go through the app API (forge Quarry), never straight to Electric —
// Electric is read-path only. Mirror the Rust write-queue contract:
//   idempotent key per mutation, retry with backoff, surface poison to the UI.
```

Keep the web shape list identical to `SyncConfig::shapes` on native so both surfaces
converge on the same rows. The write-path API (forge Quarry) and its idempotency
contract are shared across surfaces.
EOF

  # ── sync/config.rs — engine configuration ─────────────────────────────────
  cat > "$dir/src/sync/config.rs" << EOF
$MARK
//! Sync engine configuration. Pure data; no IO.

/// One Electric shape to consume. Kept minimal — the shape \`where\`/\`columns\`
/// filters that enforce tenant RLS at the shape factory are added when C-006 wires
/// the authenticated Electric URL. Keep this list identical to the web app's
/// \`pglite-sync\` shape list so both surfaces converge on the same rows.
#[derive(Debug, Clone)]
pub struct ShapeSpec {
    /// Local table the shape rows are written into (must exist before attach).
    pub table: String,
    /// Optional Postgres \`where\` filter forwarded to the shape factory.
    pub where_clause: Option<String>,
}

impl ShapeSpec {
    pub fn new(table: impl Into<String>) -> Self {
        Self { table: table.into(), where_clause: None }
    }

    #[must_use]
    pub fn with_where(mut self, clause: impl Into<String>) -> Self {
        self.where_clause = Some(clause.into());
        self
    }
}

/// Full sync configuration.
#[derive(Debug, Clone)]
pub struct SyncConfig {
    /// Base URL of the Electric HTTP API (e.g. \`https://gate.example/electric\`).
    /// Through flint-gate this is the tenant-scoped, authenticated shape endpoint.
    pub electric_url: String,
    /// Shapes to consume on the read path.
    pub shapes: Vec<ShapeSpec>,
    /// Max local writes to flush per drain pass before yielding.
    pub write_batch: usize,
    /// After this many failed replays a write is quarantined (poison handler).
    pub max_write_attempts: u32,
}

impl SyncConfig {
    pub fn new(electric_url: impl Into<String>) -> Self {
        Self {
            electric_url: electric_url.into(),
            shapes: Vec::new(),
            write_batch: 64,
            max_write_attempts: 8,
        }
    }

    #[must_use]
    pub fn with_shape(mut self, shape: ShapeSpec) -> Self {
        self.shapes.push(shape);
        self
    }
}
EOF

  # ── sync/seam.rs — LocalStore / WriteSink trait seams (PES-compatible) ─────
  cat > "$dir/src/sync/seam.rs" << EOF
$MARK
//! Seams the sync engine writes through — so it depends on neither the concrete
//! relational store (C-003) nor the forge client (C-006), and PES can reuse them.
use async_trait::async_trait;
use gen_ui_types::error::CoreResult;
use serde::{Deserialize, Serialize};

/// A single row change decoded from an Electric shape message.
#[derive(Debug, Clone, PartialEq)]
pub struct RowChange {
    pub table: String,
    pub op: RowOp,
    /// Primary-key value(s) as JSON (the shape's \`key\`).
    pub key: String,
    /// Full row value as a JSON object (empty for deletes).
    pub value_json: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RowOp {
    Insert,
    Update,
    Delete,
}

/// Read-path sink: the shape consumer applies decoded rows here. C-003's sqlx store
/// implements this against SQLite (mobile) / pglite-oxide (desktop). A single
/// \`apply_batch\` per transaction keeps the local DB consistent with a shape
/// message boundary.
#[async_trait]
pub trait LocalStore: Send + Sync {
    /// Apply a batch of row changes atomically (one local transaction).
    async fn apply_batch(&self, changes: &[RowChange]) -> CoreResult<()>;

    /// Wipe a table's synced rows — used on \`must-refetch\` (shape rotation) so the
    /// consumer can re-materialise the shape from offset \`-1\` without duplicates.
    async fn truncate_shape(&self, table: &str) -> CoreResult<()>;
}

/// One durable, idempotent local mutation awaiting replay to the server.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PendingWrite {
    /// Idempotency key — the server dedupes retries on this. Stable across replays.
    pub idempotency_key: String,
    /// Target table / entity type.
    pub table: String,
    /// The mutation as JSON (op + payload); opaque to the queue, meaningful to the sink.
    pub change_json: String,
    /// How many replay attempts have already failed.
    pub attempts: u32,
}

/// The result of attempting to replay one write through the server.
#[derive(Debug, Clone, PartialEq)]
pub enum WriteOutcome {
    /// Server accepted (or idempotently deduped) the write — drop it from the queue.
    Applied,
    /// Transient failure (network / 5xx / conflict-retryable) — keep and back off.
    Retry,
    /// Terminal rejection (4xx validation) — quarantine as poison, stop retrying.
    Poison { reason: String },
}

/// Write-path sink: the queue flushes pending writes here. C-006's forge client
/// implements this against the Quarry REST/GraphQL API under RLS. The impl MUST
/// forward \`idempotency_key\` so server-side dedup makes replay safe.
#[async_trait]
pub trait WriteSink: Send + Sync {
    async fn send(&self, write: &PendingWrite) -> WriteOutcome;
}
EOF

  # ── sync/status.rs — SyncStatus broadcast for the UI chip ──────────────────
  cat > "$dir/src/sync/status.rs" << EOF
$MARK
//! [\`SyncStatus\`] broadcast — the UI sync chip subscribes to this stream.
use gen_ui_types::sync::SyncStatus;

#[cfg(not(target_arch = "wasm32"))]
mod imp {
    use super::SyncStatus;
    use std::sync::{
        atomic::{AtomicU32, Ordering},
        Arc,
    };
    use tokio::sync::watch;

    /// Publishes [\`SyncStatus\`] transitions. Cheap to clone (\`Arc\`-backed). A
    /// \`watch\` channel (not \`broadcast\`) because status is last-value-wins: a late
    /// subscriber wants the current state, not a replay of every past transition.
    #[derive(Clone)]
    pub struct SyncStatusHandle {
        tx: Arc<watch::Sender<SyncStatus>>,
        pending: Arc<AtomicU32>,
    }

    /// A live subscription to status transitions (\`watch::Receiver\`).
    pub type SyncStatusStream = watch::Receiver<SyncStatus>;

    impl SyncStatusHandle {
        pub fn new() -> Self {
            let (tx, _rx) = watch::channel(SyncStatus::Offline);
            Self { tx: Arc::new(tx), pending: Arc::new(AtomicU32::new(0)) }
        }

        /// Subscribe to status transitions (drives one UI chip).
        pub fn subscribe(&self) -> SyncStatusStream {
            self.tx.subscribe()
        }

        /// Current status snapshot.
        pub fn current(&self) -> SyncStatus {
            self.tx.borrow().clone()
        }

        pub(crate) fn set(&self, status: SyncStatus) {
            // send_replace ignores the "no receivers" error — status is still
            // readable via \`borrow\`/\`current\` even with nobody subscribed.
            let _ = self.tx.send_replace(status);
        }

        pub(crate) fn set_pending(&self, n: u32) {
            self.pending.store(n, Ordering::Relaxed);
            if n > 0 {
                self.set(SyncStatus::Syncing { pending_writes: n });
            }
        }

        pub(crate) fn pending(&self) -> u32 {
            self.pending.load(Ordering::Relaxed)
        }
    }

    impl Default for SyncStatusHandle {
        fn default() -> Self {
            Self::new()
        }
    }
}

#[cfg(target_arch = "wasm32")]
mod imp {
    use super::SyncStatus;
    use std::{cell::RefCell, rc::Rc};

    /// wasm stub — browser sync status comes from the JS \`pglite-sync\` subscription,
    /// surfaced to the UI on that side. Kept so the type name resolves on wasm32.
    /// (No \`#[derive(Default)]\`: \`SyncStatus\` is a frozen seam with no \`Default\`.)
    #[derive(Clone)]
    pub struct SyncStatusHandle(Rc<RefCell<SyncStatus>>);

    /// No stream on wasm (the JS side owns status). Alias keeps signatures uniform.
    pub type SyncStatusStream = ();

    impl SyncStatusHandle {
        pub fn new() -> Self {
            Self(Rc::new(RefCell::new(SyncStatus::Offline)))
        }
        pub fn subscribe(&self) -> SyncStatusStream {}
        pub fn current(&self) -> SyncStatus {
            self.0.borrow().clone()
        }
    }

    impl Default for SyncStatusHandle {
        fn default() -> Self {
            Self::new()
        }
    }
}

pub use imp::{SyncStatusHandle, SyncStatusStream};
EOF

  # ── sync/shapes.rs — Electric HTTP shape consumer ──────────────────────────
  cat > "$dir/src/sync/shapes.rs" << EOF
$MARK
//! Electric HTTP shape consumer. Long-polls the Electric \`/v1/shape\` endpoint,
//! tracks \`(handle, offset)\`, and applies decoded rows to a [\`LocalStore\`].
//!
//! Wire protocol (Electric v1.x): the initial request uses \`offset=-1\`; responses
//! carry \`electric-handle\` + \`electric-offset\` headers and a JSON array of change
//! messages (\`{ headers.operation, key, value }\`) interleaved with control
//! messages (\`{ headers.control: "up-to-date" | "must-refetch" }\`). Subsequent
//! requests add \`handle=<h>&offset=<o>&live=true\` to long-poll. A \`must-refetch\`
//! control message (or HTTP 409) means the shape rotated: truncate locally and
//! restart from \`offset=-1\` with the fresh handle.
use super::config::ShapeSpec;
use super::seam::{LocalStore, RowChange, RowOp};
use super::status::SyncStatusHandle;
use gen_ui_types::error::{CoreError, CoreResult};
use gen_ui_types::sync::SyncStatus;
use serde::Deserialize;
use std::sync::Arc;

/// A shape message: either a row operation or a control frame.
#[derive(Debug, Deserialize)]
struct ShapeMessage {
    #[serde(default)]
    headers: MsgHeaders,
    #[serde(default)]
    key: Option<String>,
    #[serde(default)]
    value: Option<serde_json::Value>,
}

#[derive(Debug, Default, Deserialize)]
struct MsgHeaders {
    #[serde(default)]
    operation: Option<String>,
    #[serde(default)]
    control: Option<String>,
}

/// Tracks position within one shape's log.
struct ShapeCursor {
    handle: Option<String>,
    offset: String,
}

impl ShapeCursor {
    /// Fresh cursor — Electric's initial-sync sentinel offset is \`-1\`.
    fn initial() -> Self {
        Self { handle: None, offset: "-1".to_string() }
    }
}

pub(crate) struct ShapeConsumer {
    client: reqwest::Client,
    electric_url: String,
    shape: ShapeSpec,
    store: Arc<dyn LocalStore>,
    status: SyncStatusHandle,
}

impl ShapeConsumer {
    pub(crate) fn new(
        client: reqwest::Client,
        electric_url: String,
        shape: ShapeSpec,
        store: Arc<dyn LocalStore>,
        status: SyncStatusHandle,
    ) -> Self {
        Self { client, electric_url, shape, store, status }
    }

    /// Consume the shape until the task is cancelled (drop of the join handle) or a
    /// terminal error. Loops: catch up → long-poll live → apply → repeat, handling
    /// \`must-refetch\` by truncating and resetting the cursor.
    pub(crate) async fn run(&self) -> CoreResult<()> {
        let mut cursor = ShapeCursor::initial();
        loop {
            let live = cursor.handle.is_some(); // only long-poll once we have a handle
            let (messages, next) = self.poll(&cursor, live).await?;

            let mut changes = Vec::new();
            let mut must_refetch = false;
            for msg in &messages {
                if let Some(control) = &msg.headers.control {
                    match control.as_str() {
                        "up-to-date" => self.status.set(SyncStatus::Live),
                        "must-refetch" => {
                            must_refetch = true;
                            break;
                        }
                        _ => {} // unknown control frame — ignore forward-compatibly
                    }
                    continue;
                }
                if let Some(change) = decode_row(&self.shape.table, msg) {
                    changes.push(change);
                }
            }

            if must_refetch {
                tracing::warn!(table = %self.shape.table, "shape rotated; refetching");
                self.store.truncate_shape(&self.shape.table).await?;
                cursor = ShapeCursor::initial();
                continue;
            }

            if !changes.is_empty() {
                self.store.apply_batch(&changes).await?;
            }
            cursor = next;
        }
    }

    /// One HTTP request against the shape endpoint. Returns decoded messages and the
    /// advanced cursor. HTTP 409 is Electric's shape-rotation signal → surface it as
    /// an empty batch with a reset cursor so \`run\` re-materialises.
    async fn poll(
        &self,
        cursor: &ShapeCursor,
        live: bool,
    ) -> CoreResult<(Vec<ShapeMessage>, ShapeCursor)> {
        let mut req = self
            .client
            .get(format!("{}/v1/shape", self.electric_url))
            .query(&[("table", self.shape.table.as_str()), ("offset", cursor.offset.as_str())]);
        if let Some(handle) = &cursor.handle {
            req = req.query(&[("handle", handle.as_str())]);
        }
        if let Some(where_clause) = &self.shape.where_clause {
            req = req.query(&[("where", where_clause.as_str())]);
        }
        if live {
            req = req.query(&[("live", "true")]);
        }

        let resp = req.send().await.map_err(|e| CoreError::Transient(e.to_string()))?;

        // 409 = shape handle rotated: reset to initial and let run() refetch.
        if resp.status().as_u16() == 409 {
            return Ok((Vec::new(), ShapeCursor::initial()));
        }
        if !resp.status().is_success() {
            return Err(CoreError::Transient(format!("shape http {}", resp.status())));
        }

        let handle = header(&resp, "electric-handle").or_else(|| cursor.handle.clone());
        let offset = header(&resp, "electric-offset").unwrap_or_else(|| cursor.offset.clone());

        let body = resp.text().await.map_err(|e| CoreError::Transient(e.to_string()))?;
        // Empty body on a live long-poll timeout = no new data; keep the cursor.
        let messages: Vec<ShapeMessage> = if body.trim().is_empty() {
            Vec::new()
        } else {
            serde_json::from_str(&body).map_err(|e| CoreError::Serde(e.to_string()))?
        };

        Ok((messages, ShapeCursor { handle, offset }))
    }
}

fn header(resp: &reqwest::Response, name: &str) -> Option<String> {
    resp.headers().get(name).and_then(|v| v.to_str().ok()).map(str::to_string)
}

/// Decode one shape row message into a [\`RowChange\`]. Returns \`None\` for messages
/// without a usable operation (already filtered control frames upstream).
fn decode_row(table: &str, msg: &ShapeMessage) -> Option<RowChange> {
    let op = match msg.headers.operation.as_deref()? {
        "insert" => RowOp::Insert,
        "update" => RowOp::Update,
        "delete" => RowOp::Delete,
        _ => return None,
    };
    let key = msg.key.clone().unwrap_or_default();
    let value_json = msg
        .value
        .as_ref()
        .map(|v| v.to_string())
        .unwrap_or_else(|| "{}".to_string());
    Some(RowChange { table: table.to_string(), op, key, value_json })
}

#[cfg(test)]
mod tests {
    use super::*;

    // Boundary behavior: an Electric change message decodes to the right RowOp;
    // a control frame (no operation) decodes to None so run() skips it as a row.
    #[test]
    fn decodes_insert_and_skips_control_frames() {
        let insert: ShapeMessage = serde_json::from_str(
            r#"{"headers":{"operation":"insert"},"key":"\"e1\"","value":{"id":"e1"}}"#,
        )
        .expect("insert message parses");
        let row = decode_row("entities", &insert).expect("insert decodes to a row");
        assert_eq!(row.op, RowOp::Insert);
        assert_eq!(row.table, "entities");

        let up_to_date: ShapeMessage =
            serde_json::from_str(r#"{"headers":{"control":"up-to-date"}}"#)
                .expect("control message parses");
        assert!(decode_row("entities", &up_to_date).is_none());
    }
}
EOF

  # ── sync/write_queue.rs — DIY write queue (backoff + poison) ───────────────
  cat > "$dir/src/sync/write_queue.rs" << EOF
$MARK
//! DIY write queue: durable local action log replayed through a [\`WriteSink\`]
//! (forge Quarry API) with idempotent keys, exponential backoff, and a poison
//! handler. Read-path is Electric; this is the write-path half of local-first.
//!
//! The in-memory queue here is the replay engine; durability (survive restart) is
//! delegated to the same [\`LocalStore\`]-backed action-log table C-003 owns — this
//! module keeps the seam so persistence wires in without changing the replay logic.
use super::config::SyncConfig;
use super::seam::{PendingWrite, WriteOutcome, WriteSink};
use super::status::SyncStatusHandle;
use std::collections::VecDeque;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;

/// Backoff schedule for transient write failures (capped exponential).
const BACKOFF_BASE: Duration = Duration::from_millis(200);
const BACKOFF_MAX: Duration = Duration::from_secs(30);

fn backoff_for(attempt: u32) -> Duration {
    // 200ms, 400ms, 800ms, … capped at 30s. saturating shift avoids overflow panics.
    let factor = 1u64.checked_shl(attempt.min(20)).unwrap_or(u64::MAX);
    BACKOFF_BASE.saturating_mul(factor.min(u32::MAX as u64) as u32).min(BACKOFF_MAX)
}

pub(crate) struct WriteQueue {
    sink: Arc<dyn WriteSink>,
    status: SyncStatusHandle,
    max_attempts: u32,
    batch: usize,
    // tokio::Mutex: guard is held across the sink \`.await\`, so a std/parking_lot
    // mutex would be !Send here. Contention is low (one drain task + enqueues).
    pending: Mutex<VecDeque<PendingWrite>>,
    poison: Mutex<Vec<PendingWrite>>,
}

impl WriteQueue {
    pub(crate) fn new(cfg: &SyncConfig, sink: Arc<dyn WriteSink>, status: SyncStatusHandle) -> Self {
        Self {
            sink,
            status,
            max_attempts: cfg.max_write_attempts,
            batch: cfg.write_batch,
            pending: Mutex::new(VecDeque::new()),
            poison: Mutex::new(Vec::new()),
        }
    }

    /// Enqueue a local mutation for replay. Idempotency-keyed so retries dedupe
    /// server-side. Updates the pending-writes count that drives the UI chip.
    pub(crate) async fn enqueue(&self, write: PendingWrite) {
        let len = {
            let mut q = self.pending.lock().await;
            q.push_back(write);
            q.len() as u32
        };
        self.status.set_pending(len);
    }

    /// Drain up to \`batch\` writes, replaying each through the sink. Transient
    /// failures are re-queued (front) after a backoff sleep; poison writes are moved
    /// to the poison list and surfaced. Returns how many writes remain pending.
    pub(crate) async fn drain(&self) -> u32 {
        for _ in 0..self.batch {
            let Some(mut write) = ({ self.pending.lock().await.pop_front() }) else {
                break; // queue empty
            };

            match self.sink.send(&write).await {
                WriteOutcome::Applied => {
                    // dropped — the write succeeded (or idempotently deduped).
                }
                WriteOutcome::Retry => {
                    write.attempts += 1;
                    if write.attempts >= self.max_attempts {
                        self.quarantine(write, "max attempts exceeded").await;
                    } else {
                        let delay = backoff_for(write.attempts);
                        tracing::warn!(
                            key = %write.idempotency_key,
                            attempt = write.attempts,
                            ?delay,
                            "write retry scheduled"
                        );
                        tokio::time::sleep(delay).await;
                        self.pending.lock().await.push_front(write);
                    }
                }
                WriteOutcome::Poison { reason } => self.quarantine(write, &reason).await,
            }
        }

        let remaining = self.pending.lock().await.len() as u32;
        self.status.set_pending(remaining);
        remaining
    }

    async fn quarantine(&self, write: PendingWrite, reason: &str) {
        tracing::error!(
            key = %write.idempotency_key,
            table = %write.table,
            reason,
            "write quarantined (poison)"
        );
        self.poison.lock().await.push(write);
    }

    /// Snapshot of quarantined writes for UI surfacing / manual retry tooling.
    pub(crate) async fn poison_writes(&self) -> Vec<PendingWrite> {
        self.poison.lock().await.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Boundary behavior: backoff grows exponentially from the base and never
    // exceeds the cap, even at absurd attempt counts (no overflow panic).
    #[test]
    fn backoff_is_exponential_and_capped() {
        assert_eq!(backoff_for(0), BACKOFF_BASE);
        assert_eq!(backoff_for(1), BACKOFF_BASE * 2);
        assert_eq!(backoff_for(2), BACKOFF_BASE * 4);
        assert_eq!(backoff_for(1000), BACKOFF_MAX);
        assert!(backoff_for(50) <= BACKOFF_MAX);
    }
}
EOF

  # ── sync/engine.rs — SyncEngine wiring + SyncTransport impl ─────────────────
  cat > "$dir/src/sync/engine.rs" << EOF
$MARK
//! [\`SyncEngine\`] — assembles the shape consumers + write queue behind the frozen
//! [\`SyncTransport\`] seam.
use super::config::SyncConfig;
use super::seam::{LocalStore, PendingWrite, WriteSink};
use super::shapes::ShapeConsumer;
use super::status::SyncStatusHandle;
use super::write_queue::WriteQueue;
use async_trait::async_trait;
use gen_ui_types::error::{CoreError, CoreResult};
use gen_ui_types::sync::{SyncStatus, SyncTransport};
use std::sync::Arc;

/// The C-005 local-first sync engine. Construct with a [\`LocalStore\`] (read-path
/// sink, C-003) and a [\`WriteSink\`] (write-path, C-006 forge client), then drive it
/// through the [\`SyncTransport\`] seam.
pub struct SyncEngine {
    cfg: SyncConfig,
    client: reqwest::Client,
    store: Arc<dyn LocalStore>,
    queue: Arc<WriteQueue>,
    status: SyncStatusHandle,
}

impl SyncEngine {
    pub fn new(cfg: SyncConfig, store: Arc<dyn LocalStore>, sink: Arc<dyn WriteSink>) -> Self {
        let status = SyncStatusHandle::new();
        let queue = Arc::new(WriteQueue::new(&cfg, sink, status.clone()));
        Self { cfg, client: reqwest::Client::new(), store, queue, status }
    }

    /// Subscribe to [\`SyncStatus\`] transitions for the UI sync chip.
    pub fn status_stream(&self) -> super::status::SyncStatusStream {
        self.status.subscribe()
    }

    /// Quarantined (poison) writes — for UI surfacing and manual retry tooling.
    pub async fn poison_writes(&self) -> Vec<PendingWrite> {
        self.queue.poison_writes().await
    }
}

#[async_trait]
impl SyncTransport for SyncEngine {
    /// Start read-path sync: spawn one shape consumer per configured shape and a
    /// write-queue drain loop. Tasks run on the global runtime; they stop when the
    /// engine (and thus the \`Arc\`s they hold) is dropped.
    async fn start(&self) -> CoreResult<()> {
        if self.cfg.shapes.is_empty() {
            return Err(CoreError::Terminal("sync: no shapes configured".into()));
        }
        self.status.set(SyncStatus::Syncing { pending_writes: self.status.pending() });

        for shape in &self.cfg.shapes {
            let consumer = ShapeConsumer::new(
                self.client.clone(),
                self.cfg.electric_url.clone(),
                shape.clone(),
                Arc::clone(&self.store),
                self.status.clone(),
            );
            gen_ui_runtime::spawn(async move {
                if let Err(e) = consumer.run().await {
                    tracing::error!(error = %e, "shape consumer stopped");
                }
            });
        }

        // Write-queue drain loop: replay pending writes, idle-poll when empty.
        let queue = Arc::clone(&self.queue);
        gen_ui_runtime::spawn(async move {
            loop {
                let remaining = queue.drain().await;
                if remaining == 0 {
                    tokio::time::sleep(std::time::Duration::from_millis(250)).await;
                }
            }
        });

        Ok(())
    }

    /// Enqueue a local write for durable replay through the forge Quarry API.
    /// \`change_json\` carries the mutation; the idempotency key is derived from it so
    /// server-side dedup makes replay safe. The action-log persistence seam (C-003)
    /// makes this survive restarts.
    async fn enqueue_write(&self, change_json: &str) -> CoreResult<()> {
        let parsed: serde_json::Value =
            serde_json::from_str(change_json).map_err(|e| CoreError::Serde(e.to_string()))?;
        let table = parsed
            .get("table")
            .and_then(|v| v.as_str())
            .ok_or_else(|| CoreError::Terminal("write: missing \"table\"".into()))?
            .to_string();
        // Prefer a caller-supplied key; else derive a stable one from the payload.
        let idempotency_key = parsed
            .get("idempotency_key")
            .and_then(|v| v.as_str())
            .map(str::to_string)
            .unwrap_or_else(|| derive_key(change_json));

        self.queue
            .enqueue(PendingWrite { idempotency_key, table, change_json: change_json.to_string(), attempts: 0 })
            .await;
        Ok(())
    }

    fn status(&self) -> SyncStatus {
        self.status.current()
    }
}

/// Derive a stable idempotency key from a write payload (FNV-1a over the bytes).
/// Deterministic so an identical retried write dedupes server-side.
fn derive_key(payload: &str) -> String {
    let mut hash: u64 = 0xcbf2_9ce4_8422_2325;
    for b in payload.as_bytes() {
        hash ^= u64::from(*b);
        hash = hash.wrapping_mul(0x0000_0100_0000_01b3);
    }
    format!("wq-{hash:016x}")
}

#[cfg(test)]
mod tests {
    use super::*;

    // Boundary behavior: the same payload derives the same idempotency key (so a
    // retried write dedupes server-side) and different payloads diverge.
    #[test]
    fn derive_key_is_deterministic_and_distinct() {
        let a = r#"{"table":"entities","op":"upsert","id":"e1"}"#;
        let b = r#"{"table":"entities","op":"upsert","id":"e2"}"#;
        assert_eq!(derive_key(a), derive_key(a));
        assert_ne!(derive_key(a), derive_key(b));
        assert!(derive_key(a).starts_with("wq-"));
    }
}
EOF

  # ══════════════════════════════════════════════════════════════════════════════
  # Combined integration test binary (tests/it.rs) — C-003 relational boundary
  # tests. C-005's boundary tests live inline in its sync/*.rs #[cfg(test)] modules
  # (unit-adjacent, exercising private decode/backoff/key-derivation seams), so both
  # lanes' tests coexist: one integration binary + the inline sync module tests.
  # ══════════════════════════════════════════════════════════════════════════════
  cat > "$dir/tests/it.rs" << EOF
$MARK
//! Public-boundary behavior tests for relational startup inputs and SQLite+vec.

use gen_ui_db::relational::{RelationalError, SeedBundle, SeedSource};

#[tokio::test]
async fn bundled_seed_resolves_without_io() {
    let bundle = SeedBundle {
        name: "lookups".to_owned(),
        version: 1,
        source: SeedSource::Bundled("INSERT INTO lookup VALUES (1);"),
    };
    let sql = bundle.sql(&reqwest::Client::new()).await.unwrap();
    assert_eq!(sql, "INSERT INTO lookup VALUES (1);");
}

#[tokio::test]
async fn empty_ipfs_cid_is_rejected_before_network_io() {
    let bundle = SeedBundle {
        name: "lookups".to_owned(),
        version: 1,
        source: SeedSource::Ipfs { cid: " ".to_owned(), gateway: "https://ipfs.io/ipfs".to_owned() },
    };
    let error = bundle.sql(&reqwest::Client::new()).await.unwrap_err();
    assert!(matches!(error, RelationalError::EmptyCid { .. }));
}

#[cfg(feature = "sqlite")]
#[tokio::test]
async fn sqlite_store_loads_vec_extension() {
    use gen_ui_db::relational::SqliteStore;

    let directory = tempfile::tempdir().unwrap();
    let store = SqliteStore::open(directory.path().join("app.sqlite")).await.unwrap();
    let version: String = sqlx::query_scalar("SELECT vec_version()")
        .fetch_one(store.pool())
        .await
        .unwrap();
    assert!(version.starts_with('v'));
}
EOF

  ok "gen_ui_db: relational (pg/sqlite + migrations + startup) [C-003] + sync (Electric consumer + write queue + SyncTransport) [C-005]"
}

emit_crate gen_ui_db ""
emit_gen_ui_db
emit_crate gen_ui_inference ""
emit_l2_stub gen_ui_inference "candle GGUF engine (native accel; wasm feature-gated off)." "future inference lane"

# ── gen_ui_db_graph (C-004): SurrealDB 3.2 embedded hybrid graph-RAG ──────────
# Own crate (not a gen_ui_db submodule) on purpose: surrealdb-core's build.rs
# re-runs on every downstream touch (surrealdb#6954), so isolating it here keeps
# the rest of the workspace off SurrealDB's slow recompile path.
emit_graph_rag_crate

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
    && echo "  cargo metadata OK (13 crates)" \
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
echo "  Wave-1 lanes implement: gen_ui_db (C-003/004/005), leaves (C-007)"
echo "  C-006 DONE: gen_ui_client/flint (gate+forge+frf) + gen_ui_mcp (JSON-RPC/SSE)"
echo ""
echo "  ⚠ gen_ui_types trait seams are FROZEN after C-001 review — changes need cross-lane sign-off."
