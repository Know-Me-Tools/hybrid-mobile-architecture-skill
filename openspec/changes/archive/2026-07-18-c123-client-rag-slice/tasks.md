# Tasks — c123-client-rag-slice

- [x] 1.1 gen_ui_db::rag — RetrievalQuery/RetrievedChunk/RetrievalScope types, Embedder + VectorStore seams, RagEngine pipeline (embed → search → dedup/floor/recency → budget)
- [x] 1.2 pgvector VectorStore (pg/pglite): DDL constants (vector(384) + HNSW), upsert/search SQL, embed-on-write backfill (embedded_at IS NULL)
- [x] 1.3 Desktop/web wiring: pgvector extension + embedding columns in knowme-poc PGlite schema; agent-fact storage documented as PEM entities
- [x] 1.4 Behavior tests: engine ordering/dedup/budget contract + backfill idempotence; clippy clean
- [x] 1.5 Spec delta + openspec validate; scaffold propagation notes for c125
