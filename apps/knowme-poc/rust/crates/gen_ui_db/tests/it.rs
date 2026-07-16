// TJ-ARCH-MOB-001 compliant
//! Public-boundary behavior tests for relational startup inputs.

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
