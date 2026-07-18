// TJ-ARCH-MOB-001 compliant
//! SyncTransport — local-first sync seam. The DIY Electric-consumer + write-queue
//! (gen_ui_db::sync) implements this; a future prometheus-entity-sync (PES) client
//! can implement the same trait without touching callers.
use crate::error::{CoreError, CoreResult};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum SyncStatus {
    Offline,
    Syncing { pending_writes: u32 },
    Live,
    Error { message: String },
}

/// What a scope replicates. `UserSubset` scopes MUST be tenant-bound; the server
/// re-derives their parameters from the verified JWT (client values are hints,
/// never authority — LFS-INV-7). `SharedLookup` scopes carry server-managed
/// read-only reference data whose currency arrives as version bumps.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ScopeKind {
    UserSubset,
    SharedLookup,
}

/// The tenant-binding parameter every `UserSubset` scope must carry.
pub const SCOPE_TENANT_PARAM: &str = "sub";

/// Privacy class of an entity table (`references/sync/peer-crdt.md`). `Local`
/// data is structurally excluded from every server sync path — the write queue
/// refuses it at enqueue. Unknown tables classify as `Local` (fail closed).
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum PrivacyClass {
    Public,
    Trusted,
    Local,
}

/// Table → privacy-class declarations. Apps declare every server-syncable
/// table explicitly; anything undeclared is `Local` and never enqueues
/// (LFS-INV-4 — the fail-closed default is the security property).
#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq)]
pub struct PrivacyRegistry {
    classes: BTreeMap<String, PrivacyClass>,
}

impl PrivacyRegistry {
    #[must_use]
    pub fn declare(mut self, table: impl Into<String>, class: PrivacyClass) -> Self {
        self.classes.insert(table.into(), class);
        self
    }

    pub fn classify(&self, table: &str) -> PrivacyClass {
        self.classes
            .get(table)
            .copied()
            .unwrap_or(PrivacyClass::Local)
    }
}

/// A declared unit of partial replication (bucket descriptor). See
/// `references/sync/partial-replication.md` — the device never mirrors the
/// server database; it attaches scopes.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SyncScope {
    /// Stable scope id, e.g. `user-tasks`, `lookup-metatypes`.
    pub name: String,
    /// Parameterized-query inputs (allowlisted values, never interpolated SQL).
    pub params: BTreeMap<String, String>,
    pub kind: ScopeKind,
}

impl SyncScope {
    pub fn user_subset(name: impl Into<String>, tenant_sub: impl Into<String>) -> Self {
        let mut params = BTreeMap::new();
        params.insert(SCOPE_TENANT_PARAM.to_string(), tenant_sub.into());
        Self {
            name: name.into(),
            params,
            kind: ScopeKind::UserSubset,
        }
    }

    pub fn shared_lookup(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            params: BTreeMap::new(),
            kind: ScopeKind::SharedLookup,
        }
    }

    /// Fail-closed validation: scope names and parameter values must match the
    /// allowlist `^[a-zA-Z0-9_-]{1,128}$`, and a `UserSubset` scope without a
    /// tenant binding is refused outright (there is no "sync everything" scope).
    pub fn validate(&self) -> CoreResult<()> {
        fn allowed(value: &str) -> bool {
            !value.is_empty()
                && value.len() <= 128
                && value
                    .bytes()
                    .all(|b| b.is_ascii_alphanumeric() || b == b'_' || b == b'-')
        }
        if !allowed(&self.name) {
            return Err(CoreError::Terminal(format!(
                "sync scope name {:?} violates the allowlist",
                self.name
            )));
        }
        for (key, value) in &self.params {
            if !allowed(key) || !allowed(value) {
                return Err(CoreError::Terminal(format!(
                    "sync scope {} has a parameter violating the allowlist",
                    self.name
                )));
            }
        }
        if self.kind == ScopeKind::UserSubset && !self.params.contains_key(SCOPE_TENANT_PARAM) {
            return Err(CoreError::Terminal(format!(
                "user-subset scope {} lacks the tenant parameter {SCOPE_TENANT_PARAM:?} (fail closed)",
                self.name
            )));
        }
        Ok(())
    }
}

#[async_trait]
pub trait SyncTransport: Send + Sync {
    /// Begin read-path sync for a shape/bucket, writing into the local store.
    async fn start(&self) -> CoreResult<()>;
    /// Attach declared scopes, then begin read-path sync. Default delegates to
    /// [`SyncTransport::start`] after validating every scope, so existing
    /// transports keep compiling; scope-aware transports override this.
    async fn start_scopes(&self, scopes: &[SyncScope]) -> CoreResult<()> {
        for scope in scopes {
            scope.validate()?;
        }
        self.start().await
    }
    /// Enqueue a local write for replay through the server API.
    async fn enqueue_write(&self, change_json: &str) -> CoreResult<()>;
    /// Current status (drives the UI sync chip).
    fn status(&self) -> SyncStatus;
}

#[cfg(test)]
mod tests {
    use super::*;

    // Fail-closed contract: a user-subset scope without the tenant param, or any
    // allowlist-violating value, is refused before any transport work happens.
    #[test]
    fn refuses_tenantless_and_malformed_scopes() {
        let tenantless = SyncScope {
            name: "user-tasks".into(),
            params: BTreeMap::new(),
            kind: ScopeKind::UserSubset,
        };
        assert!(tenantless.validate().is_err());

        let injected = SyncScope {
            name: "user-tasks".into(),
            params: BTreeMap::from([(SCOPE_TENANT_PARAM.into(), "u1' OR '1'='1".into())]),
            kind: ScopeKind::UserSubset,
        };
        assert!(injected.validate().is_err());

        assert!(SyncScope::user_subset("user-tasks", "user-42")
            .validate()
            .is_ok());
        assert!(SyncScope::shared_lookup("lookup-metatypes")
            .validate()
            .is_ok());
    }
}
