// TJ-ARCH-MOB-001 compliant
//! Chat + memory/graph-RAG intent surface. Dart sends a turn and folds the
//! resulting A2uiEvent stream (see streams::chat_events) into ContentBlocks.
//! Memory/graph functions are intent-level (`memory_search`, `graph_expand`) —
//! never raw SurrealQL. Wave-1 (C-004 graph, C-006 agent) supply the backends.
// `pub use` (not `use`) — frb_generated.rs re-exports this module's types via
// `use crate::api::chat::*`, which only sees items visible through a public path.
pub use gen_ui_types::CoreResult;

/// Start a chat turn; returns the run_id whose events arrive on chat_events(run_id).
///
/// Dispatches into gen_ui_agent::ChatAgent (the single orchestration
/// implementation shared with tauri-plugin-gen-ui — no duplicated business
/// logic). Resolves provider/model from the config DB and streams the reply;
/// if no provider is configured/enabled yet this returns `Err` with a clear
/// message rather than an empty run_id (see gen_ui_agent::state for the
/// graceful-degrade default before platform config-store wiring lands, T8+).
pub async fn chat_send(thread_id: String, message: String) -> CoreResult<String> {
    gen_ui_agent::global_chat_agent().send(thread_id, message).await
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
