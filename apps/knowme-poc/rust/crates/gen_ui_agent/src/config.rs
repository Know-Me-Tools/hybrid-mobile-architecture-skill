// TJ-ARCH-MOB-001 compliant
//! Platform-agnostic config-DB access. Desktop (Tauri) reads through gen_ui_db's
//! `ConfigStore` trait (pglite-oxide); mobile reads through gen_ui_db_graph's
//! `GraphStore` inherent methods (embedded SurrealDB) — different storage engines,
//! same intent-level shape, so callers (chat::send) never branch on platform.
use std::sync::Arc;

use gen_ui_db::relational::{ConfigStore, ModelPref as PgModelPref, Provider as PgProvider};
use gen_ui_db_graph::{ModelPref as SurrealModelPref, Provider as SurrealProvider};

use crate::error::AgentError;

/// A provider row, normalized across both storage engines.
#[derive(Debug, Clone)]
pub struct Provider {
    pub id: String,
    pub kind: String,
    pub base_url: Option<String>,
    pub api_key_ref: Option<String>,
    pub enabled: bool,
}

impl From<PgProvider> for Provider {
    fn from(p: PgProvider) -> Self {
        Self { id: p.id, kind: p.kind, base_url: p.base_url, api_key_ref: p.api_key_ref, enabled: p.enabled }
    }
}

impl From<SurrealProvider> for Provider {
    fn from(p: SurrealProvider) -> Self {
        Self { id: p.id, kind: p.kind, base_url: p.base_url, api_key_ref: p.api_key_ref, enabled: p.enabled }
    }
}

/// A model preference row, normalized across both storage engines.
#[derive(Debug, Clone)]
pub struct ModelPref {
    pub provider_id: Option<String>,
    pub model_id: String,
}

impl From<PgModelPref> for ModelPref {
    fn from(p: PgModelPref) -> Self {
        Self { provider_id: p.provider_id, model_id: p.model_id }
    }
}

impl From<SurrealModelPref> for ModelPref {
    fn from(p: SurrealModelPref) -> Self {
        Self { provider_id: p.provider_id, model_id: p.model_id }
    }
}

/// One config backend per platform, selected once at startup and held for the
/// process lifetime (see `crate::state`).
pub enum ConfigBackend {
    Postgres(Arc<dyn ConfigStore>),
    Surreal(Arc<gen_ui_db_graph::GraphStore>),
}

impl ConfigBackend {
    pub async fn get_model_pref(&self, surface: &str, lane: &str) -> Result<Option<ModelPref>, AgentError> {
        match self {
            ConfigBackend::Postgres(store) => Ok(store
                .get_model_pref(surface, lane)
                .await
                .map_err(|e| AgentError::Config(e.to_string()))?
                .map(ModelPref::from)),
            ConfigBackend::Surreal(store) => Ok(store
                .get_model_pref(surface, lane)
                .await
                .map_err(|e| AgentError::Config(e.to_string()))?
                .map(ModelPref::from)),
        }
    }

    pub async fn get_provider(&self, id: &str) -> Result<Option<Provider>, AgentError> {
        match self {
            ConfigBackend::Postgres(store) => Ok(store
                .list_providers()
                .await
                .map_err(|e| AgentError::Config(e.to_string()))?
                .into_iter()
                .find(|p| p.id == id)
                .map(Provider::from)),
            ConfigBackend::Surreal(store) => Ok(store
                .list_providers()
                .await
                .map_err(|e| AgentError::Config(e.to_string()))?
                .into_iter()
                .find(|p| p.id == id)
                .map(Provider::from)),
        }
    }
}
