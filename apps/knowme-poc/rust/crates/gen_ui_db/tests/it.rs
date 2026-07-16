// TJ-ARCH-MOB-001 compliant
//! Public-boundary behavior tests for relational startup inputs.

use gen_ui_db::relational::{RelationalError, SeedBundle, SeedSource};

// Regression test for the KnowMe PoC startup crash. React StrictMode
// double-invokes the startup effect in dev, so `run_migrations` fires TWICE
// CONCURRENTLY — with the old check-then-act singleton both callers started a
// `PgliteServer` on the same directory and the loser failed with "PGlite root
// is already in use". `PgliteStore::open` now coalesces concurrent callers via
// `tokio::sync::OnceCell::get_or_try_init`: both racing opens (and any later
// sequential open) must return Ok, sharing one server.
//
// Requires pglite-oxide's runtime assets (the `bundled` feature — enabled by
// this crate's `pglite` feature — or `PGLITE_OXIDE_RUNTIME_ARCHIVE`). Skip
// rather than fail if a stripped build can't resolve them.
#[cfg(feature = "pglite")]
#[tokio::test]
async fn concurrent_and_repeat_opens_share_one_pglite_singleton() {
    let dir = tempfile::tempdir().expect("tempdir");
    let path = dir.path().join("config-db");

    // The StrictMode shape: two opens racing on a cold (never-initialized) root.
    let (a, b) = tokio::join!(
        gen_ui_db::relational::PgliteStore::open(&path),
        gen_ui_db::relational::PgliteStore::open(&path),
    );
    let first = match a {
        Ok(store) => store,
        Err(e) if e.to_string().contains("no embedded PGlite runtime assets") => {
            eprintln!("skipping: {e} (set PGLITE_OXIDE_RUNTIME_ARCHIVE to run this test)");
            return;
        }
        Err(e) => panic!("racing open A must succeed: {e}"),
    };
    let second = b.expect("racing open B must coalesce onto A's init, not lock-contend");

    // And the sequential-repeat shape (a second run_migrations later in life).
    let third = gen_ui_db::relational::PgliteStore::open(&path)
        .await
        .expect("later open must reuse the singleton");

    // All handles share the same underlying pool/server — queries through each
    // prove they are live connections, not stubs.
    for store in [&first, &second, &third] {
        sqlx::query("SELECT 1").execute(store.store().pool()).await.expect("query");
    }
}

#[tokio::test]
async fn bundled_seed_resolves_without_io() {
    let bundle = SeedBundle {
        name: "lookups".to_owned(),
        version: 1,
        source: SeedSource::Bundled("INSERT INTO lookup VALUES (1);"),
    };
    let sql = bundle.sql(&reqwest::Client::new()).await.unwrap();
    assert_eq!(sql, "INSERT INTO lookup VALUES (1);");
}

#[tokio::test]
async fn empty_ipfs_cid_is_rejected_before_network_io() {
    let bundle = SeedBundle {
        name: "lookups".to_owned(),
        version: 1,
        source: SeedSource::Ipfs { cid: " ".to_owned(), gateway: "https://ipfs.io/ipfs".to_owned() },
    };
    let error = bundle.sql(&reqwest::Client::new()).await.unwrap_err();
    assert!(matches!(error, RelationalError::EmptyCid { .. }));
}
