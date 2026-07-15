// TJ-ARCH-MOB-001 compliant
//! db_wasm_spike — c002 probe: does SurrealDB 3.2 `kv-indxdb` compile to
//! wasm32-unknown-unknown, and does the intent-level API surface (connect,
//! DEFINE INDEX HNSW, RELATE, query) type-check on that target?
//!
//! This is a COMPILE probe, not a runtime test — kv-indxdb needs a real browser
//! IndexedDB, so it cannot run under a bare `cargo test`. The value is proving the
//! dep tree resolves and the query API is target-safe before C-004 commits to it.
use surrealdb::engine::any::{connect, Any};
use surrealdb::Surreal;

/// Open an IndexedDB-backed SurrealDB instance in the browser.
/// `indxdb://<name>` selects the kv-indxdb engine (analysis §1.3).
pub async fn open_graph(db_name: &str) -> surrealdb::Result<Surreal<Any>> {
    let db = connect(format!("indxdb://{db_name}")).await?;
    db.use_ns("gen_ui").use_db("graph").await?;
    Ok(db)
}

/// Define the graph-RAG schema exactly as C-004 will: HNSW 384-dim vector index
/// + FULLTEXT BM25 index. Proves the 3.x DDL string round-trips through the wasm
/// query path (no native-only codepath in the parser/planner for these).
pub async fn define_schema(db: &Surreal<Any>) -> surrealdb::Result<()> {
    db.query(
        "
        DEFINE TABLE IF NOT EXISTS entity SCHEMALESS;
        DEFINE FIELD IF NOT EXISTS embedding ON entity TYPE array<float>;
        DEFINE INDEX IF NOT EXISTS entity_hnsw ON entity
            FIELDS embedding HNSW DIMENSION 384 DIST COSINE;
        DEFINE ANALYZER IF NOT EXISTS bm25 TOKENIZERS class FILTERS lowercase,ascii;
        DEFINE INDEX IF NOT EXISTS entity_ft ON entity
            FIELDS content FULLTEXT ANALYZER bm25 BM25;
        ",
    )
    .await?;
    Ok(())
}

/// Vector recall via the KNN operator `<|K,EF|>` (3.x syntax). Takes the result
/// out as `surrealdb::types::Value` — the always-valid target on 3.x. FINDING for C-004:
/// `.take::<R>()` bounds `R: SurrealValue` (SurrealDB's own trait), NOT plain
/// `serde::Deserialize`. Typed structs must `#[derive(SurrealValue)]`; a raw
/// `serde_json::Value` is rejected. C-004 either derives SurrealValue on its
/// entity model or converts from `surrealdb::types::Value`.
pub async fn vector_recall(
    db: &Surreal<Any>,
    query_vec: Vec<f32>,
    k: usize,
) -> surrealdb::Result<surrealdb::types::Value> {
    let mut res = db
        .query("SELECT id, content FROM entity WHERE embedding <|$k,64|> $vec")
        .bind(("k", k))
        .bind(("vec", query_vec))
        .await?;
    let rows: surrealdb::types::Value = res.take(0)?;
    Ok(rows)
}
