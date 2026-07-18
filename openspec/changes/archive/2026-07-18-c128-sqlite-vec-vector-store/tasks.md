# Tasks — c128-sqlite-vec-vector-store

> DESIGN CORRECTED at execute time (mirrors c127): mobile already has a
> production-grade 384-dim HNSW+BM25 vector store in SurrealDB
> (GraphStore::memory_search/memory_ingest) — the same capability c123 built
> pgvector for on desktop/web. Adding sqlite-vec would be a second, unused
> vector engine, the exact mistake c127 corrected for LocalStore. This change
> instead adapts gen_ui_db::rag::VectorStore/Embedder over GraphStore's
> EXISTING memory API.

- [ ] 1.1 gen_ui_db_graph::rag — SurrealVectorStore implementing gen_ui_db::rag::VectorStore over GraphStore::memory_search_with; GraphStoreEmbedder implementing rag::Embedder over the crate's existing Embedder trait
- [ ] 1.2 GraphStore::vector_store()/embedder() accessors mirroring local_store()'s pattern
- [ ] 1.3 Behavior tests: ingest via memory_ingest -> retrieve via VectorStore -> ordering/dim-parity with PgVectorStore's contract
- [x] 1.4 cargo check/clippy clean; spec delta; openspec validate
