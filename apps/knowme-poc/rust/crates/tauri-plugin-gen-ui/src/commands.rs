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
use gen_ui_db_graph::{FastEmbedder, GraphStore, GraphStoreConfig, MemoryHit, RelatedEntity};
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

/// Current chat lane: "cloud" or "local".
#[tauri::command]
pub async fn get_active_lane() -> Result<String> {
    gen_ui_agent::chat::active_lane()
        .await
        .map_err(gen_ui_types::CoreError::from)
        .map_err(Into::into)
}

/// Switch chat lanes. Errors on an unknown lane, or on "local" where this build
/// has no engine — the toggle fails loudly here rather than silently answering
/// from the cloud at the next turn.
#[tauri::command]
pub async fn set_active_lane(lane: String) -> Result<()> {
    gen_ui_agent::chat::set_active_lane(&lane)
        .await
        .map_err(gen_ui_types::CoreError::from)
        .map_err(Into::into)
}

/// Whether a local-inference engine exists on this build — the UI shows the lane
/// toggle only when it does.
#[tauri::command]
pub async fn has_local_engine() -> Result<bool> {
    Ok(gen_ui_agent::chat::has_local_engine())
}

/// Boot-order invariant, step 1: open the config store (pglite-oxide) AND the
/// memory/graph-RAG store (embedded SurrealDB — a separate concern from config
/// storage, see gen_ui_agent::state::init's doc comment: memory is
/// SurrealDB-only on every platform, desktop included, regardless of which
/// config-DB engine is in use), then initialise gen_ui_agent's process-lifetime
/// state (config backend + memory store + A2uiEvent broadcast). Idempotent per
/// process — the frontend calls this once at startup, before
/// load_seeds/attach_sync_shapes.
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
    let config_store = gen_ui_db::relational::PgliteStore::open(data_dir.join("config-db"))
        .await
        .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?;

    let embedder = gen_ui_runtime::spawn_blocking(FastEmbedder::new)
        .await
        .map_err(|e| gen_ui_types::CoreError::Transient(format!("embedder task join: {e}")))?
        .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?;
    let memory_store = GraphStore::open(GraphStoreConfig {
        endpoint: format!("rocksdb://{}", data_dir.join("memory-db").display()),
        namespace: "knowme".to_string(),
        database: "poc".to_string(),
        embedder: Arc::new(embedder),
    })
    .await
    .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?;

    // Desktop's local-inference lane. Constructing the engine is cheap — no model
    // is touched until a `local`-lane chat turn calls load() — so this is
    // unconditional; the cost is only paid by users who switch to local.
    let inference: Arc<dyn gen_ui_types::inference::InferenceProvider> =
        Arc::new(gen_ui_inference::MistralEngine::new());

    gen_ui_agent::state::init_with_inference(
        ConfigBackend::Postgres(Arc::new(config_store)),
        Arc::new(memory_store),
        Some(inference),
    );
    Ok(())
}

/// Boot-order invariant, step 2: seed data.
///
/// Ingests the C-111 demo corpus so a fresh install's memory search returns real
/// results instead of nothing. Idempotent (stable seed ids), so running on every start
/// upserts rather than duplicates. MUST follow `run_migrations` — there is no store to
/// seed into before it.
///
/// Seeding embeds every note, so this is not instant on a cold start; it is a boot step
/// rather than a lazy path precisely so the cost lands once, before the user searches.
#[tauri::command]
pub async fn load_seeds() -> Result<()> {
    let n = gen_ui_agent::memory::seed_demo_corpus()
        .await
        .map_err(gen_ui_types::CoreError::from)?;
    log::info!("seeded {n} demo memories");
    Ok(())
}

/// Boot-order invariant, step 3: attach sync (C-106).
///
/// Starts the FRF-backed [`FrfSyncTransport`]: the read lane materialises server row
/// changes into the local pglite store, and the write queue replays local mutations
/// through forge/Quarry. MUST run after `run_migrations` — a change cannot be applied to
/// a table that does not exist yet, which is the whole reason boot order is an invariant
/// here and not a suggestion.
///
/// **Sync is opt-in and absent-by-default.** With no `sync.frf` settings in the config
/// DB this returns `Ok(())` and the app runs purely local. That is the correct default
/// for a PoC whose fabric is a private cross-org service most developers cannot reach —
/// failing startup because an optional backend is unconfigured would make the app
/// unrunnable for everyone who is not doing sync work today.
#[tauri::command]
pub async fn attach_sync_shapes<R: Runtime>(app: tauri::AppHandle<R>) -> Result<()> {
    use gen_ui_db::sync::{FrfSyncTransport, PgLocalStore, SyncTransport};

    let data_dir = app.path().app_data_dir()?;
    let Some(cfg) = read_sync_config(&data_dir).await? else {
        log::info!("sync: not configured (no `sync.frf` setting) — running local-only");
        return Ok(());
    };

    // The pool the read lane writes into is the SAME pglite store `run_migrations`
    // opened — `PgliteStore::open` is a per-process singleton, so this hands back the
    // live server rather than racing a second one against the same directory.
    let store = gen_ui_db::relational::PgliteStore::open(data_dir.join("config-db"))
        .await
        .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?;
    let local = Arc::new(PgLocalStore::new(store.store().pool().clone()));

    let sink = gen_ui_agent::sync_sink::forge_write_sink(
        cfg.forge_base.clone(),
        "public",
        cfg.token.clone(),
    )?;

    let transport = FrfSyncTransport::new(cfg.into_transport_config(), local, sink);
    transport.start().await?;

    // Hold the transport for the process lifetime: dropping it stops the drain loop and
    // the read lane (they only live as long as the Arcs they captured).
    SYNC
        .set(Arc::new(transport))
        .map_err(|_| gen_ui_types::CoreError::Terminal("sync already attached".into()))?;
    Ok(())
}

/// The live sync transport. `OnceCell` mirrors `gen_ui_agent::state`'s process-lifetime
/// pattern and makes a second `attach_sync_shapes` a loud error rather than a silent
/// second engine competing for the same channel.
static SYNC: OnceCell<Arc<gen_ui_db::sync::FrfSyncTransport>> = OnceCell::new();

/// Sync settings as stored in the config DB under `sync.frf`.
#[derive(serde::Deserialize)]
struct SyncSettings {
    endpoint: String,
    tenant_id: String,
    channel_path: String,
    consumer_id: String,
    forge_base: String,
    #[serde(default)]
    token: Option<String>,
}

impl SyncSettings {
    fn into_transport_config(self) -> gen_ui_db::sync::FrfSyncConfig {
        gen_ui_db::sync::FrfSyncConfig {
            endpoint: self.endpoint,
            token: self.token,
            tenant_id: self.tenant_id,
            channel_path: self.channel_path,
            consumer_id: self.consumer_id,
            write_batch: 32,
            max_write_attempts: 5,
        }
    }
}

/// Read `sync.frf` from the config DB. `Ok(None)` = not configured (the default).
///
/// A malformed setting IS an error: someone tried to configure sync and got it wrong,
/// and silently falling back to local-only would hide that from them.
async fn read_sync_config(data_dir: &std::path::Path) -> Result<Option<SyncSettings>> {
    use gen_ui_db::relational::ConfigStore;

    let store = gen_ui_db::relational::PgliteStore::open(data_dir.join("config-db"))
        .await
        .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?;
    let Some(raw) = store
        .store()
        .get_setting("sync.frf")
        .await
        .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?
    else {
        return Ok(None);
    };
    let parsed = serde_json::from_value(raw)
        .map_err(|e| gen_ui_types::CoreError::Serde(format!("sync.frf setting: {e}")))?;
    Ok(Some(parsed))
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

/// Hybrid graph-RAG search. Delegates to the SAME `gen_ui_agent::memory` the mobile
/// FFI calls — no duplicated business logic.
///
/// Returns the real `MemoryHit` (id/text/kind/score), not the `Vec<String>` this
/// used to stub out: C-104 wired the mobile FFI to the agent but left this command
/// returning an empty vec, so desktop memory search silently produced nothing.
/// Found while surfacing the Memory screen in C-113.
#[tauri::command]
pub async fn memory_search(query: String, k: u32) -> Result<Vec<MemoryHit>> {
    gen_ui_agent::memory::search(query, k)
        .await
        .map_err(gen_ui_types::CoreError::from)
        .map_err(Into::into)
}

/// Graph expansion from an entity. Same delegation, same C-104 gap as above.
#[tauri::command]
pub async fn graph_expand(entity_id: String, depth: u32) -> Result<Vec<RelatedEntity>> {
    gen_ui_agent::memory::graph_expand(entity_id, depth)
        .await
        .map_err(gen_ui_types::CoreError::from)
        .map_err(Into::into)
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
