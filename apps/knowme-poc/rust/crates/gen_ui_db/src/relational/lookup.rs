// TJ-ARCH-MOB-001 compliant
//! Lookup/metatype currency (C-122). Shared lookup data is fetched as versioned
//! bundles and must STAY current: re-validate with `If-None-Match` on boot, and
//! re-fetch when a version bump arrives through the sync stream (a row on
//! `_lookup_versions` — currency events are just synced rows). See
//! `references/sync/partial-replication.md` §2.
//!
//! Storage seam: [`LookupLedger`] records what version/etag each bundle last
//! applied. Slices/tests use [`MemoryLookupLedger`]; store-backed ledgers
//! implement the same trait next to their `StartupStore`.

use super::seed::{SeedBundle, SeedSource};
use super::startup::StartupStore;
use super::{RelationalError, RelationalResult};
use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::Mutex;

/// DDL for the local ledger table (additive, LFS-INV-3). Stores apply this in
/// their migration set; the sync stream may also deliver bump rows into it.
pub const LOOKUP_VERSIONS_DDL: &str = "CREATE TABLE IF NOT EXISTS _lookup_versions (\n  name TEXT PRIMARY KEY,\n  version INTEGER NOT NULL,\n  etag TEXT,\n  applied_at TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP)\n)";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LookupVersion {
    pub name: String,
    pub version: u32,
    pub etag: Option<String>,
}

#[async_trait]
pub trait LookupLedger: Send + Sync {
    async fn get(&self, name: &str) -> RelationalResult<Option<LookupVersion>>;
    async fn put(&self, entry: &LookupVersion) -> RelationalResult<()>;
}

/// In-memory ledger for slices and boundary tests.
#[derive(Default)]
pub struct MemoryLookupLedger {
    entries: Mutex<HashMap<String, LookupVersion>>,
}

#[async_trait]
impl LookupLedger for MemoryLookupLedger {
    async fn get(&self, name: &str) -> RelationalResult<Option<LookupVersion>> {
        Ok(self.entries.lock().expect("ledger lock").get(name).cloned())
    }
    async fn put(&self, entry: &LookupVersion) -> RelationalResult<()> {
        self.entries
            .lock()
            .expect("ledger lock")
            .insert(entry.name.clone(), entry.clone());
        Ok(())
    }
}

/// Outcome of one revalidation pass for one bundle.
#[derive(Debug, PartialEq, Eq)]
pub enum LookupOutcome {
    /// Ledger already at/above the bundle's version, or server said 304.
    Current,
    /// Bundle content applied; ledger advanced to this version.
    Applied { version: u32 },
}

/// Re-validate one lookup bundle and apply it if it changed.
///
/// - `Bundled` sources compare versions only (no network).
/// - `Http`/`Ipfs` sources send the ledger's etag as `If-None-Match`; a 304
///   keeps the current content and just advances the ledger's version marker.
/// - Application is atomic per bundle: content lands via one
///   [`StartupStore::execute_seed`] call (bundle SQL is authored transactional).
pub async fn revalidate_lookup<S: StartupStore>(
    store: &S,
    ledger: &dyn LookupLedger,
    client: &reqwest::Client,
    bundle: &SeedBundle,
) -> RelationalResult<LookupOutcome> {
    let prior = ledger.get(&bundle.name).await?;
    if let Some(prior) = &prior {
        if prior.version >= bundle.version {
            return Ok(LookupOutcome::Current);
        }
    }

    let (sql, etag) = match &bundle.source {
        SeedSource::Bundled(sql) => ((*sql).to_owned(), None),
        _ => {
            let prior_etag = prior.as_ref().and_then(|p| p.etag.clone());
            match fetch_if_changed(client, bundle, prior_etag.as_deref()).await? {
                FetchIfChanged::NotModified => {
                    ledger
                        .put(&LookupVersion {
                            name: bundle.name.clone(),
                            version: bundle.version,
                            etag: prior_etag,
                        })
                        .await?;
                    return Ok(LookupOutcome::Current);
                }
                FetchIfChanged::Fetched { sql, etag } => (sql, etag),
            }
        }
    };

    store.execute_seed(&sql).await?;
    ledger
        .put(&LookupVersion {
            name: bundle.name.clone(),
            version: bundle.version,
            etag,
        })
        .await?;
    Ok(LookupOutcome::Applied {
        version: bundle.version,
    })
}

/// A version bump observed on the sync stream: does it require a refetch?
/// (Pure decision helper so transports/UI need no ledger access to answer.)
pub fn bump_needs_refetch(prior: Option<&LookupVersion>, bumped_to: u32) -> bool {
    prior.map(|p| p.version < bumped_to).unwrap_or(true)
}

enum FetchIfChanged {
    NotModified,
    Fetched { sql: String, etag: Option<String> },
}

async fn fetch_if_changed(
    client: &reqwest::Client,
    bundle: &SeedBundle,
    prior_etag: Option<&str>,
) -> RelationalResult<FetchIfChanged> {
    let url = match &bundle.source {
        SeedSource::Bundled(_) => unreachable!("bundled sources never fetch"),
        SeedSource::Http { url } => url.clone(),
        SeedSource::Ipfs { cid, gateway } => {
            if cid.trim().is_empty() {
                return Err(RelationalError::EmptyCid {
                    name: bundle.name.clone(),
                });
            }
            format!("{}/{cid}", gateway.trim_end_matches('/'))
        }
    };

    let mut request = client.get(&url);
    if let Some(etag) = prior_etag {
        request = request.header(reqwest::header::IF_NONE_MATCH, etag);
    }
    let response = request
        .send()
        .await
        .map_err(|source| RelationalError::SeedFetch {
            name: bundle.name.clone(),
            source,
        })?;

    if response.status() == reqwest::StatusCode::NOT_MODIFIED {
        return Ok(FetchIfChanged::NotModified);
    }
    let response = response
        .error_for_status()
        .map_err(|source| RelationalError::SeedFetch {
            name: bundle.name.clone(),
            source,
        })?;
    let etag = response
        .headers()
        .get(reqwest::header::ETAG)
        .and_then(|v| v.to_str().ok())
        .map(str::to_owned);
    let bytes = response
        .bytes()
        .await
        .map_err(|source| RelationalError::SeedFetch {
            name: bundle.name.clone(),
            source,
        })?;
    let sql = std::str::from_utf8(&bytes)
        .map(str::to_owned)
        .map_err(|source| RelationalError::SeedEncoding {
            name: bundle.name.clone(),
            source,
        })?;
    Ok(FetchIfChanged::Fetched { sql, etag })
}

#[cfg(test)]
mod tests {
    use super::super::seed::{SeedBundle, SeedSource};
    use super::super::startup::StartupStore;
    use super::super::RelationalResult;
    use super::*;

    #[derive(Default)]
    struct MemStore {
        executed: Mutex<Vec<String>>,
    }

    #[async_trait]
    impl StartupStore for MemStore {
        async fn migrate(&self) -> RelationalResult<()> {
            Ok(())
        }
        async fn execute_seed(&self, sql: &str) -> RelationalResult<()> {
            self.executed.lock().expect("lock").push(sql.to_string());
            Ok(())
        }
    }

    fn bundle(version: u32) -> SeedBundle {
        SeedBundle {
            name: "metatypes".into(),
            version,
            source: SeedSource::Bundled("INSERT INTO metatypes VALUES ('t1')"),
        }
    }

    // Currency loop: first pass applies and ledgers; same version is Current
    // (no reapply); a bumped version applies again.
    #[tokio::test]
    async fn revalidate_applies_once_then_tracks_versions() {
        let store = MemStore::default();
        let ledger = MemoryLookupLedger::default();
        let client = reqwest::Client::new();

        let first = revalidate_lookup(&store, &ledger, &client, &bundle(1))
            .await
            .expect("v1");
        assert_eq!(first, LookupOutcome::Applied { version: 1 });
        let again = revalidate_lookup(&store, &ledger, &client, &bundle(1))
            .await
            .expect("v1 again");
        assert_eq!(again, LookupOutcome::Current);
        assert_eq!(store.executed.lock().expect("lock").len(), 1);

        let bumped = revalidate_lookup(&store, &ledger, &client, &bundle(2))
            .await
            .expect("v2");
        assert_eq!(bumped, LookupOutcome::Applied { version: 2 });
        assert_eq!(store.executed.lock().expect("lock").len(), 2);
    }

    #[test]
    fn bump_decision_is_monotonic() {
        let prior = LookupVersion {
            name: "metatypes".into(),
            version: 3,
            etag: None,
        };
        assert!(!bump_needs_refetch(Some(&prior), 3));
        assert!(bump_needs_refetch(Some(&prior), 4));
        assert!(bump_needs_refetch(None, 1));
    }
}
