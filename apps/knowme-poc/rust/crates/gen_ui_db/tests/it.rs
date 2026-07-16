// TJ-ARCH-MOB-001 compliant
//! Public-boundary behavior tests for relational startup inputs and SQLite+vec.

use gen_ui_db::relational::{RelationalError, SeedBundle, SeedSource};

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

#[cfg(feature = "sqlite")]
#[tokio::test]
async fn sqlite_store_loads_vec_extension() {
    use gen_ui_db::relational::SqliteStore;

    let directory = tempfile::tempdir().unwrap();
    let store = SqliteStore::open(directory.path().join("app.sqlite")).await.unwrap();
    let version: String = sqlx::query_scalar("SELECT vec_version()")
        .fetch_one(store.pool())
        .await
        .unwrap();
    assert!(version.starts_with('v'));
}
