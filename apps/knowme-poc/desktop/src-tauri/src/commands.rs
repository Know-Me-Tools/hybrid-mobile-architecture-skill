// TJ-ARCH-MOB-001 compliant
// Tauri command surface. Stub bodies today — Wave-1 lanes (C-104/C-105/C-106)
// wire these into gen_ui_core once the shared Rust crate is linked as a
// dependency of this crate. Signatures match the frontend's invoke() contract
// (src/features/*/stores/*.ts) so wiring a real backend never changes the
// frontend call sites.

use serde::{Deserialize, Serialize};

#[tauri::command]
pub async fn run_migrations() -> Result<(), String> {
    Ok(())
}

#[tauri::command]
pub async fn load_seeds() -> Result<(), String> {
    Ok(())
}

#[tauri::command]
pub async fn attach_sync_shapes() -> Result<(), String> {
    Ok(())
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MemoryHit {
    pub name: String,
    pub score: f64,
    pub snippet: Option<String>,
}

#[tauri::command]
pub async fn memory_ingest(text: String) -> Result<String, String> {
    let _ = text;
    Ok(String::new())
}

#[tauri::command]
pub async fn memory_search(query: String, k: u32) -> Result<Vec<MemoryHit>, String> {
    let _ = (query, k);
    Ok(Vec::new())
}

#[tauri::command]
pub async fn entity_runtime_start(tenant_id: String) -> Result<(), String> {
    let _ = tenant_id;
    Ok(())
}

#[tauri::command]
pub async fn entity_runtime_stop() -> Result<(), String> {
    Ok(())
}
