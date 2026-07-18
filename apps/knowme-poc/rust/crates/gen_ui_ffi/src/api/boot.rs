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
    fn boot_fail(stage: &str, message: impl std::fmt::Display) -> CoreError {
        let rendered = format!("{stage}: {message}");
        eprintln!("[knowme boot] {rendered}");
        tracing::error!(stage, error = %message, "mobile boot phase failed");
        CoreError::Transient(rendered)
    }

    tracing::info!(%data_dir, "mobile migrations starting");
    crate::api::entity::init_store(
        std::path::PathBuf::from(&data_dir).join("entity-records.sqlite3"),
    )
    .await?;
    let db_path = format!("{data_dir}/knowme-poc.db");
    let embed_cache = std::path::PathBuf::from(&data_dir).join("model-cache/fastembed");
    std::fs::create_dir_all(&embed_cache).map_err(|e| boot_fail("model cache create", e))?;
    let embedder = gen_ui_runtime::spawn_blocking(move || FastEmbedder::new(embed_cache))
        .await
        .map_err(|e| boot_fail("embedder task join", e))?
        .map_err(|e| boot_fail("embedder load", e))?;

    let store = GraphStore::open(GraphStoreConfig {
        endpoint: format!("rocksdb://{db_path}"),
        namespace: "knowme".to_string(),
        database: "poc".to_string(),
        embedder: Arc::new(embedder),
    })
    .await
    .map_err(|e| boot_fail("graph store open", e))?;
    let store = Arc::new(store);

    // The mobile engine ships the smaller Qwen catalog entry. Persist an
    // explicit preference so the agent never guesses the desktop model id.
    if store
        .get_model_pref("chat", "local")
        .await
        .map_err(|e| boot_fail("local model preference read", e))?
        .is_none()
    {
        store
            .upsert_model_pref(&gen_ui_db_graph::ModelPref {
                surface: "chat".to_string(),
                lane: "local".to_string(),
                provider_id: None,
                model_id: "qwen2.5-0.5b-instruct-q4".to_string(),
                params: serde_json::json!({
                    "context_len": 2048,
                    "max_tokens": 128,
                    "temperature": 0.7,
                    "top_p": 0.95
                }),
            })
            .await
            .map_err(|e| boot_fail("local model preference write", e))?;
    }

    let inference: Arc<dyn gen_ui_types::inference::InferenceProvider> =
        Arc::new(gen_ui_inference::LlamaCppEngine::new(
            std::path::PathBuf::from(&data_dir).join("model-cache/llama"),
        ));
    gen_ui_agent::state::init_with_inference(
        ConfigBackend::Surreal(store.clone()),
        store,
        Some(inference),
    );
    tracing::info!("mobile migrations ready");
    Ok(())
}

/// Boot-order invariant, step 2: seed data.
///
/// Ingests the C-111 demo corpus through the SAME `gen_ui_agent::memory` the desktop
/// plugin's `load_seeds` calls — no duplicated seeding logic, and both surfaces get an
/// identical corpus. Idempotent (stable seed ids), so running on every start upserts
/// rather than duplicates. MUST follow `run_migrations`.
///
/// Returns the number of notes seeded, so Dart can report progress rather than stare at
/// a silent pause: every note is embedded here, which is not instant on a cold start.
pub async fn load_seeds() -> Result<u32, CoreError> {
    let n = gen_ui_agent::memory::seed_demo_corpus().await?;
    Ok(n as u32)
}

/// Boot-order invariant, step 3 (LEGACY name — see [`attach_sync_scopes`]).
/// Kept as a no-op alias so any caller still on the old Electric-era name
/// does not silently skip sync attach; new code calls `attach_sync_scopes`.
pub async fn attach_sync_shapes() -> Result<(), CoreError> {
    Ok(())
}

/// Boot-order invariant, step 3 (C-127, resolving the C-106 T5 tracked gap):
/// attach partial-replication scopes over mobile's `LocalStore`.
///
/// Desktop's equivalent (`tauri-plugin-gen-ui::commands::attach_sync_shapes`)
/// runs an `FrfSyncTransport` whose read lane materialises row changes into
/// `PgLocalStore` (Postgres-protocol). Mobile has no Postgres — `run_migrations`
/// opened embedded SurrealDB as `ConfigBackend::Surreal` instead (pglite-oxide
/// is structurally unsupported on iOS/Android: no child processes, no JIT).
///
/// `GraphStore::local_store()` is the sanctioned way to reach that SAME
/// connection as a [`gen_ui_db::sync::LocalStore`] (`SurrealLocalStore`,
/// gen_ui_db_graph::sync — deliberately NOT part of the crate's intent-level
/// `memory_ingest`/`memory_search`/`graph_expand` surface; its own module,
/// its own narrow row-envelope table). This slice attaches a dev loopback
/// transport (`gen_ui_db::sync::LoopbackSyncTransport`) behind the identical
/// `SyncTransport` seam the FRF transport implements — the production PES/FRF
/// client swaps in later without touching this call site (ADR-LFS-1).
///
/// MUST run after `run_migrations` (which opens the SurrealDB connection this
/// depends on) and after any onboarding loads that decide which scopes apply.
pub async fn attach_sync_scopes(
    user_subset_tenant: Option<String>,
) -> Result<(), CoreError> {
    use gen_ui_types::sync::{SyncScope, SyncTransport};

    let memory = gen_ui_agent::state::memory()
        .map_err(|e| CoreError::Terminal(format!("attach_sync_scopes: {e}")))?;
    let store = memory
        .local_store()
        .await
        .map_err(|e| CoreError::Terminal(format!("local_store: {e}")))?;
    let (transport, _feed) = gen_ui_db::sync::LoopbackSyncTransport::new(store);

    let mut scopes = vec![SyncScope::shared_lookup("lookup-metatypes")];
    if let Some(tenant) = user_subset_tenant {
        scopes.push(SyncScope::user_subset("user-notes", tenant));
    }
    transport
        .start_scopes(&scopes)
        .await
        .map_err(|e| CoreError::Terminal(format!("start_scopes: {e}")))
}

/// Boot-order invariant, step 2b (C-127): run ledgered one-time loads for
/// `stage` ("pre" before onboarding UI, "post" after). Idempotent — see
/// `gen_ui_db::relational::run_one_time_loads`'s doc comment; a failed
/// post-onboarding load defers rather than blocking the user.
///
/// Mobile has no relational `StartupStore`/`LookupLedger` today (no
/// pglite-oxide) — this wraps the ledger over the same SurrealDB connection
/// so the one-time-load CONTRACT is honored on mobile without inventing a
/// second ledger shape. Bundles are supplied by the caller (Dart resolves
/// which bundles apply; this function only enforces once-per-version).
pub async fn run_one_time_loads(stage: String) -> Result<Vec<String>, CoreError> {
    let parsed_stage = match stage.as_str() {
        "pre" => gen_ui_db::relational::LoadStage::PreOnboarding,
        "post" => gen_ui_db::relational::LoadStage::PostOnboarding,
        other => {
            return Err(CoreError::Terminal(format!(
                "run_one_time_loads: unknown stage {other:?} (expected \"pre\" or \"post\")"
            )))
        }
    };
    // No bundles are wired yet on mobile (nothing ships a mobile-specific
    // pre/post-onboarding bundle today) — this proves the boot-order contract
    // end-to-end; bundles arrive with the first real mobile onboarding flow.
    let loads: Vec<gen_ui_db::relational::OneTimeLoad> = Vec::new();
    let ledger = gen_ui_db::relational::MemoryLookupLedger::default();

    struct NoopStore;
    #[async_trait::async_trait]
    impl gen_ui_db::relational::StartupStore for NoopStore {
        async fn migrate(&self) -> gen_ui_db::relational::RelationalResult<()> {
            Ok(())
        }
        async fn execute_seed(&self, _sql: &str) -> gen_ui_db::relational::RelationalResult<()> {
            Ok(())
        }
    }
    let client = reqwest::Client::new();
    let results = gen_ui_db::relational::run_one_time_loads(
        &NoopStore,
        &ledger,
        &client,
        &loads,
        parsed_stage,
    )
    .await
    .map_err(|e| CoreError::Terminal(format!("run_one_time_loads: {e}")))?;
    Ok(results
        .into_iter()
        .map(|r| format!("{r:?}"))
        .collect())
}
