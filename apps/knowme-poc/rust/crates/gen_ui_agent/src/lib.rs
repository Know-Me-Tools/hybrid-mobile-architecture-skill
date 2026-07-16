// TJ-ARCH-MOB-001 compliant
//! gen_ui_agent (L3) — PMPO loop (UAR embedded/external) over L0-L2 abstractions.
//!
//! T6/T7 land the chat-turn slice: [`ChatAgent`] resolves provider/model from
//! the config DB, drives a liter-llm streaming chat completion, and publishes
//! the resulting `A2uiEvent`s onto a per-run broadcast channel ([`RunRegistry`])
//! that gen_ui_ffi (mobile, via frb `StreamSink`) and tauri-plugin-gen-ui
//! (desktop, via Tauri `emit`) both subscribe to — the same orchestration code
//! runs on every platform; no business logic is duplicated per surface.

mod chat;
mod config_resolve;
mod error;
mod registry;
mod secret;
mod state;

pub use chat::ChatAgent;
pub use config_resolve::{resolve_chat_model, ResolvedModel, CHAT_LANE, CHAT_SURFACE};
pub use registry::RunRegistry;
pub use secret::{NoopSecretResolver, SecretResolver};
pub use state::{global as global_chat_agent, install as install_chat_agent};
