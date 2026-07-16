// TJ-ARCH-MOB-001 compliant
//! Tauri command handlers. Thin wrappers over the shared intent surface. Desktop
//! runs gen_ui_core in-process, so these call the same logic gen_ui_ffi exposes to
//! Flutter — no duplicated business logic (constraint: logic lives in Rust core).
//! run_migrations/load_seeds/attach_sync_shapes replace the ad-hoc stubs that used
//! to live directly in src-tauri/src/commands.rs (removed — this plugin is now the
//! single desktop command surface, matching the mobile FFI's single intent surface).
use std::sync::{Arc, Mutex};

use crate::error::Result;
use gen_ui_agent::ConfigBackend;
use gen_ui_types::transport::{EntityRecord, ListResult};
use gen_ui_types::view::ViewDescriptor;
use once_cell::sync::OnceCell;
use tauri::{Manager, Runtime};

// Named to match the frontend's existing invoke('stream_agent_a2ui', ...) call
// site (src/features/chat/stores/chatStore.ts) rather than renaming the
// frontend — mobile's frb bridge calls the equivalent Rust fn `chat_send`
// directly by name (no separate invoke-key layer), so the two ecosystems
// have different but internally consistent naming.
#[tauri::command]
pub async fn stream_agent_a2ui(user_message: String, messages: Vec<String>) -> Result<String> {
    gen_ui_agent::chat::send(user_message, messages)
        .await
        .map_err(gen_ui_types::CoreError::from)
        .map_err(Into::into)
}

/// Boot-order invariant, step 1: open the config store (pglite-oxide), run its
/// migrations, and initialise gen_ui_agent's process-lifetime state (config
/// backend + A2uiEvent broadcast). Idempotent per process — the frontend calls
/// this once at startup, before load_seeds/attach_sync_shapes.
///
/// Concurrent duplicate invocations (React StrictMode double-invokes the startup
/// effect in dev) are safe: `PgliteStore::open` coalesces concurrent callers
/// onto one in-flight initialization (see its doc comment). Cross-process
/// contention is prevented by `tauri-plugin-single-instance`, registered ahead
/// of this plugin. Any remaining open failure surfaces pglite-oxide's own error
/// text verbatim — no re-labelling, so the real cause is never masked.
#[tauri::command]
pub async fn run_migrations<R: Runtime>(app: tauri::AppHandle<R>) -> Result<()> {
    let data_dir = app.path().app_data_dir()?;
    std::fs::create_dir_all(&data_dir).map_err(|e| {
        tauri::Error::from(std::io::Error::new(e.kind(), format!("app data dir: {e}")))
    })?;
    let store = gen_ui_db::relational::PgliteStore::open(data_dir.join("config-db"))
        .await
        .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?;
    gen_ui_agent::state::init(ConfigBackend::Postgres(Arc::new(store)));
    Ok(())
}

/// Boot-order invariant, step 2: seed data. No seed bundles for the PoC yet
/// (C-104 supplies the memory corpus) — a real no-op until then.
#[tauri::command]
pub async fn load_seeds() -> Result<()> {
    Ok(())
}

/// Boot-order invariant, step 3: attach sync shapes. C-106's job — real no-op
/// until then (migrations+seeds must still run first even without live sync).
#[tauri::command]
pub async fn attach_sync_shapes() -> Result<()> {
    Ok(())
}

/// C-104 wires the real memory graph-RAG ingest; stub keeps the app booting.
#[tauri::command]
pub async fn memory_ingest(text: String) -> Result<String> {
    let _ = text;
    Ok(String::new())
}

/// C-104/C-003 wire the real entity runtime; stub keeps the app booting.
#[tauri::command]
pub async fn entity_runtime_start(tenant_id: String) -> Result<()> {
    let _ = tenant_id;
    Ok(())
}

#[tauri::command]
pub async fn entity_runtime_stop() -> Result<()> {
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

// Scribe (voice-to-memory): delegates entirely to gen_ui_audio, the SAME crate
// gen_ui_ffi's mobile scribe_start/scribe_stop call — no duplicated business
// logic. One recording in flight per process, mirroring gen_ui_agent's
// single-chat-turn precedent.
static RECORDING: OnceCell<Mutex<Option<gen_ui_audio::Recorder>>> = OnceCell::new();

fn recording_slot() -> &'static Mutex<Option<gen_ui_audio::Recorder>> {
    RECORDING.get_or_init(|| Mutex::new(None))
}

#[tauri::command]
pub async fn scribe_start() -> Result<()> {
    let mut guard = recording_slot().lock().expect("scribe recording mutex poisoned");
    if guard.is_some() {
        return Err(gen_ui_types::CoreError::Terminal(
            "a recording is already in progress".to_string(),
        )
        .into());
    }
    let recorder = gen_ui_audio::Scribe::new()
        .start_recording()
        .map_err(Into::<gen_ui_types::CoreError>::into)?;
    *guard = Some(recorder);
    Ok(())
}

#[tauri::command]
pub async fn scribe_stop() -> Result<String> {
    let recorder = recording_slot()
        .lock()
        .expect("scribe recording mutex poisoned")
        .take()
        .ok_or_else(|| {
            gen_ui_types::CoreError::Terminal("no recording in progress".to_string())
        })?;
    gen_ui_audio::Scribe::new()
        .stop_and_transcribe(recorder)
        .await
        .map_err(Into::<gen_ui_types::CoreError>::into)
        .map_err(Into::into)
}
