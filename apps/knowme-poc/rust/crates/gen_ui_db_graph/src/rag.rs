// TJ-ARCH-MOB-001 compliant
//! C-128: mobile's client-RAG [`gen_ui_db::rag::VectorStore`] — a thin adapter
//! over `GraphStore`'s EXISTING 384-dim HNSW + BM25 memory store
//! (`memory_ingest` / `search_by_vector*`), which already gives mobile the
//! same client-RAG capability c123 built pgvector for on desktop/web. This
//! deliberately does NOT introduce sqlite-vec (the plan's original design):
//! that would be a second, unused vector engine on a platform that already
//! has one, the exact mistake c127 corrected for `LocalStore`.
//!
//! `RetrievalScope::Vault` still refuses here, same as `PgVectorStore` — an
//! embedding of `local`-class data is `local` (LFS-INV-4); mobile's vault
//! (when it lands) gets its own local-only index, never this one.
use gen_ui_types::error::{CoreError, CoreResult};
use std::sync::Arc;

use crate::embed::Embedder as GraphEmbedder;
use crate::store::GraphStore;

/// Adapts this crate's sync [`GraphEmbedder`] to `gen_ui_db::rag::Embedder`'s
/// async seam. `GraphEmbedder::embed` is CPU-bound (ONNX inference); running
/// it on `spawn_blocking` matches the crate's own `embed_blocking` pattern.
pub struct GraphRagEmbedder {
    inner: Arc<dyn GraphEmbedder>,
}

impl GraphRagEmbedder {
    pub fn new(inner: Arc<dyn GraphEmbedder>) -> Self {
        Self { inner }
    }
}

#[async_trait::async_trait]
impl gen_ui_db::rag::Embedder for GraphRagEmbedder {
    async fn embed(&self, text: &str) -> CoreResult<Vec<f32>> {
        let inner = Arc::clone(&self.inner);
        let text = text.to_string();
        gen_ui_runtime::spawn_blocking(move || inner.embed(&[text]))
            .await
            .map_err(|e| CoreError::Terminal(format!("embed task join: {e}")))?
            .map_err(|e| CoreError::Terminal(format!("embed: {e}")))?
            .into_iter()
            .next()
            .ok_or_else(|| CoreError::Terminal("embedder returned no vector".into()))
    }
}

/// Adapts `GraphStore`'s existing memory table to `gen_ui_db::rag::VectorStore`.
pub struct GraphVectorStore {
    store: Arc<GraphStore>,
}

impl GraphVectorStore {
    pub fn new(store: Arc<GraphStore>) -> Self {
        Self { store }
    }
}

#[async_trait::async_trait]
impl gen_ui_db::rag::VectorStore for GraphVectorStore {
    async fn search(
        &self,
        scope: &gen_ui_db::rag::RetrievalScope,
        embedding: &[f32],
        limit: usize,
    ) -> CoreResult<Vec<gen_ui_db::rag::VectorHit>> {
        use gen_ui_db::rag::RetrievalScope;
        if matches!(scope, RetrievalScope::Vault) {
            return Err(CoreError::Terminal(
                "vault retrieval uses the local-only vault index, not the shared memory store"
                    .into(),
            ));
        }
        // Every non-Vault scope reads the same `memory` table today — mobile
        // has no per-conversation partition yet (see c123's ThisConversation
        // note that mobile ships doctrine + stubs). Filtering can be added
        // to `search_by_vector_with_timestamps`'s WHERE clause once mobile's
        // conversation-scoped memory kind exists.
        let hits = self
            .store
            .search_by_vector_with_timestamps(embedding.to_vec(), limit)
            .await
            .map_err(|e| CoreError::Terminal(e.to_string()))?;
        Ok(hits
            .into_iter()
            .map(|(hit, created)| gen_ui_db::rag::VectorHit {
                source_id: hit.id,
                text: hit.text,
                score: hit.score,
                provenance: gen_ui_db::rag::Provenance {
                    table: "memory".to_string(),
                    privacy_class: "trusted".to_string(),
                    updated_at: created,
                },
            })
            .collect())
    }
}

// Boundary tests live in tests/it/rag_seam.rs, NOT here — this crate's
// GraphStore/gen_ui_runtime are process-global singletons that a plain
// `#[tokio::test]` breaks (see tests/it/main.rs's `run_test` doc comment:
// "runtime not initialised" / dead-router flakiness). Every other test
// module in this crate follows the same rule.
