// TJ-ARCH-MOB-001 compliant
//! The retrieval pipeline. Stage order is a contract (tested): candidates →
//! dedup by source → min_score floor → score-then-recency ordering → cut to k
//! → cut to token budget. Chunks are whole messages (no mid-message splits).

use super::{Embedder, RetrievalQuery, RetrievedChunk, VectorStore};
use gen_ui_types::error::CoreResult;
use std::collections::HashSet;
use std::sync::Arc;

pub const EMBEDDING_DIM: usize = 384;
pub const DEFAULT_K: usize = 8;
pub const DEFAULT_MIN_SCORE: f32 = 0.3;
/// Candidate over-fetch factor before trimming (top-4k per the reference doc).
const CANDIDATE_FACTOR: usize = 4;
/// Rough chars-per-token for budget cuts (client-side heuristic; callers pass
/// the budget in tokens).
const CHARS_PER_TOKEN: usize = 4;

pub struct RagEngine {
    embedder: Arc<dyn Embedder>,
    store: Arc<dyn VectorStore>,
}

impl RagEngine {
    pub fn new(embedder: Arc<dyn Embedder>, store: Arc<dyn VectorStore>) -> Self {
        Self { embedder, store }
    }

    /// Retrieve context for `query`, never exceeding `token_budget` tokens of
    /// chunk text. Results are score-descending with recency as the tiebreak.
    pub async fn retrieve(
        &self,
        query: RetrievalQuery,
        token_budget: usize,
    ) -> CoreResult<Vec<RetrievedChunk>> {
        let embedding = self.embedder.embed(&query.text).await?;
        let candidates = self
            .store
            .search(&query.scope, &embedding, query.k * CANDIDATE_FACTOR)
            .await?;

        // Dedup by source entity, keeping the best-scoring hit.
        let mut seen = HashSet::new();
        let mut chunks: Vec<RetrievedChunk> = Vec::new();
        let mut ordered = candidates;
        ordered.sort_by(|a, b| {
            b.score
                .partial_cmp(&a.score)
                .unwrap_or(std::cmp::Ordering::Equal)
                .then_with(|| b.provenance.updated_at.cmp(&a.provenance.updated_at))
        });
        for hit in ordered {
            if hit.score < query.min_score {
                continue;
            }
            if !seen.insert(hit.source_id.clone()) {
                continue;
            }
            chunks.push(RetrievedChunk {
                source_id: hit.source_id,
                text: hit.text,
                score: hit.score,
                provenance: hit.provenance,
            });
            if chunks.len() == query.k {
                break;
            }
        }

        // Token-budget cut: drop trailing chunks once the budget is exhausted.
        let budget_chars = token_budget.saturating_mul(CHARS_PER_TOKEN);
        let mut used = 0usize;
        chunks.retain(|chunk| {
            let next = used + chunk.text.len();
            if next > budget_chars {
                return false;
            }
            used = next;
            true
        });
        Ok(chunks)
    }
}

#[cfg(test)]
mod tests {
    use super::super::{Provenance, RetrievalScope, VectorHit};
    use super::*;
    use async_trait::async_trait;

    struct FixedEmbedder;
    #[async_trait]
    impl Embedder for FixedEmbedder {
        async fn embed(&self, _text: &str) -> CoreResult<Vec<f32>> {
            Ok(vec![0.0; EMBEDDING_DIM])
        }
    }

    struct FixedStore {
        hits: Vec<VectorHit>,
    }
    #[async_trait]
    impl VectorStore for FixedStore {
        async fn search(
            &self,
            _scope: &RetrievalScope,
            _embedding: &[f32],
            _limit: usize,
        ) -> CoreResult<Vec<VectorHit>> {
            Ok(self.hits.clone())
        }
    }

    fn hit(id: &str, score: f32, updated_at: &str, text: &str) -> VectorHit {
        VectorHit {
            source_id: id.into(),
            text: text.into(),
            score,
            provenance: Provenance {
                table: "messages".into(),
                privacy_class: "trusted".into(),
                updated_at: updated_at.into(),
            },
        }
    }

    fn engine(hits: Vec<VectorHit>) -> RagEngine {
        RagEngine::new(Arc::new(FixedEmbedder), Arc::new(FixedStore { hits }))
    }

    // Ordering contract: score descending, recency breaks ties, floor applies,
    // duplicates collapse to the best hit per source entity.
    #[tokio::test]
    async fn orders_dedups_and_floors_candidates() {
        let engine = engine(vec![
            hit("m1", 0.9, "2026-07-01T00:00:00Z", "alpha"),
            hit("m1", 0.5, "2026-07-01T00:00:00Z", "alpha-old"),
            hit("m2", 0.7, "2026-07-02T00:00:00Z", "beta"),
            hit("m3", 0.7, "2026-07-03T00:00:00Z", "gamma"),
            hit("m4", 0.1, "2026-07-04T00:00:00Z", "below-floor"),
        ]);
        let out = engine
            .retrieve(
                RetrievalQuery::new("q", RetrievalScope::AllConversations),
                10_000,
            )
            .await
            .expect("retrieve");
        let ids: Vec<_> = out.iter().map(|c| c.source_id.as_str()).collect();
        // m3 beats m2 on recency at equal score; m4 is floored; m1 deduped to 0.9.
        assert_eq!(ids, vec!["m1", "m3", "m2"]);
        assert_eq!(out[0].score, 0.9);
    }

    // Budget contract: k caps count, token budget caps total text.
    #[tokio::test]
    async fn respects_k_and_token_budget() {
        let engine = engine(vec![
            hit("m1", 0.9, "t", "aaaaaaaaaaaaaaaa"), // 16 chars = 4 tokens
            hit("m2", 0.8, "t", "bbbbbbbbbbbbbbbb"),
            hit("m3", 0.7, "t", "cccccccccccccccc"),
        ]);
        let mut query = RetrievalQuery::new("q", RetrievalScope::AgentMemory);
        query.k = 2;
        let out = engine.retrieve(query, 5).await.expect("retrieve");
        // k=2 allows m1+m2; a 5-token budget (20 chars) fits only m1.
        assert_eq!(out.len(), 1);
        assert_eq!(out[0].source_id, "m1");
    }
}
