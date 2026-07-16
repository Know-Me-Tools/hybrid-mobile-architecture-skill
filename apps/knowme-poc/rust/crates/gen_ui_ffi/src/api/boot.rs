// TJ-ARCH-MOB-001 compliant
//! Mobile boot-order intent surface, mirroring tauri-plugin-gen-ui's
//! run_migrations/load_seeds/attach_sync_shapes commands: migrations -> seeds
//! -> shapes (shapes fail on unknown columns, so this order is load-bearing).
//! Dart resolves the platform data directory (path_provider) and passes it in
//! — Rust has no portable way to ask the OS for it on mobile.
use std::sync::Arc;

use gen_ui_agent::ConfigBackend;
use gen_ui_db_graph::{FastEmbedder, GraphStore, GraphStoreConfig};
// frb's Result<T,E> detection needs a literal `Result<...>` — see chat.rs's
// note; CoreResult<T>'s generic alias is invisible to frb's codegen.
use gen_ui_types::CoreError;

/// Boot-order invariant, step 1: open the embedded SurrealDB store (config +
/// memory/graph-RAG both live in it on mobile — see gen_ui_agent::state::init's
/// doc comment on why memory is SurrealDB-only regardless of platform) and
/// initialise gen_ui_agent's process-lifetime state. Idempotent per process.
pub async fn run_migrations(data_dir: String) -> Result<(), CoreError> {
    let db_path = format!("{data_dir}/knowme-poc.db");
    let embedder = gen_ui_runtime::spawn_blocking(FastEmbedder::new)
        .await
        .map_err(|e| gen_ui_types::CoreError::Transient(format!("embedder task join: {e}")))?
        .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?;

    let store = GraphStore::open(GraphStoreConfig {
        endpoint: format!("rocksdb://{db_path}"),
        namespace: "knowme".to_string(),
        database: "poc".to_string(),
        embedder: Arc::new(embedder),
    })
    .await
    .map_err(|e| gen_ui_types::CoreError::Transient(e.to_string()))?;
    let store = Arc::new(store);

    gen_ui_agent::state::init(ConfigBackend::Surreal(store.clone()), store);
    Ok(())
}

/// Boot-order invariant, step 2: seed data. No seed bundles for the PoC yet
/// (C-104's curated corpus lands separately) — a real no-op until then.
pub async fn load_seeds() -> Result<(), CoreError> {
    Ok(())
}

/// Boot-order invariant, step 3: attach sync (C-106).
///
/// **Still a no-op on mobile, and deliberately so — see below.** Desktop's equivalent
/// (`tauri-plugin-gen-ui::commands::attach_sync_shapes`) is live: it starts an
/// `FrfSyncTransport` whose read lane materialises row changes into `PgLocalStore`.
///
/// Mobile cannot reuse that, because mobile has no Postgres. `run_migrations` above
/// opens embedded SurrealDB and registers it as BOTH config and memory backend
/// (`ConfigBackend::Surreal`) — pglite-oxide is structurally unsupported on iOS/Android
/// (no child processes, no JIT), which is why the split exists at all. So the read lane
/// needs a `LocalStore` over SurrealDB, and `gen_ui_db_graph`'s public surface is
/// intent-level by design ("INTENT-LEVEL, never raw SurrealQL" — lib.rs): it exposes
/// `memory_ingest`/`memory_search`/`graph_expand`, not row upserts. Writing a
/// `SurrealLocalStore` means adding a row-persistence surface to that crate, which is a
/// real design decision about its contract — not something to smuggle in under a sync
/// task. Tracked as C-106 T5; the honest state is "desktop syncs, mobile does not yet".
///
/// The write path is NOT blocked by this: `gen_ui_agent::sync_sink::forge_write_sink`
/// is platform-agnostic, so once a mobile `LocalStore` exists the wiring here mirrors
/// desktop's exactly.
pub async fn attach_sync_shapes() -> Result<(), CoreError> {
    Ok(())
}
