// TJ-ARCH-MOB-001 compliant
//! API key resolution: `providers.api_key_ref` in the config DB is a reference
//! into platform-secure storage, never a plaintext secret. This module resolves
//! that reference to the actual key at call time, immediately before handing it
//! to liter-llm — the key is never persisted in our own process state.
//!
//! Backed by the `keyring` crate: macOS Keychain, Windows Credential Manager,
//! Linux Secret Service, iOS Keychain. NO Android Keystore support yet (tracked
//! upstream: open-source-cooperative/keyring-rs#127) — full secrets
//! administration (write path, Android) is C-109's Settings/admin-UI scope;
//! this module only covers the read path C-103's chat call needs.
use crate::error::AgentError;

const SERVICE: &str = "ai.prometheusags.knowme-poc";

/// Resolve a provider's API key reference to its actual secret value.
pub fn resolve_api_key(api_key_ref: &str) -> Result<String, AgentError> {
    let entry = keyring::Entry::new(SERVICE, api_key_ref)
        .map_err(|e| AgentError::Config(format!("keychain entry for '{api_key_ref}': {e}")))?;
    entry.get_password().map_err(|e| AgentError::Config(format!("keychain read for '{api_key_ref}': {e}")))
}
