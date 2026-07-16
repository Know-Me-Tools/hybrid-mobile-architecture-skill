// TJ-ARCH-MOB-001 compliant
//! Secret resolution seam. `ConfigStore::Provider::api_key_ref` is a reference
//! into platform-secure storage (keychain on desktop/mobile), never a plaintext
//! secret — resolving that reference into the actual key is a platform concern
//! this crate does not implement.
//!
//! DESIGN NOTE (T6, ambiguous in spec): no keychain integration exists anywhere
//! in the workspace yet (verified via grep before adding this). Building real
//! keychain access is out of scope for T6/T7 — the acceptance bar is a
//! documented seam + graceful "no provider configured" degrade. gen_ui_ffi
//! (mobile) and tauri-plugin-gen-ui (desktop) each own a platform and should
//! inject a concrete `SecretResolver` (iOS/Android Keystore, macOS/Windows/Linux
//! keychain) when that lands; until then `NoopSecretResolver` always reports
//! "not found", which drives the graceful-degrade path in `chat.rs`.

use async_trait::async_trait;
use gen_ui_types::CoreResult;

/// Resolves a provider's `api_key_ref` (an opaque reference stored in the config
/// DB) into the actual secret value held in platform-secure storage.
#[async_trait]
pub trait SecretResolver: Send + Sync {
    /// Resolve `api_key_ref` into the live secret. Returns `CoreError::NotFound`
    /// when the reference does not resolve to a stored secret (e.g. the user
    /// has not yet entered a key for this provider).
    async fn resolve(&self, api_key_ref: &str) -> CoreResult<String>;
}

/// Default resolver used until a platform-specific keychain integration is
/// wired in by a downstream crate. Always reports the secret as absent, which
/// is the correct behavior for graceful degrade (never a hardcoded key/env var
/// fallback).
#[derive(Debug, Default, Clone, Copy)]
pub struct NoopSecretResolver;

#[async_trait]
impl SecretResolver for NoopSecretResolver {
    async fn resolve(&self, api_key_ref: &str) -> CoreResult<String> {
        Err(gen_ui_types::CoreError::NotFound(format!(
            "no secret resolver configured for api_key_ref '{api_key_ref}' \
             (platform keychain integration not yet wired)"
        )))
    }
}
