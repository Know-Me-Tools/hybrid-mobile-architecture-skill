// TJ-ARCH-MOB-001 compliant
//! SurrealDB 3.2 schema DDL. Kept as `OVERWRITE`/`IF NOT EXISTS` statements so
//! `GraphStore::init` is idempotent — safe to run on every boot (greenfield; no
//! in-place 2.x→3.x migration path per the analysis, which is fine for new stores).
//!
//! 3.x syntax notes (breaking vs 2.x, verified against SurrealDB 3.2 docs):
//!   * vector index is `HNSW DIMENSION n DIST COSINE` (MTREE was removed in 3.0)
//!   * full-text index is `FULLTEXT ANALYZER <a> BM25` (was `SEARCH ANALYZER`)
//!   * `search::rrf([...], k, limit)` fuses ranked lists natively (added in 3.0)

/// Analyzer + entity/memory tables + HNSW and BM25 indexes + the RELATE edge table.
/// One string so `init` runs it in a single `.query()` round-trip.
pub const SCHEMA_DDL: &str = r#"
-- Full-text analyzer: whitespace + class + camelCase splitting, English stemming.
DEFINE ANALYZER OVERWRITE gu_simple
    TOKENIZERS blank, class, camel, punct
    FILTERS lowercase, snowball(english);

-- entity: nodes in the knowledge graph (projects, notes, people, ...).
DEFINE TABLE IF NOT EXISTS entity SCHEMALESS;
DEFINE FIELD IF NOT EXISTS entity_type ON entity TYPE string;
DEFINE FIELD IF NOT EXISTS label       ON entity TYPE string;
DEFINE FIELD IF NOT EXISTS data        ON entity FLEXIBLE TYPE option<object>;

-- memory: retrievable text with its embedding; optionally linked to an entity.
DEFINE TABLE IF NOT EXISTS memory SCHEMALESS;
DEFINE FIELD IF NOT EXISTS text      ON memory TYPE string;
DEFINE FIELD IF NOT EXISTS kind      ON memory TYPE string DEFAULT 'note';
DEFINE FIELD IF NOT EXISTS entity    ON memory TYPE option<record<entity>>;
DEFINE FIELD IF NOT EXISTS embedding ON memory TYPE array<float>;
DEFINE FIELD IF NOT EXISTS created   ON memory TYPE datetime DEFAULT time::now();

-- HNSW vector index — semantic recall. 384 dims to match all-MiniLM-L6-v2 / bge-small.
DEFINE INDEX OVERWRITE memory_hnsw ON memory
    FIELDS embedding HNSW DIMENSION 384 DIST COSINE;

-- BM25 full-text index — lexical recall the vector lane misses.
DEFINE INDEX OVERWRITE memory_ft ON memory
    FIELDS text FULLTEXT ANALYZER gu_simple BM25;

-- relates_to: typed graph edges between entities, traversed by graph_expand.
DEFINE TABLE IF NOT EXISTS relates_to SCHEMALESS TYPE RELATION FROM entity TO entity;
DEFINE FIELD IF NOT EXISTS rel ON relates_to TYPE string DEFAULT 'related';

-- Config DB v1 (mobile only — desktop/web use the Postgres-dialect schema in
-- gen_ui_db instead; see gen_ui_db::relational::config). api_key_ref is a
-- reference into platform-secure storage, never a plaintext secret.
DEFINE TABLE IF NOT EXISTS provider SCHEMALESS;
DEFINE FIELD IF NOT EXISTS kind        ON provider TYPE string;
DEFINE FIELD IF NOT EXISTS base_url    ON provider TYPE option<string>;
DEFINE FIELD IF NOT EXISTS api_key_ref ON provider TYPE option<string>;
DEFINE FIELD IF NOT EXISTS enabled     ON provider TYPE bool DEFAULT true;

-- One record per (surface, lane), e.g. surface='chat', lane='cloud'|'local'.
DEFINE TABLE IF NOT EXISTS model_pref SCHEMALESS;
DEFINE FIELD IF NOT EXISTS surface     ON model_pref TYPE string;
DEFINE FIELD IF NOT EXISTS lane        ON model_pref TYPE string;
DEFINE FIELD IF NOT EXISTS provider_id ON model_pref TYPE option<string>;
DEFINE FIELD IF NOT EXISTS model_id    ON model_pref TYPE string;
DEFINE FIELD IF NOT EXISTS params      ON model_pref FLEXIBLE TYPE option<object>;

DEFINE TABLE IF NOT EXISTS app_setting SCHEMALESS;
DEFINE FIELD IF NOT EXISTS value ON app_setting FLEXIBLE TYPE option<object>;
"#;

/// Hybrid recall: vector lane + BM25 lane, fused by native `search::rrf`.
/// Binds: `$qvec` (query embedding), `$q` (query text), `$k` (neighbours).
/// Returns one ranked list of `{ id, text, kind, entity, score }`.
///
/// `<|$k,64|>` = return `$k` HNSW neighbours exploring up to 64 candidates.
/// RRF k=60 is the standard smoothing constant; limit 128 caps fusion input.
pub const HYBRID_SEARCH_QUERY: &str = r#"
LET $vs = SELECT id, text, kind, entity, vector::distance::knn() AS distance
    FROM memory WHERE embedding <|$k,64|> $qvec
    ORDER BY distance ASC LIMIT 64;
LET $ft = SELECT id, text, kind, entity, search::score(0) AS ft_score
    FROM memory WHERE text @0@ $q
    ORDER BY ft_score DESC LIMIT 64;
SELECT meta::id(id) AS id, text, kind, rrf_score AS score
    FROM search::rrf([$vs, $ft], 60, 128)
    LIMIT $k;
"#;
