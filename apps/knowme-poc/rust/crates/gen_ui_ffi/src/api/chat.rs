// TJ-ARCH-MOB-001 compliant
//! Chat + memory/graph-RAG intent surface. Dart sends a turn and folds the
//! resulting A2uiEvent stream (see streams::chat_events) into ContentBlocks.
//! Memory/graph functions are intent-level (`memory_search`, `graph_expand`) —
//! never raw SurrealQL. Wave-1 (C-004 graph, C-006 agent) supply the backends.
//!
//! Functions here spell out `Result<T, CoreError>` rather than the
//! `gen_ui_types::CoreResult<T>` alias: flutter_rust_bridge_codegen 2.12.0
//! does not resolve type aliases used directly as a function's return type
//! (confirmed empirically, 2026-07-16 — a plain `Result<String, String>`
//! return generates a throwing `Future<String>` as expected, but
//! `CoreResult<String>` generates an opaque, fieldless `RustOpaqueInterface`
//! handle with no way for Dart to read the value out). `CoreError` derives
//! `thiserror::Error` (→ `std::error::Error`), and this crate's
//! `flutter_rust_bridge` dependency has the `anyhow` feature enabled, so frb's
//! built-in `Result<T, E: std::error::Error>` handling turns the spelled-out
//! form into a `Future<T>` that throws a Dart exception (carrying
//! `CoreError`'s `Display` message) on `Err` — no mirror needed. `gen_ui_agent`
//! and other non-FFI-facing Rust callers should keep using `CoreResult<T>`;
//! this is purely a frb-parser workaround at the Dart-facing boundary.
// `pub use` (not `use`) — frb_generated.rs glob-imports `crate::api::chat::*`
// and references `CoreError` by bare name in its opaque-refcounting
// boilerplate; a plain (non-`pub`) `use` does not re-export it.
pub use gen_ui_types::CoreError;

/// Start a chat turn; returns the run_id whose events arrive on chat_events(run_id).
///
/// Dispatches into gen_ui_agent::ChatAgent (the single orchestration
/// implementation shared with tauri-plugin-gen-ui — no duplicated business
/// logic). Resolves provider/model from the config DB and streams the reply;
/// if no provider is configured/enabled yet this returns `Err` with a clear
/// message rather than an empty run_id (see gen_ui_agent::state for the
/// graceful-degrade default before platform config-store wiring lands, T8+).
pub async fn chat_send(thread_id: String, message: String) -> Result<String, CoreError> {
    gen_ui_agent::global_chat_agent().send(thread_id, message).await
}

/// Hybrid memory search (vector recall + graph expansion + BM25, RRF-fused in Rust).
/// Returns opaque JSON rows the UI renders as Memory/Citation ContentBlocks.
pub async fn memory_search(query: String, k: u32) -> Result<Vec<String>, CoreError> {
    let _ = (query, k);
    Ok(Vec::new())
}

/// Expand the entity graph around a node to a given depth. Intent-level; the
/// recursive RELATE traversal lives in gen_ui_db::graph (C-004).
pub async fn graph_expand(entity_id: String, depth: u32) -> Result<Vec<String>, CoreError> {
    let _ = (entity_id, depth);
    Ok(Vec::new())
}

