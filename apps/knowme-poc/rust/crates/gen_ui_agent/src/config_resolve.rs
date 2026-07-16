// TJ-ARCH-MOB-001 compliant
//! Resolve which provider + model a chat turn should use from the config DB
//! (`gen_ui_db::relational::ConfigStore`, desktop/web backend — see the
//! `ChatAgent` doc comment in `chat.rs` for the mobile-backend follow-up note).

use gen_ui_db::relational::{ConfigStore, ModelPref, Provider};
use gen_ui_types::{CoreError, CoreResult};

use crate::error::from_relational;

/// Model-preference surface used for the chat feature. Kept as a constant
/// (Rule 29: no stringly-typed hacks) so every caller reads/writes the same
/// (surface, lane) pair; a real lane taxonomy (e.g. per-conversation-mode
/// lanes) is speculative until a second lane exists (YAGNI).
pub const CHAT_SURFACE: &str = "chat";
pub const CHAT_LANE: &str = "default";

/// Resolved (provider, model, model_pref) ready to build a liter-llm client.
pub struct ResolvedModel {
    pub provider: Provider,
    pub model_pref: ModelPref,
}

/// Resolve the enabled provider + model preference for the chat surface.
///
/// Graceful-degrade contract (T6): returns `CoreError::Terminal` with a clear
/// message — never panics, never falls back to a hardcoded key/provider — when:
///   * no model_pref is configured for (chat, default),
///   * the model_pref references a provider_id that isn't configured, or
///   * the referenced provider is configured but not `enabled`.
pub async fn resolve_chat_model(store: &dyn ConfigStore) -> CoreResult<ResolvedModel> {
    let model_pref = store
        .get_model_pref(CHAT_SURFACE, CHAT_LANE)
        .await
        .map_err(from_relational)?
        .ok_or_else(|| {
            CoreError::Terminal(
                "no provider configured: no model preference set for the chat surface".into(),
            )
        })?;

    let provider_id = model_pref.provider_id.clone().ok_or_else(|| {
        CoreError::Terminal(
            "no provider configured: chat model preference has no provider_id".into(),
        )
    })?;

    let providers = store.list_providers().await.map_err(from_relational)?;
    let provider = providers
        .into_iter()
        .find(|p| p.id == provider_id)
        .ok_or_else(|| {
            CoreError::Terminal(format!(
                "no provider configured: provider_id '{provider_id}' referenced by the chat \
                 model preference does not exist"
            ))
        })?;

    if !provider.enabled {
        return Err(CoreError::Terminal(format!(
            "no provider configured: provider '{provider_id}' is disabled"
        )));
    }

    Ok(ResolvedModel { provider, model_pref })
}
