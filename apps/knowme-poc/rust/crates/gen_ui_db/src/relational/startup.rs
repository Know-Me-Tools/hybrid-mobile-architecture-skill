// TJ-ARCH-MOB-001 compliant
//! Typestate startup orchestration (LFS-INV-5): migrations -> seed/lookup ->
//! pre-onboarding load -> [onboarding UI] -> post-onboarding load -> sync attach.
//! The legacy two-hop path (`seed_and_attach`) remains for callers without
//! onboarding stages; the granular path threads a version ledger and scopes.

use std::{marker::PhantomData, sync::Arc};

use gen_ui_types::sync::{SyncScope, SyncTransport};

use super::loads::{run_one_time_loads, LoadResult, LoadStage, OneTimeLoad};
use super::lookup::LookupLedger;
use super::{RelationalResult, SeedBundle};

pub struct Uninitialized;
pub struct Migrated;
/// Seeds + lookups applied; pre-onboarding loads not yet run.
pub struct Seeded;
/// Pre-onboarding loads ran; the app may show onboarding UI now.
pub struct PreOnboarded;
pub struct Ready;

#[async_trait::async_trait]
pub trait StartupStore: Send + Sync {
    async fn migrate(&self) -> RelationalResult<()>;
    async fn execute_seed(&self, sql: &str) -> RelationalResult<()>;
}

pub struct Startup<S, State> {
    store: S,
    http: reqwest::Client,
    _state: PhantomData<State>,
}

impl<S> Startup<S, Uninitialized>
where
    S: StartupStore,
{
    pub fn new(store: S) -> Self {
        Self {
            store,
            http: reqwest::Client::new(),
            _state: PhantomData,
        }
    }

    pub async fn migrate(self) -> RelationalResult<Startup<S, Migrated>> {
        self.store.migrate().await?;
        Ok(Startup {
            store: self.store,
            http: self.http,
            _state: PhantomData,
        })
    }
}

impl<S> Startup<S, Migrated>
where
    S: StartupStore,
{
    pub async fn seed_and_attach(
        self,
        bundles: &[SeedBundle],
        sync: Arc<dyn SyncTransport>,
    ) -> RelationalResult<Startup<S, Ready>> {
        for bundle in bundles {
            let sql = bundle.sql(&self.http).await?;
            self.store.execute_seed(&sql).await?;
        }
        sync.start()
            .await
            .map_err(|error| super::RelationalError::Sync(error.to_string()))?;
        Ok(Startup {
            store: self.store,
            http: self.http,
            _state: PhantomData,
        })
    }
}

impl<S> Startup<S, Migrated>
where
    S: StartupStore,
{
    /// Granular path, step 1: apply seed/lookup bundles (no sync attach yet).
    pub async fn seed(self, bundles: &[SeedBundle]) -> RelationalResult<Startup<S, Seeded>> {
        for bundle in bundles {
            let sql = bundle.sql(&self.http).await?;
            self.store.execute_seed(&sql).await?;
        }
        Ok(Startup {
            store: self.store,
            http: self.http,
            _state: PhantomData,
        })
    }
}

impl<S> Startup<S, Seeded>
where
    S: StartupStore,
{
    /// Granular path, step 2: run pre-onboarding loads (idempotent via ledger).
    /// Returns per-load results alongside the advanced state so the caller can
    /// decide whether any `Deferred` load is boot-critical.
    pub async fn pre_onboarding_load(
        self,
        ledger: &dyn LookupLedger,
        loads: &[OneTimeLoad],
    ) -> RelationalResult<(Startup<S, PreOnboarded>, Vec<LoadResult>)> {
        let results = run_one_time_loads(
            &self.store,
            ledger,
            &self.http,
            loads,
            LoadStage::PreOnboarding,
        )
        .await?;
        Ok((
            Startup {
                store: self.store,
                http: self.http,
                _state: PhantomData,
            },
            results,
        ))
    }
}

impl<S> Startup<S, PreOnboarded>
where
    S: StartupStore,
{
    /// Granular path, step 3: run post-onboarding loads (only when onboarding
    /// has completed — pass `onboarded: false` to skip them; they run on a later
    /// boot once the flag flips), then attach sync with the declared scopes.
    /// Post-onboarding loads never block boot: failures come back `Deferred`.
    pub async fn post_onboarding_and_attach(
        self,
        ledger: &dyn LookupLedger,
        loads: &[OneTimeLoad],
        onboarded: bool,
        sync: Arc<dyn SyncTransport>,
        scopes: &[SyncScope],
    ) -> RelationalResult<(Startup<S, Ready>, Vec<LoadResult>)> {
        let results = if onboarded {
            run_one_time_loads(
                &self.store,
                ledger,
                &self.http,
                loads,
                LoadStage::PostOnboarding,
            )
            .await?
        } else {
            Vec::new()
        };
        sync.start_scopes(scopes)
            .await
            .map_err(|error| super::RelationalError::Sync(error.to_string()))?;
        Ok((
            Startup {
                store: self.store,
                http: self.http,
                _state: PhantomData,
            },
            results,
        ))
    }
}

impl<S> Startup<S, Ready> {
    pub fn into_store(self) -> S {
        self.store
    }
}
