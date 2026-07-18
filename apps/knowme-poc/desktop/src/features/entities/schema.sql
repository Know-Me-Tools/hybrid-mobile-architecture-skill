-- TJ-ARCH-MOB-001 compliant
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL,
  project_id uuid NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS chat_conversations (
  id uuid PRIMARY KEY,
  tenant_id text NOT NULL,
  title text NOT NULL,
  messages jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- C-123 client-RAG vector surface (384-dim standard, references/sync/client-rag.md).
-- Messages live as JSONB inside chat_conversations until the C-104+ entity-view
-- normalization; message_embeddings carries the per-message vector surface until
-- then. agent_memory mirrors the Rust-side DDL exactly.
CREATE TABLE IF NOT EXISTS message_embeddings (
  id text PRIMARY KEY,
  conversation_id uuid NOT NULL,
  tenant_id text NOT NULL,
  content text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  embedding vector(384),
  embedded_at timestamptz
);
CREATE INDEX IF NOT EXISTS message_embeddings_hnsw
  ON message_embeddings USING hnsw (embedding vector_cosine_ops);
CREATE TABLE IF NOT EXISTS agent_memory (
  id text PRIMARY KEY,
  content text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  embedding vector(384),
  embedded_at timestamptz
);
CREATE INDEX IF NOT EXISTS agent_memory_embedding_hnsw
  ON agent_memory USING hnsw (embedding vector_cosine_ops);
