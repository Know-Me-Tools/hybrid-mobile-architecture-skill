// TJ-ARCH-MOB-001 compliant
//! Tauri command handlers. Thin wrappers over the shared intent surface. Desktop
//! runs gen_ui_core in-process, so these call the same logic gen_ui_ffi exposes to
//! Flutter — no duplicated business logic (constraint: logic lives in Rust core).
use crate::error::Result;
use gen_ui_types::transport::{EntityRecord, ListResult};
use gen_ui_types::view::ViewDescriptor;

#[tauri::command]
pub async fn chat_send(thread_id: String, message: String) -> Result<String> {
    // C-006 dispatches into the PMPO loop; C-007 lands the command seam.
    let _ = (thread_id, message);
    Ok(String::new())
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
