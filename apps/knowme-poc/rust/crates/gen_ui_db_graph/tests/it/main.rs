// TJ-ARCH-MOB-001 compliant
//! Boundary tests for gen_ui_db_graph — exercised at the public intent API over a
//! real in-memory SurrealDB (`memory` engine) with a deterministic fake embedder,
//! so no ONNX download and no flakiness. Per CLAUDE.md: 3–5 behaviour tests at the
//! API surface, no internal mocks, features-first.
mod fake_embedder;

use fake_embedder::HashEmbedder;
use gen_ui_db_graph::{GraphStore, GraphStoreConfig, MemoryRecord};
use std::sync::Arc;

/// The store embeds via `gen_ui_runtime::spawn_blocking`, which reads the crate's
/// global runtime `OnceCell` — and `#[tokio::test]` builds its OWN runtime that the
/// OnceCell knows nothing about. Without this, every embedding path panics with
/// "runtime not initialised" and the failure looks like broken search rather than
/// missing setup. `init` is idempotent, so every test can call it.
fn init_runtime() {
    gen_ui_runtime::init(Some(2));
}

async fn open_store() -> GraphStore {
    init_runtime();
    GraphStore::open(GraphStoreConfig {
        endpoint: "memory".into(),
        namespace: "test".into(),
        database: "graph".into(),
        embedder: Arc::new(HashEmbedder),
    })
    .await
    .expect("store opens and applies schema")
}

/// Ingest → hybrid search returns the ingested memory ranked first for its own text.
#[tokio::test]
async fn ingest_then_search_finds_the_memory() {
    let store = open_store().await;
    let id = store
        .memory_ingest(MemoryRecord {
            id: None,
            text: "the octopus is a highly intelligent cephalopod".into(),
            kind: "note".into(),
            entity: None,
        })
        .await
        .expect("ingest succeeds");
    assert!(!id.is_empty());

    let hits = store
        .memory_search("octopus intelligent cephalopod", 5)
        .await
        .expect("search succeeds");
    assert!(!hits.is_empty(), "expected at least one hit");
    assert!(
        hits[0].text.contains("octopus"),
        "top hit should be the ingested memory, got {:?}",
        hits[0].text
    );
}

/// BM25 lexical lane finds an exact-term match even when semantics are thin.
#[tokio::test]
async fn lexical_lane_matches_rare_term() {
    let store = open_store().await;
    for text in [
        "quarterly revenue grew in the fiscal report",
        "the platypus lays eggs despite being a mammal",
    ] {
        store
            .memory_ingest(MemoryRecord {
                id: None,
                text: text.into(),
                kind: "note".into(),
                entity: None,
            })
            .await
            .expect("ingest");
    }
    let hits = store.memory_search("platypus", 5).await.expect("search");
    assert!(
        hits.iter().any(|h| h.text.contains("platypus")),
        "BM25 lane should surface the platypus memory"
    );
}

/// Vector-only mode returns hits and is scored "higher = better", like hybrid.
///
/// This asserts the lane WORKS, not that it is worse — the fake HashEmbedder has no
/// real semantics, so a meaningful hybrid-beats-vector comparison isn't possible here.
/// That difference is what the UI toggle exists to show against real embeddings; a test
/// asserting it with a hash fake would be asserting the fake's arbitrary behaviour.
#[tokio::test]
async fn vector_mode_returns_scored_hits() {
    use gen_ui_db_graph::SearchMode;
    let store = open_store().await;
    for text in [
        "the axolotl regenerates entire limbs",
        "quarterly revenue grew in the fiscal report",
    ] {
        store
            .memory_ingest(MemoryRecord {
                id: None,
                text: text.into(),
                kind: "note".into(),
                entity: None,
            })
            .await
            .expect("ingest");
    }

    let hits = store
        .memory_search_with("axolotl regenerates limbs", 5, SearchMode::Vector)
        .await
        .expect("vector search succeeds");

    assert!(!hits.is_empty(), "vector lane should return hits");
    // Scores are 1/(1+distance), so bounded (0,1] and descending.
    for h in &hits {
        assert!(h.score > 0.0 && h.score <= 1.0, "score out of range: {}", h.score);
    }
    assert!(
        hits.windows(2).all(|w| w[0].score >= w[1].score),
        "vector hits must be ranked best-first: {:?}",
        hits.iter().map(|h| h.score).collect::<Vec<_>>()
    );
}

/// Empty inputs are rejected at the boundary (terminal, not a silent empty result).
#[tokio::test]
async fn empty_inputs_are_rejected() {
    let store = open_store().await;
    assert!(store
        .memory_ingest(MemoryRecord {
            id: None,
            text: "   ".into(),
            kind: "note".into(),
            entity: None,
        })
        .await
        .is_err());
    assert!(store.memory_search("", 5).await.is_err());
    // depth 0 is a caller error, not an empty traversal.
    assert!(store.graph_expand("entity:anything", 0).await.is_err());
}

/// RELATE edges are traversed and fused by graph_expand, nearer hops ranking higher.
#[tokio::test]
async fn graph_expand_traverses_relate_edges() {
    let store = open_store().await;
    // Seed a small graph: a -> b -> c, plus a -> d directly.
    for (id, label) in [("a", "Alpha"), ("b", "Beta"), ("c", "Gamma"), ("d", "Delta")] {
        store.create_entity(id, "node", label).await.expect("create entity");
    }
    for (from, to) in [("a", "b"), ("b", "c"), ("a", "d")] {
        store.relate(from, to, "related").await.expect("relate");
    }
    let related = store
        .graph_expand("a", 2)
        .await
        .expect("graph_expand succeeds");
    let ids: Vec<&str> = related.iter().map(|r| r.id.as_str()).collect();
    assert!(ids.contains(&"b"), "1-hop neighbour b should be present: {ids:?}");
    assert!(ids.contains(&"d"), "1-hop neighbour d should be present: {ids:?}");
    assert!(ids.contains(&"c"), "2-hop neighbour c should be present: {ids:?}");
    // b (1 hop) must outrank c (2 hops) under RRF.
    let rank = |want: &str| related.iter().position(|r| r.id == want).unwrap();
    assert!(rank("b") < rank("c"), "nearer hop b should outrank farther hop c");
}
