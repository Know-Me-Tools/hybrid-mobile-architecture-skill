// TJ-ARCH-MOB-001 compliant
//! `GraphStore` — the intent-level API over SurrealDB. Callers (FFI, agent) use
//! `memory_ingest` / `memory_search` / `graph_expand`; SurrealQL never leaves this
//! module.
use crate::embed::{Embedder, EMBED_DIM};
use crate::error::GraphError;
use crate::rrf::{rrf_fuse, RrfConfig};
use crate::schema::{HYBRID_SEARCH_QUERY, SCHEMA_DDL, VECTOR_SEARCH_QUERY};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::OnceCell;
use surrealdb::engine::any::{connect, Any};
use surrealdb::types::SurrealValue;
use surrealdb::Surreal;

/// Where the embedded store lives and how it is embedded.
pub struct GraphStoreConfig {
    /// SurrealDB connection endpoint. Native persistent: `rocksdb://<path>`.
    /// Tests / ephemeral: `memory`. wasm: `indxdb://<name>`.
    pub endpoint: String,
    pub namespace: String,
    pub database: String,
    /// Embedding backend. Behind `Arc` so it can be shared across concurrent calls.
    pub embedder: Arc<dyn Embedder>,
}

/// A memory row as ingested. `id` is `None` on the way in (DB assigns it).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MemoryRecord {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    pub text: String,
    #[serde(default = "default_kind")]
    pub kind: String,
    /// Optional owning entity record id (e.g. `entity:project_x`).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub entity: Option<String>,
}

fn default_kind() -> String {
    "note".to_string()
}

/// One search hit. `score` is always "higher = better", but its SCALE depends on the
/// `SearchMode` that produced it — an RRF score and a vector-similarity score are not
/// comparable magnitudes. Never rank hits from different modes against each other.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MemoryHit {
    pub id: String,
    pub text: String,
    pub kind: String,
    pub score: f32,
}

/// Which retrieval lane `memory_search` runs (C-111 T3).
///
/// Exists so the hybrid lane's advantage is demonstrable rather than asserted: run the
/// same query both ways and watch a rare exact term — a product name, an error code —
/// that vector recall smooths away come back ranked first under fusion.
///
/// Defaults to `Hybrid`: that is the product behaviour, and `Vector` is a diagnostic.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SearchMode {
    /// Vector + BM25, fused with native RRF. The real retrieval path.
    #[default]
    Hybrid,
    /// HNSW vector recall alone — no lexical lane, no fusion. Diagnostic only.
    Vector,
}

/// A neighbour reached by graph expansion, with the RRF score from re-fusing the
/// expansion lanes.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RelatedEntity {
    pub id: String,
    pub label: String,
    pub entity_type: String,
    pub score: f32,
}

// One embedded store per process: native persistent endpoints (`rocksdb://<path>`)
// take an exclusive lock on their data directory, the same way pglite-oxide's
// PgliteServer does for its own data directory (see gen_ui_db's PgliteStore).
// `get_or_try_init` serializes initializers so concurrent `open()` callers await
// the winner's in-flight init instead of racing a second exclusive open; a
// failed init leaves the cell unset so later retries work. This isn't
// load-bearing yet — mobile's FFI boot sequence doesn't call `open()` today —
// but it keeps GraphStore's singleton contract identical to the desktop
// config-DB's before mobile wiring makes it load-bearing.
static GRAPH_STORE: OnceCell<GraphStore> = OnceCell::const_new();

impl GraphStore {
    /// Open (or return/await the already-opening) singleton embedded store for
    /// this process, selecting ns/db and applying the schema on first open.
    /// `cfg` is only honoured by the call that performs the first successful
    /// initialization — later calls ignore it and hand back the existing
    /// handle, since a second endpoint would imply a second store.
    pub async fn open(cfg: GraphStoreConfig) -> Result<Self, GraphError> {
        GRAPH_STORE
            .get_or_try_init(|| async move {
                let model = cfg.embedder.model_info();
                if model.dim != EMBED_DIM {
                    return Err(GraphError::Invalid(format!(
                        "embedder dim {} != index dim {EMBED_DIM} ({})",
                        model.dim, model.name
                    )));
                }
                let db = connect(&cfg.endpoint).await?;
                db.use_ns(&cfg.namespace).use_db(&cfg.database).await?;
                let store = Self { db, embedder: cfg.embedder };
                store.init().await?;
                Ok(store)
            })
            .await
            .cloned()
    }

    async fn init(&self) -> Result<(), GraphError> {
        let mut res = self.db.query(SCHEMA_DDL).await?;
        // DDL errors surface per-statement, not as a query-level Err — surface the
        // first so a bad schema fails loudly at boot instead of at first search.
        if let Some((idx, err)) = res.take_errors().into_iter().next() {
            return Err(GraphError::Surreal(format!("schema stmt {idx}: {err}")));
        }
        Ok(())
    }

    /// Run the (synchronous, CPU-bound) embedder off the async runtime.
    #[cfg(not(target_arch = "wasm32"))]
    async fn embed_blocking(&self, texts: Vec<String>) -> Result<Vec<Vec<f32>>, GraphError> {
        let embedder = Arc::clone(&self.embedder);
        gen_ui_runtime::spawn_blocking(move || embedder.embed(&texts))
            .await
            .map_err(|e| GraphError::Embedding(format!("embed task join: {e}")))?
    }

    /// wasm has no blocking pool (single-threaded, host-supplied JS embedder
    /// per `embed.rs`) — call the embedder inline on the current task.
    #[cfg(target_arch = "wasm32")]
    async fn embed_blocking(&self, texts: Vec<String>) -> Result<Vec<Vec<f32>>, GraphError> {
        self.embedder.embed(&texts)
    }

    /// INTENT: ingest a memory. Embeds `text`, stores row + vector, returns the id.
    pub async fn memory_ingest(&self, record: MemoryRecord) -> Result<String, GraphError> {
        if record.text.trim().is_empty() {
            return Err(GraphError::Invalid("memory text is empty".into()));
        }
        let embedding = self
            .embed_blocking(vec![record.text.clone()])
            .await?
            .into_iter()
            .next()
            .ok_or_else(|| GraphError::Embedding("embedder returned no vector".into()))?;

        let mut res = self
            .db
            .query(
                "CREATE memory SET text = $text, kind = $kind, embedding = $embedding, \
                 entity = IF $entity != NONE THEN type::record($entity) ELSE NONE END \
                 RETURN meta::id(id) AS id;",
            )
            .bind(("text", record.text))
            .bind(("kind", record.kind))
            .bind(("embedding", embedding))
            .bind(("entity", record.entity))
            .await?;
        let ids: Vec<IdRow> = res.take(0)?;
        ids.into_iter()
            .next()
            .map(|r| r.id)
            .ok_or_else(|| GraphError::Surreal("ingest returned no id".into()))
    }

    /// INTENT: create (or upsert) a graph entity node. `id` is the record key
    /// (e.g. `project_x`); `label`/`entity_type` are indexed graph metadata.
    pub async fn create_entity(
        &self,
        id: &str,
        entity_type: &str,
        label: &str,
    ) -> Result<String, GraphError> {
        if id.trim().is_empty() {
            return Err(GraphError::Invalid("entity id is empty".into()));
        }
        let mut res = self
            .db
            .query(
                "UPSERT type::record('entity', $id) \
                 SET entity_type = $etype, label = $label \
                 RETURN meta::id(id) AS id;",
            )
            .bind(("id", id.to_string()))
            .bind(("etype", entity_type.to_string()))
            .bind(("label", label.to_string()))
            .await?;
        let ids: Vec<IdRow> = res.take(0)?;
        ids.into_iter()
            .next()
            .map(|r| r.id)
            .ok_or_else(|| GraphError::Surreal("create_entity returned no id".into()))
    }

    /// INTENT: create a directed RELATE edge `from -> to` with a relation label.
    /// Edges are what `graph_expand` traverses.
    pub async fn relate(&self, from: &str, to: &str, rel: &str) -> Result<(), GraphError> {
        if from.trim().is_empty() || to.trim().is_empty() {
            return Err(GraphError::Invalid("relate endpoints must be non-empty".into()));
        }
        // Endpoints must be PARENTHESIZED. A bare `type::record('entity', $from)`
        // hits RELATE's record-id fallback and dies on `::`; the parens route it to
        // the expression arm instead (syn/parser/stmt/relate.rs `parse_relate_expr`).
        // Do NOT "simplify" to the escaped-ident form `entity:⟨$from⟩` — chevrons are
        // escaped-IDENTIFIER syntax, not interpolation, so that silently relates the
        // literal records `entity:$from`/`entity:$to` and traversal finds nothing.
        self.db
            .query(
                "RELATE (type::record('entity', $from))->relates_to->(type::record('entity', $to)) \
                 SET rel = $rel;",
            )
            .bind(("from", from.to_string()))
            .bind(("to", to.to_string()))
            .bind(("rel", rel.to_string()))
            .await?;
        Ok(())
    }

    /// INTENT: hybrid semantic + lexical search. Embeds `query`, runs the vector
    /// and BM25 lanes, fuses them with native `search::rrf`, returns top-`k`.
    pub async fn memory_search(&self, query: &str, k: usize) -> Result<Vec<MemoryHit>, GraphError> {
        self.memory_search_with(query, k, SearchMode::Hybrid).await
    }

    /// `memory_search`, choosing the retrieval lane (C-111 T3).
    ///
    /// `SearchMode::Vector` skips the BM25 lane and RRF entirely — a diagnostic for
    /// showing what fusion actually buys, not a product path. Scores are comparable
    /// only within a mode; see `MemoryHit::score`.
    pub async fn memory_search_with(
        &self,
        query: &str,
        k: usize,
        mode: SearchMode,
    ) -> Result<Vec<MemoryHit>, GraphError> {
        if query.trim().is_empty() {
            return Err(GraphError::Invalid("search query is empty".into()));
        }
        let qvec = self
            .embed_blocking(vec![query.to_string()])
            .await?
            .into_iter()
            .next()
            .ok_or_else(|| GraphError::Embedding("embedder returned no vector".into()))?;

        match mode {
            SearchMode::Hybrid => {
                let mut res = self
                    .db
                    .query(HYBRID_SEARCH_QUERY)
                    .bind(("qvec", qvec))
                    .bind(("q", query.to_string()))
                    .bind(("k", k as i64))
                    .await?;
                // The SELECT is the last statement in the multi-statement query. Bind
                // the index first — `take(&mut self)` and `num_statements(&self)` can't
                // borrow `res` in the same expression.
                let last = res.num_statements().saturating_sub(1);
                let rows: Vec<HitRow> = res.take(last)?;
                Ok(rows.into_iter().map(HitRow::into_hit).collect())
            }
            SearchMode::Vector => {
                // Single statement, so the rows are at index 0 — no `$q` binding,
                // because with no lexical lane there is nothing to match text against.
                let mut res = self
                    .db
                    .query(VECTOR_SEARCH_QUERY)
                    .bind(("qvec", qvec))
                    .bind(("k", k as i64))
                    .await?;
                let rows: Vec<HitRow> = res.take(0)?;
                Ok(rows.into_iter().map(HitRow::into_hit).collect())
            }
        }
    }

    /// INTENT: expand the graph outward from `entity_id` up to `depth` RELATE hops,
    /// fusing per-depth neighbour lists with Rust RRF (nearer hops rank higher).
    pub async fn graph_expand(
        &self,
        entity_id: &str,
        depth: u8,
    ) -> Result<Vec<RelatedEntity>, GraphError> {
        if depth == 0 {
            return Err(GraphError::Invalid("depth must be >= 1".into()));
        }
        // One lane per hop distance; closer hops fuse to higher RRF scores.
        let mut lanes: Vec<Vec<String>> = Vec::with_capacity(depth as usize);
        let mut frontier = vec![entity_id.to_string()];
        let mut seen = std::collections::HashSet::new();
        seen.insert(entity_id.to_string());

        for _ in 0..depth {
            let mut res = self
                .db
                .query(
                    "SELECT VALUE ->relates_to->entity.map(|$e| meta::id($e)) \
                     FROM $frontier.map(|$id| type::record('entity', $id));",
                )
                .bind(("frontier", frontier.clone()))
                .await?;
            let hops: Vec<Vec<String>> = res.take(0)?;
            let next: Vec<String> = hops
                .into_iter()
                .flatten()
                .filter(|id| seen.insert(id.clone()))
                .collect();
            if next.is_empty() {
                break;
            }
            lanes.push(next.clone());
            frontier = next;
        }

        let fused = rrf_fuse(&lanes, RrfConfig::default());
        if fused.is_empty() {
            return Ok(vec![]);
        }
        // Hydrate the fused ids into labelled entities, preserving fusion order.
        let ids: Vec<String> = fused.iter().map(|(id, _)| id.clone()).collect();
        let mut res = self
            .db
            .query(
                "SELECT meta::id(id) AS id, label, entity_type \
                 FROM entity WHERE meta::id(id) IN $ids;",
            )
            .bind(("ids", ids))
            .await?;
        let rows: Vec<EntityRow> = res.take(0)?;
        let by_id: std::collections::HashMap<String, EntityRow> =
            rows.into_iter().map(|r| (r.id.clone(), r)).collect();
        Ok(fused
            .into_iter()
            .filter_map(|(id, score)| {
                by_id.get(&id).map(|r| RelatedEntity {
                    id: id.clone(),
                    label: r.label.clone(),
                    entity_type: r.entity_type.clone(),
                    score,
                })
            })
            .collect())
    }
}

/// Handle to the embedded SurrealDB plus the shared embedder. Cheap to clone:
/// `Surreal<Any>` and `Arc<dyn Embedder>` are both `Arc`-backed handles, not
/// owning the connection/model themselves.
#[derive(Clone)]
pub struct GraphStore {
    db: Surreal<Any>,
    embedder: Arc<dyn Embedder>,
}

impl GraphStore {
    // config.rs (config-DB CRUD) is a separate `impl GraphStore` block in this
    // same crate, so it needs access to the connection without making `db` a
    // public field on every other consumer of this struct.
    pub(crate) fn db(&self) -> &Surreal<Any> {
        &self.db
    }
}

// SurrealDB 3.2's `IndexedResults::take` deserializes into `SurrealValue`, not
// serde — so the row structs read back from `.query()` derive `SurrealValue`.
// (The public API types — MemoryRecord/MemoryHit/RelatedEntity — stay serde-based
// because they cross the FFI boundary as JSON.) Every field is projected as a
// primitive (`meta::id(id)` → String) so no RecordId handling is needed here.
#[derive(SurrealValue)]
struct IdRow {
    id: String,
}

#[derive(SurrealValue)]
struct HitRow {
    id: String,
    text: String,
    kind: String,
    score: f32,
}

impl HitRow {
    fn into_hit(self) -> MemoryHit {
        MemoryHit { id: self.id, text: self.text, kind: self.kind, score: self.score }
    }
}

#[derive(SurrealValue)]
struct EntityRow {
    id: String,
    label: String,
    entity_type: String,
}