## ADDED Requirements

### Requirement: Mobile client-RAG reuses the existing SurrealDB vector store
Mobile's `gen_ui_db::rag::VectorStore`/`Embedder` seams SHALL be implemented
as adapters (`GraphVectorStore`, `GraphRagEmbedder`) over `GraphStore`'s
EXISTING 384-dim HNSW memory table, NOT a second vector engine. `RagEngine`
callers on mobile therefore reuse the same store `memory_ingest`/
`memory_search` already write and read.

#### Scenario: Ingested memory is retrievable through the RAG seam
- **WHEN** a memory is ingested via `memory_ingest` and later queried via
  `GraphVectorStore::search` with a semantically similar embedding
- **THEN** that memory is returned, ranked first for its own text, with
  non-empty provenance

#### Scenario: Vault scope is refused on the shared store
- **WHEN** `RetrievalScope::Vault` is requested from `GraphVectorStore`
- **THEN** the call fails — an embedding of `local`-class data never lands in
  the shared memory store (LFS-INV-4); mobile's vault gets its own index

### Requirement: Vector-only recall without re-embedding
`GraphStore` SHALL expose a vector-only search entry point
(`search_by_vector`, `search_by_vector_with_timestamps`) that accepts an
already-computed embedding, so callers that embed once via their own
`Embedder` seam do not pay for a second embed inside `GraphStore`.

#### Scenario: Vector search accepts a precomputed embedding
- **WHEN** `search_by_vector` is called with an embedding not derived from a
  `memory_search` text query
- **THEN** it performs HNSW recall directly against that vector
