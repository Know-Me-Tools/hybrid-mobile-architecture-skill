// TJ-ARCH-MOB-001 compliant
//! Process-wide `ChatAgent` handle. gen_ui_ffi's `#[frb(init)]` and
//! tauri-plugin-gen-ui's `.setup(...)` both run once per process before any
//! chat command fires — this module gives them a single place to install the
//! real `ConfigStore`/`SecretResolver` once the platform wiring exists (T8+),
//! while letting `chat_send` work correctly (graceful-degrade, not panic)
//! *today* even before that wiring lands.
//!
//! DESIGN NOTE (ambiguous in spec): the task brief describes `ChatAgent`
//! resolving config from "the config DB" but neither gen_ui_ffi's `init_core`
//! nor tauri-plugin-gen-ui's `.setup(...)` currently construct or hold a
//! `ConfigStore` (that lands with the desktop pglite-oxide / mobile SurrealDB
//! startup wiring, T8+). Rather than block T6/T7 on that follow-up work, this
//! module defaults to `NoopConfigStore`, which deterministically reports "no
//! provider configured" — the exact graceful-degrade path required by T6 — and
//! exposes `install` so a later init step can swap in the real store without
//! any change to `chat.rs`, `gen_ui_ffi`, or `tauri-plugin-gen-ui`'s call sites.
use std::sync::{Arc, OnceLock};

use async_trait::async_trait;
use gen_ui_db::relational::{ConfigStore, ModelPref, Provider, RelationalError, RelationalResult};

use crate::chat::ChatAgent;
use crate::registry::RunRegistry;
use crate::secret::{NoopSecretResolver, SecretResolver};

/// `ConfigStore` impl used until a real backend (pglite-oxide desktop /
/// SurrealDB mobile, via an adapter) is installed. Every read reports "not
/// configured"; every write fails — this store is never meant to persist
/// anything, only to make the graceful-degrade path reachable before startup
/// wiring exists.
#[derive(Debug, Default)]
struct NoopConfigStore;

#[async_trait]
impl ConfigStore for NoopConfigStore {
    async fn list_providers(&self) -> RelationalResult<Vec<Provider>> {
        Ok(Vec::new())
    }
    async fn upsert_provider(&self, _provider: &Provider) -> RelationalResult<()> {
        Err(RelationalError::Sync("NoopConfigStore is read-only".into()))
    }
    async fn delete_provider(&self, _id: &str) -> RelationalResult<()> {
        Err(RelationalError::Sync("NoopConfigStore is read-only".into()))
    }
    async fn get_model_pref(&self, _surface: &str, _lane: &str) -> RelationalResult<Option<ModelPref>> {
        Ok(None)
    }
    async fn upsert_model_pref(&self, _pref: &ModelPref) -> RelationalResult<()> {
        Err(RelationalError::Sync("NoopConfigStore is read-only".into()))
    }
    async fn get_setting(&self, _key: &str) -> RelationalResult<Option<serde_json::Value>> {
        Ok(None)
    }
    async fn set_setting(&self, _key: &str, _value: serde_json::Value) -> RelationalResult<()> {
        Err(RelationalError::Sync("NoopConfigStore is read-only".into()))
    }
}

static AGENT: OnceLock<ChatAgent> = OnceLock::new();

/// Install the real config store / secret resolver. Call once at app startup
/// (frb `init_core`, or the Tauri plugin's `.setup(...)`) before any
/// `chat_send` call, once the platform's `ConfigStore` + `SecretResolver` are
/// available. A no-op (with a debug log) if called after `global()` has
/// already lazily initialised the default — callers should install before the
/// first chat turn, not race it.
pub fn install(config_store: Arc<dyn ConfigStore>, secret_resolver: Arc<dyn SecretResolver>) {
    let agent = ChatAgent::new(config_store, secret_resolver, RunRegistry::new());
    if AGENT.set(agent).is_err() {
        tracing::debug!("gen_ui_agent::state::install called after the ChatAgent was already initialised; ignored");
    }
}

/// Access the process-wide `ChatAgent`, lazily defaulting to the graceful-
/// degrade `NoopConfigStore` + `NoopSecretResolver` pair if `install` was
/// never called.
pub fn global() -> &'static ChatAgent {
    AGENT.get_or_init(|| {
        ChatAgent::new(Arc::new(NoopConfigStore), Arc::new(NoopSecretResolver), RunRegistry::new())
    })
}
