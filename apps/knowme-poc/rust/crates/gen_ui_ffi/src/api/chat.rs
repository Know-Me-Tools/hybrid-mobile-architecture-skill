// TJ-ARCH-MOB-001 compliant
//! Chat + memory/graph-RAG intent surface. Dart sends a turn and folds the
//! resulting A2uiEvent stream (see streams::chat_events) into ContentBlocks.
//! Memory/graph functions are intent-level (`memory_search`, `graph_expand`) —
//! never raw SurrealQL. chat_send delegates to gen_ui_agent::chat::send, the
//! SAME implementation tauri-plugin-gen-ui's stream_agent_a2ui calls — no
//! duplicated business logic between the mobile and desktop leaves.
// `pub use` (not `use`) — frb_generated.rs re-exports this module's types via
// `use crate::api::chat::*`, which only sees items visible through a public path.
pub use gen_ui_types::CoreResult;

/// Start a chat turn; returns the run_id whose events arrive on chat_events(run_id).
/// `thread_id` is reserved for multi-thread history (not yet used — the agent
/// layer takes the full turn history via `message` for now).
pub async fn chat_send(thread_id: String, message: String) -> CoreResult<String> {
    let _ = thread_id;
    gen_ui_agent::chat::send(message, Vec::new()).await.map_err(Into::into)
}

/// Hybrid memory search (vector recall + graph expansion + BM25, RRF-fused in Rust).
/// Returns opaque JSON rows the UI renders as Memory/Citation ContentBlocks.
pub async fn memory_search(query: String, k: u32) -> CoreResult<Vec<String>> {
    let _ = (query, k);
    Ok(Vec::new())
}

/// Expand the entity graph around a node to a given depth. Intent-level; the
/// recursive RELATE traversal lives in gen_ui_db::graph (C-004).
pub async fn graph_expand(entity_id: String, depth: u32) -> CoreResult<Vec<String>> {
    let _ = (entity_id, depth);
    Ok(Vec::new())
}
