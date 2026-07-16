-- TJ-ARCH-MOB-001 compliant
-- Server-side schema for the C-106 local-first sync demo.
--
-- These are the tables Electric publishes as shapes and that `gen_ui_db::sync`'s
-- consumer materialises locally (one ShapeSpec per table — keep this list identical
-- to the web app's pglite-sync shape list so both surfaces converge on the same rows).
--
-- Contract notes (from gen_ui_db::sync::seam::RowChange):
--   * every synced table needs a single, stable primary key — it becomes the shape's
--     `key`, which is what the local apply_batch upserts on and what the write queue's
--     idempotency key is derived from. UUID text keys are generated client-side so an
--     OFFLINE insert already knows its own id (no server round-trip to learn it) —
--     that is what makes the airplane-mode replay converge instead of duplicating.
--   * updated_at drives last-write-wins on replay. The PoC does not do CRDT merge;
--     that is honest for a demo and must stay labeled as such.

CREATE TABLE IF NOT EXISTS notes (
  id          TEXT PRIMARY KEY,          -- client-generated UUID (see above)
  title       TEXT NOT NULL DEFAULT '',
  body        TEXT NOT NULL DEFAULT '',
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted     BOOLEAN NOT NULL DEFAULT false   -- soft delete: a shape can't ship a
                                               -- row that no longer exists, so the
                                               -- delete has to be a visible row change
);

CREATE TABLE IF NOT EXISTS memories (
  id          TEXT PRIMARY KEY,
  text        TEXT NOT NULL,
  kind        TEXT NOT NULL DEFAULT 'note',
  entity      TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted     BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS notes_updated_at_idx    ON notes (updated_at);
CREATE INDEX IF NOT EXISTS memories_updated_at_idx ON memories (updated_at);
