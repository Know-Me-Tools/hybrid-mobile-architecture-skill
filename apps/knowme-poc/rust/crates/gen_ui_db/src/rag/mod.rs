// TJ-ARCH-MOB-001 compliant
//! Client-side RAG (C-123). ONE typed retrieval API — features and agents call
//! [`RagEngine::retrieve`]; they never write retrieval SQL. Pipeline (fixed
//! order, `references/sync/client-rag.md`): embed query → vector candidates
//! (top-4k per store) → dedup by source → score floor → recency tiebreak → cut
//! to k and token budget. Embeddings are 384-dim everywhere and are DERIVED
//! data: computed on-device, backfilled idempotently, never a sync dependency.
//!
//! Seams: [`Embedder`] (fastembed/candle impl lives in the inference layer) and
//! [`VectorStore`] (pgvector on pg/pglite via [`pg_vector`]; sqlite-vec mobile
//! impl lands with the mobile tier). Vault-class content indexes into a
//! SEPARATE local-only store — an embedding of `local` data is `local`.

mod engine;
#[cfg(feature = "pg")]
mod pg_vector;

pub use engine::{RagEngine, DEFAULT_K, DEFAULT_MIN_SCORE, EMBEDDING_DIM};
#[cfg(feature = "pg")]
pub use pg_vector::{backfill_embeddings, PgVectorStore, MESSAGES_EMBEDDING_DDL};

use async_trait::async_trait;
use gen_ui_types::error::CoreResult;
use serde::{Deserialize, Serialize};

/// Where retrieval looks. `Vault` results carry `privacy_class: "local"` and are
/// momentary prompt context only (see `references/sync/peer-crdt.md`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RetrievalScope {
    ThisConversation { conversation_id: String },
    AllConversations,
    AgentMemory,
    Vault,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetrievalQuery {
    pub text: String,
    pub scope: RetrievalScope,
    /// Result count cap (defaults to [`DEFAULT_K`] via `RetrievalQuery::new`).
    pub k: usize,
    /// Cosine-similarity floor (defaults to [`DEFAULT_MIN_SCORE`]).
    pub min_score: f32,
}

impl RetrievalQuery {
    pub fn new(text: impl Into<String>, scope: RetrievalScope) -> Self {
        Self {
            text: text.into(),
            scope,
            k: DEFAULT_K,
            min_score: DEFAULT_MIN_SCORE,
        }
    }
}

/// Provenance travels with every chunk so caller sinks can apply privacy rules
/// structurally (LFS-INV-4) and cite sources.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Provenance {
    pub table: String,
    pub privacy_class: String,
    /// RFC3339 timestamp of the source row (recency tiebreak input).
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RetrievedChunk {
    pub source_id: String,
    pub text: String,
    pub score: f32,
    pub provenance: Provenance,
}

/// On-device embedding seam (384-dim). Implementations run CPU-bound work on
/// `spawn_blocking`; callers treat this as async.
#[async_trait]
pub trait Embedder: Send + Sync {
    async fn embed(&self, text: &str) -> CoreResult<Vec<f32>>;
}

/// One vector candidate from a store, pre-trim.
#[derive(Debug, Clone)]
pub struct VectorHit {
    pub source_id: String,
    pub text: String,
    pub score: f32,
    pub provenance: Provenance,
}

/// Vector search seam. pgvector (pg/pglite) and sqlite-vec implement this;
/// in-memory fakes are legitimate test doubles at this IO boundary.
#[async_trait]
pub trait VectorStore: Send + Sync {
    async fn search(
        &self,
        scope: &RetrievalScope,
        embedding: &[f32],
        limit: usize,
    ) -> CoreResult<Vec<VectorHit>>;
}
