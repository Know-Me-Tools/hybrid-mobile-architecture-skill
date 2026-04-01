#!/usr/bin/env bash
# scripts/scaffold-rust-core.sh
# Scaffold the gen_ui_core shared Rust crate
# Usage: bash scripts/scaffold-rust-core.sh <output-dir> [embedded|external]

set -euo pipefail

OUT="${1:-rust/gen_ui_core}"
UAR_MODE="${2:-embedded}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }

step "Scaffolding gen_ui_core: $OUT (UAR: $UAR_MODE)"
mkdir -p "$OUT/src"/{api,inference,mcp,agent,db,protocol}

# Cargo.toml
cat > "$OUT/Cargo.toml" << 'EOF'
[package]
name        = "gen_ui_core"
version.workspace = true
edition.workspace = true

[lib]
name       = "gen_ui_core"
crate-type = ["cdylib", "staticlib"]

[dependencies]
tokio.workspace             = true
tokio-stream.workspace      = true
futures.workspace           = true
flutter_rust_bridge.workspace = true
reqwest.workspace           = true
reqwest-eventsource.workspace = true
serde.workspace             = true
serde_json.workspace        = true
candle-core.workspace       = true
candle-nn.workspace         = true
candle-transformers.workspace = true
hf-hub.workspace            = true
tokenizers.workspace        = true
surrealdb.workspace         = true
rayon.workspace             = true
dashmap.workspace           = true
parking_lot.workspace       = true
tracing.workspace           = true
anyhow.workspace            = true
thiserror.workspace         = true
uuid.workspace              = true
chrono.workspace            = true
once_cell.workspace         = true
async-trait.workspace       = true
pin-project   = "1.1"
tokio-util    = { version = "0.7", features = ["codec"] }

[target.'cfg(target_os = "android")'.dependencies]
android_logger = "0.14"

[target.'cfg(target_os = "ios")'.dependencies]
oslog = "0.2"

[profile.release]
opt-level     = 3
lto           = "thin"
codegen-units = 1
panic         = "abort"
strip         = "symbols"
EOF
ok "$OUT/Cargo.toml"

# lib.rs
cat > "$OUT/src/lib.rs" << 'EOF'
//! gen_ui_core — Shared Rust infrastructure for Flutter + Tauri hybrid apps.
//! TJ-ARCH-MOB-001 compliant.
#![allow(clippy::too_many_arguments)]

pub mod api;
pub mod api_http;
pub mod runtime;
pub mod streaming;
pub mod config;
pub mod protocol;
pub mod inference;
pub mod mcp;
pub mod db;
pub mod agent;
EOF
ok "$OUT/src/lib.rs"

# config.rs
cat > "$OUT/src/config.rs" << 'EOF'
//! Application configuration — feature flags, UAR mode, API keys.
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum UarMode {
    /// UAR embedded in-process (default for standalone apps)
    Embedded,
    /// Connect to external UAR service via HTTP
    External {
        url: String,
        api_key: Option<String>,
        timeout_secs: u64,
    },
}

#[derive(Debug, Clone)]
pub struct AppConfig {
    pub uar_mode: UarMode,
    pub anthropic_api_key: String,
    pub data_dir: std::path::PathBuf,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            uar_mode: UarMode::Embedded,
            anthropic_api_key: std::env::var("ANTHROPIC_API_KEY").unwrap_or_default(),
            data_dir: dirs::data_dir()
                .unwrap_or_else(|| std::path::PathBuf::from("."))
                .join("gen_ui"),
        }
    }
}
EOF
ok "$OUT/src/config.rs"

# runtime.rs
cat > "$OUT/src/runtime.rs" << 'EOF'
//! Global Tokio runtime — one per process, N-1 worker threads, 8 blocking.
use std::sync::OnceLock;
use tokio::runtime::{Builder, Runtime};

static RT: OnceLock<Runtime> = OnceLock::new();

pub fn init(worker_threads: Option<usize>) {
    RT.get_or_init(|| {
        let n = worker_threads.unwrap_or_else(|| {
            std::thread::available_parallelism()
                .map(|n| (n.get()).max(2) - 1)
                .unwrap_or(4)
        });
        Builder::new_multi_thread()
            .worker_threads(n)
            .max_blocking_threads(8)
            .thread_name("gen-ui-worker")
            .thread_keep_alive(std::time::Duration::from_secs(60))
            .enable_all()
            .build()
            .expect("Tokio runtime init failed")
    });
}

pub fn handle() -> tokio::runtime::Handle {
    RT.get().expect("runtime not initialised").handle().clone()
}

pub fn spawn<F>(f: F) -> tokio::task::JoinHandle<F::Output>
where F: std::future::Future + Send + 'static, F::Output: Send + 'static {
    handle().spawn(f)
}

pub fn spawn_blocking<F, T>(f: F) -> tokio::task::JoinHandle<T>
where F: FnOnce() -> T + Send + 'static, T: Send + 'static {
    handle().spawn_blocking(f)
}
EOF
ok "$OUT/src/runtime.rs"

# api.rs (FFI surface stub)
cat > "$OUT/src/api.rs" << 'EOF'
//! FFI surface — flutter_rust_bridge codegen target (Flutter)
//! For Tauri: move commands to src-tauri/src/commands.rs
use flutter_rust_bridge::frb;
use once_cell::sync::OnceCell;
use std::sync::Arc;

use crate::{api_http::AnthropicClient, runtime, db};

static ANTHROPIC: OnceCell<Arc<AnthropicClient>> = OnceCell::new();

/// Call once from Dart main() before runApp()
#[frb(init)]
pub fn init_core(worker_threads: Option<usize>, data_dir: Option<String>) {
    #[cfg(target_os = "android")]
    android_logger::init_once(
        android_logger::Config::default()
            .with_max_level(log::LevelFilter::Debug)
            .with_tag("gen_ui_core"),
    );
    runtime::init(worker_threads);
    if let Some(dir) = data_dir {
        runtime::spawn(async move {
            let _ = db::init(std::path::Path::new(&dir)).await;
        });
    }
}

pub fn set_api_key(key: String) -> anyhow::Result<()> {
    let _ = ANTHROPIC.set(Arc::new(AnthropicClient::new(key)?));
    Ok(())
}

// TODO: Add stream_agent_a2ui, local_generate, memory_*, mcp_* functions
// See references/rust/patterns.md for full FFI surface implementation
EOF
ok "$OUT/src/api.rs"

# protocol/mod.rs stub
cat > "$OUT/src/protocol/mod.rs" << 'EOF'
//! A2UI + AG-UI dual-protocol pipeline.
pub mod a2ui;
pub mod agui;

use tokio::sync::{broadcast, mpsc};
use crate::streaming::StreamEvent;
pub use a2ui::A2uiEvent;
pub use agui::AguiEvent;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct FrbA2uiEvent { pub event_type: String, pub payload_json: String }
impl From<A2uiEvent> for FrbA2uiEvent {
    fn from(ev: A2uiEvent) -> Self {
        let v = serde_json::to_value(&ev).unwrap_or_default();
        Self { event_type: v["type"].as_str().unwrap_or("unknown").into(),
               payload_json: serde_json::to_string(&ev).unwrap_or_default() }
    }
}

pub struct ProtocolPipeline {
    pub run_id: String,
    pub thread_id: String,
    pub a2ui_tx: broadcast::Sender<A2uiEvent>,
    pub agui_tx: broadcast::Sender<AguiEvent>,
}

impl ProtocolPipeline {
    pub fn new(thread_id: impl Into<String>) -> Self {
        let (a2ui_tx, _) = broadcast::channel(512);
        let (agui_tx, _) = broadcast::channel(512);
        Self { run_id: uuid::Uuid::new_v4().to_string(), thread_id: thread_id.into(), a2ui_tx, agui_tx }
    }
    pub fn subscribe_a2ui(&self) -> broadcast::Receiver<A2uiEvent> { self.a2ui_tx.subscribe() }
    pub fn subscribe_agui(&self) -> broadcast::Receiver<AguiEvent> { self.agui_tx.subscribe() }

    pub async fn drive(self, mut rx: mpsc::Receiver<StreamEvent>) {
        let mut a2ui = a2ui::A2uiAdapter::new(&self.run_id);
        let mut agui = agui::AguiAdapter::new(&self.thread_id, &self.run_id);
        while let Some(raw) = rx.recv().await {
            let done = matches!(raw, StreamEvent::Done);
            for a2ui_ev in a2ui.ingest(&raw) {
                for agui_ev in agui.translate(&a2ui_ev) { let _ = self.agui_tx.send(agui_ev); }
                let _ = self.a2ui_tx.send(a2ui_ev);
            }
            if done { break; }
        }
    }
}
EOF
ok "$OUT/src/protocol/mod.rs"

# Create placeholder files for all remaining modules
for file in \
  "src/api_http.rs" \
  "src/streaming.rs" \
  "src/protocol/a2ui.rs" \
  "src/protocol/agui.rs" \
  "src/agent/mod.rs" \
  "src/inference/mod.rs" \
  "src/inference/sampler.rs" \
  "src/mcp/mod.rs" \
  "src/mcp/sse_transport.rs" \
  "src/mcp/stdio_transport.rs" \
  "src/db/mod.rs"; do
  if [[ ! -f "$OUT/$file" ]]; then
    echo "// TODO: Implement $(basename $file .rs) — see references/rust/patterns.md" > "$OUT/$file"
  fi
done
ok "Module stubs created"

step "Building Rust crate (check compilation)"
cd "$OUT"
cargo check 2>&1 | tail -5 || echo "(cargo check — install Rust and run again)"

echo ""
echo -e "${GREEN}✅ gen_ui_core scaffolded in $OUT${NC}"
echo ""
echo "  Next steps:"
echo "  1. Implement modules using references/rust/patterns.md"
echo "  2. Build Android: bash scripts/android/build.sh"
echo "  3. Build iOS: bash scripts/ios/build-xcframework.sh"
echo "  4. Generate bindings: flutter_rust_bridge_codegen generate --rust-input src/api.rs --dart-output ../../mobile/lib/bridge/generated_api.dart"
