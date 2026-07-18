# rag-ipc Specification

## Purpose
TBD - created by archiving change c129-rag-ipc-and-chat-wiring. Update Purpose after archive.
## Requirements
### Requirement: RAG retrieval exposed over IPC
`RagEngine` SHALL be reachable from the UI on both surfaces: a `rag_retrieve`
Tauri command on desktop (over `PgVectorStore`/`FastEmbedder`, embedding
cache lazily initialized once per process) and a `rag_retrieve` frb function
on mobile (over c128's `GraphVectorStore`/`GraphRagEmbedder`), sharing one
request/response shape (`query`, `scope`, optional `conversation_id`, `k`,
`token_budget`).

#### Scenario: Desktop retrieval returns typed chunks with provenance
- **WHEN** `rag_retrieve` is invoked with a query and a valid scope
- **THEN** it returns chunks with `sourceId`, `text`, `score`, `table`, and
  `updatedAt`, using the SAME engine/embedder singleton across calls

#### Scenario: this_conversation scope requires a conversation id
- **WHEN** `scope` is `"this_conversation"` without `conversationId`
- **THEN** the call fails with a clear error rather than silently searching
  all conversations

### Requirement: Chat store owns the only invoke() point for retrieval
The desktop chat store SHALL expose `retrieveContext(query)` as the sole
caller of `ragRetrieve`; hooks compose it (`useRecall`), and components never
call the IPC binding directly (layer contract: UI → Hooks → Stores →
Services/API).

#### Scenario: useRecall skips empty queries
- **WHEN** `recall` is called with an empty or whitespace-only query
- **THEN** `retrieveContext` is never invoked and chunks clear

#### Scenario: useRecall surfaces retrieved chunks
- **WHEN** `recall` is called with a non-empty query
- **THEN** the chunks `retrieveContext` resolves with become the hook's
  `chunks` state

