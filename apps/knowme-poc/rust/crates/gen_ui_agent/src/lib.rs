// TJ-ARCH-MOB-001 compliant
//! gen_ui_agent (L3) — PMPO loop (UAR embedded/external) over L0-L2 abstractions.
//! `chat` is the shared chat-send implementation both platform leaves
//! (gen_ui_ffi mobile, tauri-plugin-gen-ui desktop) call into — see chat.rs.

pub mod chat;
pub mod config;
pub mod error;
pub mod memory;
pub mod secrets;
pub mod state;
// C-106: forge-backed WriteSink. Lives here (L3) because the trait is gen_ui_db's and
// the client is gen_ui_client's — L2 siblings that must not depend on each other.
pub mod sync_sink;

pub use config::ConfigBackend;
pub use error::AgentError;
