// TJ-ARCH-MOB-001 compliant
//! C-127: mobile's sync `LocalStore` — the [`gen_ui_db::sync::LocalStore`] seam
//! implemented over the SAME embedded SurrealDB instance `GraphStore` already
//! opens (`ConfigBackend::Surreal`, see `gen_ui_ffi::api::boot::run_migrations`).
//! Deliberately NOT part of `store.rs`'s intent-level API (`memory_ingest` /
//! `memory_search` / `graph_expand`): this is the frozen sync seam's contract
//! (row-batch apply, shape truncate), a distinct concern with its own narrow
//! table, following exactly the boundary `SqliteEntityStore` draws for entity
//! envelopes on the same platform. Native-only — mirrors `gen_ui_db::sync`'s
//! own wasm32 no-op stub (SurrealDB itself still runs on wasm32 for the
//! memory/graph lane, but the sync write-queue/read-lane machinery this seam
//! serves does not exist in-browser).
use async_trait::async_trait;
use gen_ui_db::sync::{LocalStore, RowChange, RowOp};
use gen_ui_types::error::{CoreError, CoreResult};
use surrealdb::engine::any::Any;
use surrealdb::Surreal;

/// DDL for the sync row table. Applied once at boot alongside `SCHEMA_DDL`
/// (additive, LFS-INV-3) — a flat `(table, key) -> value_json` envelope,
/// mirroring `SqliteEntityStore`'s `entity_records` shape so both mobile
/// stores share one mental model.
pub const SYNC_ROWS_DDL: &str = r#"
DEFINE TABLE IF NOT EXISTS sync_rows SCHEMALESS;
DEFINE FIELD IF NOT EXISTS table_name ON sync_rows TYPE string;
DEFINE FIELD IF NOT EXISTS row_key ON sync_rows TYPE string;
DEFINE FIELD IF NOT EXISTS value_json ON sync_rows TYPE string;
DEFINE INDEX IF NOT EXISTS sync_rows_table_key ON sync_rows FIELDS table_name, row_key UNIQUE;
"#;

/// Table names this store is allowed to write (security boundary, not
/// tidiness — mirrors `PgLocalStore::SYNCED_TABLES`'s reasoning exactly: an
/// unknown table is [`CoreError::Terminal`], never silently skipped).
const SYNCED_TABLES: &[&str] = &["notes", "memories"];

fn check_table(table: &str) -> CoreResult<&'static str> {
    SYNCED_TABLES
        .iter()
        .find(|t| **t == table)
        .copied()
        .ok_or_else(|| CoreError::Terminal(format!("table not syncable: {table}")))
}

/// Composite record id: SurrealDB record ids must be a single string/number
/// per table, so `table_name` + `row_key` are joined rather than used as two
/// separate id components.
fn record_key(table: &str, key: &str) -> String {
    format!("{table}::{key}")
}

pub struct SurrealLocalStore {
    db: Surreal<Any>,
}

impl SurrealLocalStore {
    /// Wrap an already-open SurrealDB connection (the same one `GraphStore`
    /// opened at boot — one embedded store per process, never a second one).
    /// `pub(crate)`: external callers go through [`crate::GraphStore::local_store`],
    /// which is the only place outside this crate allowed to reach the raw
    /// connection (see the crate's INTENT-LEVEL boundary in lib.rs).
    pub(crate) fn new(db: Surreal<Any>) -> Self {
        Self { db }
    }

    pub async fn ensure_schema(&self) -> CoreResult<()> {
        self.db
            .query(SYNC_ROWS_DDL)
            .await
            .map_err(|e| CoreError::Io(e.to_string()))?;
        Ok(())
    }
}

#[async_trait]
impl LocalStore for SurrealLocalStore {
    async fn apply_batch(&self, changes: &[RowChange]) -> CoreResult<()> {
        // One statement per row inside SurrealDB's implicit per-query
        // transaction — matches PgLocalStore's "one transaction per batch"
        // invariant: the store is only ever consistent at a batch boundary.
        for change in changes {
            check_table(&change.table)?;
            let id = record_key(&change.table, &change.key);
            match change.op {
                RowOp::Insert | RowOp::Update => {
                    self.db
                        .query(
                            "UPSERT type::record('sync_rows', $id) \
                             SET table_name = $table, row_key = $key, value_json = $value;",
                        )
                        .bind(("id", id))
                        .bind(("table", change.table.clone()))
                        .bind(("key", change.key.clone()))
                        .bind(("value", change.value_json.clone()))
                        .await
                        .map_err(|e| CoreError::Io(e.to_string()))?;
                }
                RowOp::Delete => {
                    self.db
                        .query("DELETE type::record('sync_rows', $id);")
                        .bind(("id", id))
                        .await
                        .map_err(|e| CoreError::Io(e.to_string()))?;
                }
            }
        }
        Ok(())
    }

    async fn truncate_shape(&self, table: &str) -> CoreResult<()> {
        check_table(table)?;
        self.db
            .query("DELETE FROM sync_rows WHERE table_name = $table;")
            .bind(("table", table.to_string()))
            .await
            .map_err(|e| CoreError::Io(e.to_string()))?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use surrealdb::engine::any::connect;

    async fn open_mem() -> Surreal<Any> {
        let db = connect("memory").await.expect("connect memory surreal");
        db.use_ns("test").use_db("test").await.expect("use ns/db");
        db
    }

    fn row(table: &str, key: &str, value: &str) -> RowChange {
        RowChange {
            table: table.to_string(),
            op: RowOp::Insert,
            key: key.to_string(),
            value_json: value.to_string(),
        }
    }

    // Boundary behavior: apply_batch persists rows retrievably, and an unknown
    // table is refused (fail closed) rather than silently accepted.
    #[tokio::test]
    async fn applies_batch_and_refuses_unknown_tables() {
        let db = open_mem().await;
        let store = SurrealLocalStore::new(db.clone());
        store.ensure_schema().await.expect("schema");

        store
            .apply_batch(&[row("notes", "n1", r#"{"id":"n1","title":"A"}"#)])
            .await
            .expect("apply known table");

        let unknown = store.apply_batch(&[row("secrets", "s1", "{}")]).await;
        assert!(unknown.is_err());
    }

    // Delete removes the row; truncate_shape clears everything for one table
    // without touching another (re-materialization must not cross tables).
    #[tokio::test]
    async fn delete_and_truncate_are_scoped_per_table() {
        let db = open_mem().await;
        let store = SurrealLocalStore::new(db.clone());
        store.ensure_schema().await.expect("schema");

        store
            .apply_batch(&[
                row("notes", "n1", r#"{"id":"n1"}"#),
                row("memories", "m1", r#"{"id":"m1"}"#),
            ])
            .await
            .expect("seed both tables");

        store.truncate_shape("notes").await.expect("truncate notes");

        let mut result = db
            .query("SELECT table_name FROM sync_rows;")
            .await
            .expect("query remaining rows");
        let remaining: Vec<String> = result
            .take::<Vec<serde_json::Value>>(0)
            .expect("rows")
            .into_iter()
            .filter_map(|v| {
                v.get("table_name")
                    .and_then(|t| t.as_str())
                    .map(str::to_string)
            })
            .collect();
        assert_eq!(remaining, vec!["memories"]);
    }
}
