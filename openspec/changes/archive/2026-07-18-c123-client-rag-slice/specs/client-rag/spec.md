## ADDED Requirements

### Requirement: Client-side retrieval engine
Client RAG SHALL run entirely on-device through one typed API (`RagEngine::retrieve`)
with a fixed pipeline: embed (384-dim standard) → vector candidates → dedup by source
→ score floor → score-then-recency ordering → k and token-budget cuts. Features and
agents SHALL NOT write retrieval SQL.

#### Scenario: Ordering and dedup contract holds
- **WHEN** candidates include duplicates, ties, and below-floor scores
- **THEN** results are score-descending with recency tiebreaks, one chunk per source
  entity, floored, and capped by k and token budget

### Requirement: Per-tier vector stores
The vector surface SHALL be pgvector on web (PGlite + `@electric-sql/pglite-pgvector`
extension) and desktop (pglite-oxide), and sqlite-vec on mobile, all at 384 dimensions;
embeddings are derived data backfilled idempotently where `embedded_at IS NULL`.

#### Scenario: Wrong-dimension embeddings refused
- **WHEN** an embedding of any dimension other than 384 reaches the store
- **THEN** the operation fails terminally before SQL executes

#### Scenario: Web store loads pgvector
- **WHEN** the web PGlite store boots
- **THEN** the vector extension is registered at create time and `CREATE EXTENSION
  IF NOT EXISTS vector` plus the HNSW-indexed vector tables apply

### Requirement: Vault vectors stay local
Vault-scope retrieval SHALL NOT query server-synced tables; requesting the Vault
scope from a synced-store implementation fails terminally (an embedding of
`local`-class data is itself `local`).

#### Scenario: Vault scope on the synced store
- **WHEN** RetrievalScope::Vault is requested from the pgvector synced store
- **THEN** the call fails with a terminal error naming the local-only vault index
