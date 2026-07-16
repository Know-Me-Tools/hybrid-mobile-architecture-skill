// TJ-ARCH-MOB-001 compliant
//! T10 dev-only smoke-test wiring: an in-memory `ConfigStore` + `SecretResolver`
//! pair pointing at a local Ollama instance, gated behind the
//! `GEN_UI_DEV_OLLAMA_MODEL` env var so it never activates unless explicitly
//! opted into. This is NOT the real desktop ConfigStore (that's pglite-oxide,
//! still unwired — see gen_ui_agent::state's doc comment) — it exists solely
//! to prove chat_send -> liter-llm -> chat_subscribe round-trips end-to-end on
//! a local, keyless provider before the real config-store/keychain wiring
//! lands. Delete this module once that wiring exists.
//!
//! liter-llm's Ollama support takes an `ollama/<model>` model-hint string and
//! an empty API key (see the vendored crate's `tests/local_llm.rs`
//! `ollama_client` helper) — no `api_key_ref`/keychain resolution needed for
//! this provider, hence `DevOllamaSecretResolver` always resolves to `""`.
use std::sync::Arc;

use async_trait::async_trait;
use gen_ui_agent::{install_chat_agent, SecretResolver};
use gen_ui_db::relational::{ConfigStore, ModelPref, Provider, RelationalError, RelationalResult};
use gen_ui_types::CoreResult;

const DEV_PROVIDER_ID: &str = "dev-ollama";
const DEV_API_KEY_REF: &str = "dev-ollama-noop";

#[derive(Debug)]
struct DevOllamaConfigStore {
    model_hint: String,
}

#[async_trait]
impl ConfigStore for DevOllamaConfigStore {
    async fn list_providers(&self) -> RelationalResult<Vec<Provider>> {
        Ok(vec![Provider {
            id: DEV_PROVIDER_ID.into(),
            kind: format!("ollama/{}", self.model_hint),
            base_url: std::env::var("OLLAMA_BASE_URL").ok(),
            api_key_ref: Some(DEV_API_KEY_REF.into()),
            enabled: true,
        }])
    }
    async fn upsert_provider(&self, _provider: &Provider) -> RelationalResult<()> {
        Err(RelationalError::Sync("dev Ollama config store is read-only".into()))
    }
    async fn delete_provider(&self, _id: &str) -> RelationalResult<()> {
        Err(RelationalError::Sync("dev Ollama config store is read-only".into()))
    }
    async fn get_model_pref(&self, surface: &str, lane: &str) -> RelationalResult<Option<ModelPref>> {
        if surface != "chat" || lane != "default" {
            return Ok(None);
        }
        Ok(Some(ModelPref {
            surface: surface.into(),
            lane: lane.into(),
            provider_id: Some(DEV_PROVIDER_ID.into()),
            model_id: format!("ollama/{}", self.model_hint),
            params: serde_json::Value::Null,
        }))
    }
    async fn upsert_model_pref(&self, _pref: &ModelPref) -> RelationalResult<()> {
        Err(RelationalError::Sync("dev Ollama config store is read-only".into()))
    }
    async fn get_setting(&self, _key: &str) -> RelationalResult<Option<serde_json::Value>> {
        Ok(None)
    }
    async fn set_setting(&self, _key: &str, _value: serde_json::Value) -> RelationalResult<()> {
        Err(RelationalError::Sync("dev Ollama config store is read-only".into()))
    }
}

#[derive(Debug, Default)]
struct DevOllamaSecretResolver;

#[async_trait]
impl SecretResolver for DevOllamaSecretResolver {
    async fn resolve(&self, api_key_ref: &str) -> CoreResult<String> {
        if api_key_ref == DEV_API_KEY_REF {
            Ok(String::new())
        } else {
            Err(gen_ui_types::CoreError::NotFound(format!(
                "dev Ollama secret resolver only knows '{DEV_API_KEY_REF}', not '{api_key_ref}'"
            )))
        }
    }
}

/// Install the dev Ollama `ConfigStore`/`SecretResolver` if
/// `GEN_UI_DEV_OLLAMA_MODEL` is set (e.g. `deepseek-v4-flash:cloud`). No-op
/// otherwise — the process falls back to `gen_ui_agent::state`'s
/// `NoopConfigStore` graceful-degrade path as normal.
pub fn install_if_requested() {
    let Ok(model_hint) = std::env::var("GEN_UI_DEV_OLLAMA_MODEL") else {
        return;
    };
    log::info!("GEN_UI_DEV_OLLAMA_MODEL set — installing dev Ollama ChatAgent config (model: {model_hint})");
    install_chat_agent(
        Arc::new(DevOllamaConfigStore { model_hint }),
        Arc::new(DevOllamaSecretResolver),
    );
}
