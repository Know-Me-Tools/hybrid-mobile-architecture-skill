// TJ-ARCH-MOB-001 compliant
//! Chat + memory/graph-RAG intent surface. Dart sends a turn and folds the
//! resulting A2uiEvent stream (see streams::chat_events) into ContentBlocks.
//! Memory/graph functions are intent-level (`memory_search`, `graph_expand`) —
//! never raw SurrealQL. All three delegate to gen_ui_agent, the SAME
//! implementation tauri-plugin-gen-ui's commands call — no duplicated
//! business logic between the mobile and desktop leaves.
// `pub use` (not `use`) — frb_generated.rs re-exports this module's types via
// `use crate::api::chat::*`, which only sees items visible through a public path.
//
// frb's Result<T,E> detection only matches a literal `Result<...>` return
// type — it does NOT resolve through a generic type alias (verified against
// flutter_rust_bridge_codegen 2.12.0: its alias-parsing filter drops any
// `type Foo<T> = ...` with generics before resolution runs). Every
// frb-exposed fn below spells out `Result<T, CoreError>` literally; using
// `CoreResult<T>` here would silently make Dart receive an opaque blob with
// no field/error access instead of a normal Future<T> that throws on Err.
pub use gen_ui_db_graph::{MemoryHit, RelatedEntity};
pub use gen_ui_types::CoreError;

/// Start a chat turn; returns the run_id whose events arrive on chat_events(run_id).
/// `messages` is the selected conversation's role/text history. The thread id
/// remains transport metadata; persistence is owned by the entity repository.
pub async fn chat_send(
    thread_id: String,
    message: String,
    messages: Vec<String>,
) -> Result<String, CoreError> {
    let _ = thread_id;
    gen_ui_agent::chat::send(message, messages)
        .await
        .map_err(Into::into)
}

/// Ingest a note into memory (embeds on-device via fastembed, upserts into
/// SurrealDB). Returns the assigned record id.
pub async fn memory_ingest(text: String) -> Result<String, CoreError> {
    gen_ui_agent::memory::ingest(text).await.map_err(Into::into)
}

/// Hybrid memory search (vector recall + graph expansion + BM25, RRF-fused in Rust).
pub async fn memory_search(query: String, k: u32) -> Result<Vec<MemoryHit>, CoreError> {
    gen_ui_agent::memory::search(query, k)
        .await
        .map_err(Into::into)
}

/// Expand the entity graph around a node to a given depth.
pub async fn graph_expand(entity_id: String, depth: u32) -> Result<Vec<RelatedEntity>, CoreError> {
    gen_ui_agent::memory::graph_expand(entity_id, depth)
        .await
        .map_err(Into::into)
}

/// C-129: client-RAG retrieval, mirroring desktop's `rag_retrieve` Tauri
/// command over the SAME `RagEngine` contract (mobile runs it against c128's
/// SurrealDB adapter instead of pgvector). `scope`: "this_conversation" |
/// "all_conversations" | "agent_memory" — Vault is deliberately not
/// selectable from the wire (LFS-INV-4, no server-facing invoke path).
pub async fn rag_retrieve(
    query: String,
    scope: String,
    conversation_id: Option<String>,
    k: u32,
    token_budget: u32,
) -> Result<Vec<RagChunk>, CoreError> {
    use gen_ui_db::rag::RetrievalScope;
    let scope = match scope.as_str() {
        "this_conversation" => {
            let id = conversation_id.ok_or_else(|| {
                CoreError::Terminal("this_conversation scope requires conversation_id".into())
            })?;
            RetrievalScope::ThisConversation { conversation_id: id }
        }
        "all_conversations" => RetrievalScope::AllConversations,
        "agent_memory" => RetrievalScope::AgentMemory,
        other => {
            return Err(CoreError::Terminal(format!(
                "rag_retrieve: unknown scope {other:?}"
            )))
        }
    };
    let chunks = gen_ui_agent::memory::retrieve(query, scope, k as usize, token_budget as usize)
        .await
        .map_err(CoreError::from)?;
    Ok(chunks
        .into_iter()
        .map(|c| RagChunk {
            source_id: c.source_id,
            text: c.text,
            score: c.score,
            table: c.provenance.table,
            updated_at: c.provenance.updated_at,
        })
        .collect())
}

/// frb-friendly, serde-free struct (avoids re-exporting `gen_ui_db::rag`'s
/// types across the frb boundary, matching this module's `MemoryHit`/
/// `RelatedEntity` re-export convention instead of a raw type re-export for
/// a crate frb does not cargo-expand per `flutter_rust_bridge.yaml`).
pub struct RagChunk {
    pub source_id: String,
    pub text: String,
    pub score: f32,
    pub table: String,
    pub updated_at: String,
}
