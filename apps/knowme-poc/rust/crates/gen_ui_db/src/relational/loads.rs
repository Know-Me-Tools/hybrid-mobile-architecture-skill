// TJ-ARCH-MOB-001 compliant
//! One-time data loads (C-122): certain data loads from the server exactly once,
//! at two well-defined boot moments — before onboarding (anonymous-safe manifest,
//! catalogs) and after onboarding (preference-driven personalization seeds).
//! Idempotent via a ledger: a load runs only when its ledger entry is absent or
//! older. A failed post-onboarding load degrades (retry next boot) — it must
//! never block the user. See `references/sync/partial-replication.md` §3.

use super::lookup::{LookupLedger, LookupVersion};
use super::seed::SeedBundle;
use super::startup::StartupStore;
use super::RelationalResult;

/// DDL for the store-backed load ledger (additive, LFS-INV-3). Ledger entries
/// share the version-ledger seam ([`LookupLedger`]) with lookups; store-backed
/// impls keep loads in their own table.
pub const LOAD_LEDGER_DDL: &str = "CREATE TABLE IF NOT EXISTS _load_ledger (\n  load_name TEXT PRIMARY KEY,\n  version INTEGER NOT NULL,\n  completed_at TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP)\n)";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LoadStage {
    PreOnboarding,
    PostOnboarding,
}

/// A ledgered one-time load: a seed bundle bound to a boot stage.
#[derive(Debug, Clone)]
pub struct OneTimeLoad {
    pub stage: LoadStage,
    pub bundle: SeedBundle,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum LoadResult {
    /// Ledger already current — nothing ran.
    AlreadyLoaded { name: String },
    /// Load executed and ledgered.
    Loaded { name: String, version: u32 },
    /// Load failed; ledger untouched so it retries next boot. Post-onboarding
    /// failures surface here instead of erroring the whole boot (degrade rule).
    Deferred { name: String, error: String },
}

/// Run every load for `stage`, idempotently. Pre-onboarding failures are
/// returned as `Deferred` too — the caller decides whether a load is
/// boot-critical (then treat `Deferred` as fatal) or degradable (default).
pub async fn run_one_time_loads<S: StartupStore>(
    store: &S,
    ledger: &dyn LookupLedger,
    client: &reqwest::Client,
    loads: &[OneTimeLoad],
    stage: LoadStage,
) -> RelationalResult<Vec<LoadResult>> {
    let mut results = Vec::new();
    for load in loads.iter().filter(|l| l.stage == stage) {
        let name = load.bundle.name.clone();
        let prior = ledger.get(&name).await?;
        if prior
            .map(|p| p.version >= load.bundle.version)
            .unwrap_or(false)
        {
            results.push(LoadResult::AlreadyLoaded { name });
            continue;
        }
        match load.bundle.sql(client).await {
            Ok(sql) => match store.execute_seed(&sql).await {
                Ok(()) => {
                    ledger
                        .put(&LookupVersion {
                            name: name.clone(),
                            version: load.bundle.version,
                            etag: None,
                        })
                        .await?;
                    results.push(LoadResult::Loaded {
                        name,
                        version: load.bundle.version,
                    });
                }
                Err(error) => results.push(LoadResult::Deferred {
                    name,
                    error: error.to_string(),
                }),
            },
            Err(error) => results.push(LoadResult::Deferred {
                name,
                error: error.to_string(),
            }),
        }
    }
    Ok(results)
}

#[cfg(test)]
mod tests {
    use super::super::lookup::MemoryLookupLedger;
    use super::super::seed::{SeedBundle, SeedSource};
    use super::super::startup::StartupStore;
    use super::super::{RelationalError, RelationalResult};
    use super::*;
    use std::sync::Mutex;

    struct MemStore {
        executed: Mutex<Vec<String>>,
        fail: bool,
    }

    #[async_trait::async_trait]
    impl StartupStore for MemStore {
        async fn migrate(&self) -> RelationalResult<()> {
            Ok(())
        }
        async fn execute_seed(&self, sql: &str) -> RelationalResult<()> {
            if self.fail {
                return Err(RelationalError::Sync("store down".into()));
            }
            self.executed.lock().expect("lock").push(sql.to_string());
            Ok(())
        }
    }

    fn load(stage: LoadStage, name: &str) -> OneTimeLoad {
        OneTimeLoad {
            stage,
            bundle: SeedBundle {
                name: name.into(),
                version: 1,
                source: SeedSource::Bundled("INSERT INTO seeded VALUES (1)"),
            },
        }
    }

    // One-time semantics: a load runs exactly once per version, filtered by stage.
    #[tokio::test]
    async fn loads_run_once_per_version_and_stage() {
        let store = MemStore {
            executed: Mutex::new(Vec::new()),
            fail: false,
        };
        let ledger = MemoryLookupLedger::default();
        let client = reqwest::Client::new();
        let loads = [
            load(LoadStage::PreOnboarding, "manifest"),
            load(LoadStage::PostOnboarding, "personalization"),
        ];

        let pre = run_one_time_loads(&store, &ledger, &client, &loads, LoadStage::PreOnboarding)
            .await
            .expect("pre");
        assert_eq!(
            pre,
            vec![LoadResult::Loaded {
                name: "manifest".into(),
                version: 1
            }]
        );

        let rerun = run_one_time_loads(&store, &ledger, &client, &loads, LoadStage::PreOnboarding)
            .await
            .expect("rerun");
        assert_eq!(
            rerun,
            vec![LoadResult::AlreadyLoaded {
                name: "manifest".into()
            }]
        );
        assert_eq!(store.executed.lock().expect("lock").len(), 1);
    }

    // Degrade rule: a failing load defers (ledger untouched) so it retries next boot.
    #[tokio::test]
    async fn failing_load_defers_and_retries_next_boot() {
        let failing = MemStore {
            executed: Mutex::new(Vec::new()),
            fail: true,
        };
        let ledger = MemoryLookupLedger::default();
        let client = reqwest::Client::new();
        let loads = [load(LoadStage::PostOnboarding, "personalization")];

        let result = run_one_time_loads(
            &failing,
            &ledger,
            &client,
            &loads,
            LoadStage::PostOnboarding,
        )
        .await
        .expect("deferred, not fatal");
        assert!(matches!(result[0], LoadResult::Deferred { .. }));

        let healthy = MemStore {
            executed: Mutex::new(Vec::new()),
            fail: false,
        };
        let retry = run_one_time_loads(
            &healthy,
            &ledger,
            &client,
            &loads,
            LoadStage::PostOnboarding,
        )
        .await
        .expect("retry");
        assert!(matches!(retry[0], LoadResult::Loaded { .. }));
    }
}
