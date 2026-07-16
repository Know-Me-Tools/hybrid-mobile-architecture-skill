// TJ-ARCH-MOB-001 compliant
//! tauri-plugin-gen-ui (LEAF) — Tauri 2 plugin exposing the same intent surface as
//! gen_ui_ffi, but as `#[tauri::command]` handlers. Desktop shares gen_ui_core in
//! the SAME process (no FFI): commands call the intent functions directly.
//!
//! LAYER CONTRACT: the JS side invokes these ONLY from Zustand stores — never from
//! a React component or hook. The npm guest-js package (guest-js/) provides typed
//! wrappers + `listen` helpers for the event channels.
use tauri::{
    plugin::{Builder, TauriPlugin},
    Manager, Runtime,
};

mod commands;
mod error;

pub use error::{Error, Result};

/// Emit-channel names for the three UI-facing event feeds (mirror gen_ui_ffi
/// streams). Stores subscribe with `listen(GEN_UI_CHAT_EVENT, ...)`.
pub const GEN_UI_CHAT_EVENT: &str = "gen-ui://chat-event";
pub const GEN_UI_ENTITY_CHANGE: &str = "gen-ui://entity-change";
pub const GEN_UI_SYNC_STATUS: &str = "gen-ui://sync-status";

/// Build the plugin. Register in the Tauri app with `.plugin(tauri_plugin_gen_ui::init())`.
pub fn init<R: Runtime>() -> TauriPlugin<R> {
    Builder::new("gen-ui")
        .invoke_handler(tauri::generate_handler![
            commands::chat_send,
            commands::chat_subscribe,
            commands::entity_list,
            commands::entity_get,
            commands::entity_create,
            commands::entity_update,
            commands::entity_delete,
            commands::memory_search,
            commands::graph_expand,
        ])
        .setup(|app, _api| {
            // One global Tokio runtime per process (never a second). Desktop
            // shares gen_ui_core in-process, so init here rather than via FFI.
            gen_ui_runtime::init(None);
            let _ = app.app_handle();
            Ok(())
        })
        .build()
}
