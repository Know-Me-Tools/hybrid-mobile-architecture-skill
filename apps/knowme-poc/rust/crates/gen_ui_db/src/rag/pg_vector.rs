// TJ-ARCH-MOB-001 compliant
//! pgvector-backed [`VectorStore`] + embed-on-write backfill. One impl serves
//! desktop (pglite-oxide) and cloud/test Postgres — same wire protocol, same
//! SQL as the web tier's pgvector-in-PGlite (one query dialect, C-123).
//!
//! Embeddings bind as a text literal cast to `::vector` (pgvector's canonical
//! `[x,y,…]` form) so no client-side pgvector type dependency is needed.

use super::engine::EMBEDDING_DIM;
use super::{Embedder, Provenance, RetrievalScope, VectorHit, VectorStore};
use async_trait::async_trait;
use gen_ui_types::error::{CoreError, CoreResult};
use sqlx::{PgPool, Row};

/// Additive DDL (LFS-INV-3) for the chat + agent-memory vector surface.
/// Applied via the store's migration/seed path. `vector` must be available:
/// pglite-oxide/Postgres ship it; web PGlite needs the
/// `@electric-sql/pglite-pgvector` extension passed at `PGlite.create`
/// (verified empirically — NOT bundled in the core wasm).
pub const MESSAGES_EMBEDDING_DDL: &str = "CREATE EXTENSION IF NOT EXISTS vector;\nALTER TABLE messages ADD COLUMN IF NOT EXISTS embedding vector(384);\nALTER TABLE messages ADD COLUMN IF NOT EXISTS embedded_at timestamptz;\nCREATE INDEX IF NOT EXISTS messages_embedding_hnsw ON messages USING hnsw (embedding vector_cosine_ops);\nCREATE TABLE IF NOT EXISTS agent_memory (\n  id TEXT PRIMARY KEY,\n  content TEXT NOT NULL,\n  updated_at timestamptz NOT NULL DEFAULT now(),\n  embedding vector(384),\n  embedded_at timestamptz\n);\nCREATE INDEX IF NOT EXISTS agent_memory_embedding_hnsw ON agent_memory USING hnsw (embedding vector_cosine_ops)";

pub struct PgVectorStore {
    pool: PgPool,
}

impl PgVectorStore {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

fn vector_literal(embedding: &[f32]) -> CoreResult<String> {
    if embedding.len() != EMBEDDING_DIM {
        return Err(CoreError::Terminal(format!(
            "embedding has {} dims; the standard is {EMBEDDING_DIM} (references/sync/client-rag.md)",
            embedding.len()
        )));
    }
    let joined = embedding
        .iter()
        .map(|v| v.to_string())
        .collect::<Vec<_>>()
        .join(",");
    Ok(format!("[{joined}]"))
}

#[async_trait]
impl VectorStore for PgVectorStore {
    async fn search(
        &self,
        scope: &RetrievalScope,
        embedding: &[f32],
        limit: usize,
    ) -> CoreResult<Vec<VectorHit>> {
        let literal = vector_literal(embedding)?;
        // Table names are compile-time constants per scope — never interpolated
        // from input (the PgLocalStore allow-list lesson applies here too).
        let (sql, conversation): (&str, Option<&str>) = match scope {
            RetrievalScope::ThisConversation { conversation_id } => (
                "SELECT id, content, 1 - (embedding <=> $1::vector) AS score, \
                 to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SSZ') AS updated_at \
                 FROM messages WHERE embedding IS NOT NULL AND conversation_id = $3 \
                 ORDER BY embedding <=> $1::vector LIMIT $2",
                Some(conversation_id.as_str()),
            ),
            RetrievalScope::AllConversations => (
                "SELECT id, content, 1 - (embedding <=> $1::vector) AS score, \
                 to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SSZ') AS updated_at \
                 FROM messages WHERE embedding IS NOT NULL \
                 ORDER BY embedding <=> $1::vector LIMIT $2",
                None,
            ),
            RetrievalScope::AgentMemory => (
                "SELECT id, content, 1 - (embedding <=> $1::vector) AS score, \
                 to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SSZ') AS updated_at \
                 FROM agent_memory WHERE embedding IS NOT NULL \
                 ORDER BY embedding <=> $1::vector LIMIT $2",
                None,
            ),
            // Fail loudly: vault content lives in the local-only vault index,
            // never in server-synced tables (an embedding of `local` data is
            // `local` — LFS-INV-4).
            RetrievalScope::Vault => {
                return Err(CoreError::Terminal(
                    "vault retrieval uses the local-only vault index, not the synced store".into(),
                ))
            }
        };

        let table = match scope {
            RetrievalScope::AgentMemory => "agent_memory",
            _ => "messages",
        };
        let mut query = sqlx::query(sql).bind(&literal).bind(limit as i64);
        if let Some(conversation_id) = conversation {
            query = query.bind(conversation_id);
        }
        let rows = query
            .fetch_all(&self.pool)
            .await
            .map_err(|e| CoreError::Io(e.to_string()))?;

        Ok(rows
            .into_iter()
            .map(|row| VectorHit {
                source_id: row.get::<String, _>("id"),
                text: row.get::<String, _>("content"),
                score: row.get::<f64, _>("score") as f32,
                provenance: Provenance {
                    table: table.to_string(),
                    privacy_class: "trusted".to_string(),
                    updated_at: row.get::<String, _>("updated_at"),
                },
            })
            .collect())
    }
}

/// Embed-on-write catch-up: embed up to `limit` rows whose `embedded_at` is
/// NULL, in one pass per table. Idempotent — rerunning embeds only what is
/// still uncovered; UI never waits on this (LFS: retrieval just sees fewer
/// candidates until backfill completes).
pub async fn backfill_embeddings(
    pool: &PgPool,
    embedder: &dyn Embedder,
    limit: usize,
) -> CoreResult<usize> {
    let mut embedded = 0usize;
    for table in ["messages", "agent_memory"] {
        // Constant table names (see search); content drives the embedding.
        let rows = sqlx::query(&format!(
            "SELECT id, content FROM {table} WHERE embedded_at IS NULL AND content IS NOT NULL LIMIT $1"
        ))
        .bind(limit as i64)
        .fetch_all(pool)
        .await
        .map_err(|e| CoreError::Io(e.to_string()))?;

        for row in rows {
            let id = row.get::<String, _>("id");
            let content = row.get::<String, _>("content");
            let literal = vector_literal(&embedder.embed(&content).await?)?;
            sqlx::query(&format!(
                "UPDATE {table} SET embedding = $1::vector, embedded_at = now() WHERE id = $2"
            ))
            .bind(&literal)
            .bind(&id)
            .execute(pool)
            .await
            .map_err(|e| CoreError::Io(e.to_string()))?;
            embedded += 1;
        }
    }
    Ok(embedded)
}

#[cfg(test)]
mod tests {
    use super::*;

    // Dimension discipline is enforced before any SQL runs.
    #[test]
    fn rejects_wrong_dimension_embeddings() {
        assert!(vector_literal(&[0.1; 3]).is_err());
        let ok = vector_literal(&[0.5; EMBEDDING_DIM]).expect("384 dims accepted");
        assert!(ok.starts_with("[0.5,"));
        assert!(ok.ends_with("]"));
    }
}
