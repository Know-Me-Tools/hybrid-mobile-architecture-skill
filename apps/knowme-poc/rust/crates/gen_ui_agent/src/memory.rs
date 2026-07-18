// TJ-ARCH-MOB-001 compliant
//! Shared memory/graph-RAG implementation. Called identically from gen_ui_ffi
//! (mobile, via frb) and tauri-plugin-gen-ui (desktop, via Tauri IPC) — both
//! platforms share the SAME embedded SurrealDB GraphStore instance shape (see
//! `state::init`'s doc comment on why this is not tied to `ConfigBackend`).
use std::sync::Arc;

use gen_ui_db::rag::{RagEngine, RetrievalQuery, RetrievalScope, RetrievedChunk};
use gen_ui_db_graph::{
    GraphRagEmbedder, GraphVectorStore, MemoryHit, MemoryRecord, RelatedEntity, SearchMode,
};
use tokio::sync::OnceCell;

use crate::error::AgentError;
use crate::state;

/// Ingest a note into memory (embeds on-device via fastembed, upserts into
/// SurrealDB). Returns the assigned record id.
pub async fn ingest(text: String) -> Result<String, AgentError> {
    let store = state::memory()?;
    store
        .memory_ingest(MemoryRecord {
            id: None,
            text,
            kind: "note".to_string(),
            entity: None,
        })
        .await
        .map_err(|e| AgentError::Config(e.to_string()))
}

/// Hybrid semantic + lexical search over ingested memory, RRF-fused in the DB.
pub async fn search(query: String, k: u32) -> Result<Vec<MemoryHit>, AgentError> {
    search_with(query, k, SearchMode::Hybrid).await
}

/// `search`, choosing the retrieval lane (C-111 T3).
///
/// `SearchMode::Vector` is a diagnostic — it drops the BM25 lane and RRF so the UI can
/// show what fusion actually buys on the same query. Scores are comparable only within a
/// mode, so callers must never merge results from both.
pub async fn search_with(
    query: String,
    k: u32,
    mode: SearchMode,
) -> Result<Vec<MemoryHit>, AgentError> {
    let store = state::memory()?;
    store
        .memory_search_with(&query, k as usize, mode)
        .await
        .map_err(|e| AgentError::Config(e.to_string()))
}

/// Ingest the demo corpus (C-111). Idempotent — the notes carry stable ids, so the
/// `load_seeds` boot step can call this on every start without duplicating.
/// Returns the number of notes seeded.
pub async fn seed_demo_corpus() -> Result<usize, AgentError> {
    let store = state::memory()?;
    gen_ui_db_graph::seed_corpus(store)
        .await
        .map_err(|e| AgentError::Config(e.to_string()))
}

/// Expand the entity graph outward from `entity_id` up to `depth` RELATE hops.
pub async fn graph_expand(entity_id: String, depth: u32) -> Result<Vec<RelatedEntity>, AgentError> {
    let store = state::memory()?;
    let depth = depth.clamp(1, u8::MAX as u32) as u8;
    store
        .graph_expand(&entity_id, depth)
        .await
        .map_err(|e| AgentError::Config(e.to_string()))
}

/// C-129: mobile's client-RAG entry point. `RagEngine` built once per process
/// over `GraphVectorStore`/`GraphRagEmbedder` (c128's adapters over the SAME
/// SurrealDB store `search`/`ingest` above already use — no second vector
/// engine, no second embedder instance).
static RAG_ENGINE: OnceCell<Arc<RagEngine>> = OnceCell::const_new();

async fn rag_engine() -> Result<Arc<RagEngine>, AgentError> {
    RAG_ENGINE
        .get_or_try_init(|| async {
            let store = state::memory()?.clone();
            let embedder: Arc<dyn gen_ui_db::rag::Embedder> =
                Arc::new(GraphRagEmbedder::new(store.embedder()));
            let vector_store: Arc<dyn gen_ui_db::rag::VectorStore> =
                Arc::new(GraphVectorStore::new(store));
            Ok::<_, AgentError>(Arc::new(RagEngine::new(embedder, vector_store)))
        })
        .await
        .cloned()
}

/// Retrieve context for `query` within `scope`, never exceeding `token_budget`
/// tokens of chunk text. Mirrors desktop's `rag_retrieve` Tauri command, which
/// runs the same `RagEngine` shape over pgvector instead of this SurrealDB
/// adapter (two different vector surfaces, one shared engine contract).
pub async fn retrieve(
    query: String,
    scope: RetrievalScope,
    k: usize,
    token_budget: usize,
) -> Result<Vec<RetrievedChunk>, AgentError> {
    let engine = rag_engine().await?;
    let request = RetrievalQuery {
        text: query,
        scope,
        k,
        min_score: gen_ui_db::rag::DEFAULT_MIN_SCORE,
    };
    engine
        .retrieve(request, token_budget)
        .await
        .map_err(|e| AgentError::Config(e.to_string()))
}
