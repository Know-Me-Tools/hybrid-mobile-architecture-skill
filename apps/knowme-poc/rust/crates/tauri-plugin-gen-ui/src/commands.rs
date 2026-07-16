// TJ-ARCH-MOB-001 compliant
//! Tauri command handlers. Thin wrappers over the shared intent surface. Desktop
//! runs gen_ui_core in-process, so these call the same logic gen_ui_ffi exposes to
//! Flutter — no duplicated business logic (constraint: logic lives in Rust core).
use tauri::{AppHandle, Emitter, Runtime};

use crate::error::Result;
use crate::GEN_UI_CHAT_EVENT;
use gen_ui_types::transport::{EntityRecord, ListResult};
use gen_ui_types::view::ViewDescriptor;

/// Start a chat turn. Calls the SAME gen_ui_agent orchestration gen_ui_ffi's
/// `chat_send` calls (no duplicated business logic) and returns the run_id
/// immediately; the stream itself arrives via `chat_subscribe` + the
/// `GEN_UI_CHAT_EVENT` channel, mirroring gen_ui_ffi's chat_send/chat_events
/// split for the FFI surface.
#[tauri::command]
pub async fn chat_send(thread_id: String, message: String) -> Result<String> {
    Ok(gen_ui_agent::global_chat_agent().send(thread_id, message).await?)
}

/// Subscribe to a chat run's event stream and forward it as
/// `GEN_UI_CHAT_EVENT` Tauri events. Desktop has no `StreamSink<T>` (that's the
/// frb/mobile bridge) — Tauri's `AppHandle::emit` is the equivalent event
/// channel, so this command is the desktop counterpart of gen_ui_ffi's
/// `streams::chat_events`. The JS side calls this once after `chat_send`
/// resolves, then listens on `GEN_UI_CHAT_EVENT` (per the layer contract: only
/// Zustand stores invoke commands / listen for events).
///
/// Returns immediately once the forwarding task is spawned; it does not block
/// for the run to finish. Unknown run_id (never started, or already finished)
/// is a silent no-op — there is nothing to stream.
#[tauri::command]
pub async fn chat_subscribe<R: Runtime>(run_id: String, app_handle: AppHandle<R>) -> Result<()> {
    let Some(mut rx) = gen_ui_agent::global_chat_agent().registry().subscribe(&run_id) else {
        return Ok(());
    };
    gen_ui_runtime::spawn(async move {
        loop {
            match rx.recv().await {
                Ok(event) => {
                    // Emit failures mean no window is listening (e.g. it closed
                    // mid-stream) — stop forwarding rather than erroring, the
                    // run itself already completed independently of the UI.
                    if app_handle.emit(GEN_UI_CHAT_EVENT, &event).is_err() {
                        break;
                    }
                }
                Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => continue,
                Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
            }
        }
    });
    Ok(())
}

#[tauri::command]
pub async fn entity_list(view: ViewDescriptor) -> Result<ListResult> {
    let _ = view;
    Ok(ListResult { items: Vec::new(), next_cursor: None })
}

#[tauri::command]
pub async fn entity_get(entity_type: String, id: String) -> Result<Option<EntityRecord>> {
    let _ = (entity_type, id);
    Ok(None)
}

#[tauri::command]
pub async fn entity_create(record: EntityRecord) -> Result<EntityRecord> {
    Ok(record)
}

#[tauri::command]
pub async fn entity_update(record: EntityRecord) -> Result<EntityRecord> {
    Ok(record)
}

#[tauri::command]
pub async fn entity_delete(entity_type: String, id: String) -> Result<()> {
    let _ = (entity_type, id);
    Ok(())
}

#[tauri::command]
pub async fn memory_search(query: String, k: u32) -> Result<Vec<String>> {
    let _ = (query, k);
    Ok(Vec::new())
}

#[tauri::command]
pub async fn graph_expand(entity_id: String, depth: u32) -> Result<Vec<String>> {
    let _ = (entity_id, depth);
    Ok(Vec::new())
}
