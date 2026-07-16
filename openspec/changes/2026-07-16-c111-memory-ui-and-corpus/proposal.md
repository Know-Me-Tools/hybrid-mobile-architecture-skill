# 2026-07-16-c111-memory-ui-and-corpus

> Phase: phase-codegen-and-ci-verification · Status: proposed
> Assigned harness/model: claude/sonnet-5
> Depends on: c104
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

C-104 delivered the memory/graph-RAG **backend** (gen_ui_db_graph intents, FastEmbedder,
AgentState wiring, FFI + Tauri bootstrap), verified end-to-end via a real Ollama live
test. Its user-facing half — the Memory tile UI, a demo-quality seed corpus, and the
hybrid-vs-vector dev toggle — was deliberately deferred at the user's direction
(scope decision 2026-07-16) so the backend could land and be verified on its own.

This change carries that deferred surface forward so it is tracked rather than lost in
C-104's archive.

## What changes

- Memory tile UI on both surfaces: ingest form → hybrid search results → tappable
  citation/memory ContentBlocks (Flutter + Tauri/React, per the ContentBlock contract).
- Seed corpus of curated notes so search returns demo-quality results out of the box.
- Hybrid-vs-vector dev toggle to demonstrate the RRF fusion lane against plain vector
  recall.

## Impact

> **CORRECTED 2026-07-16 at execute time (user-ratified).** Three claims below were
> written before C-105/C-113 landed and were wrong. Recorded rather than silently
> edited, because each one was load-bearing for how this change was scoped.

- ~~UI-only + fixture data; no change to the verified C-104 backend contract.~~
  **Not UI-only.** `GraphStore::memory_search` is hybrid-*only* — it embeds the query,
  runs the vector and BM25 lanes, and fuses them with native `search::rrf` in a single
  SurrealQL statement. There is no vector-only lane to toggle against, so the
  hybrid-vs-vector toggle needs a real backend addition threaded through
  store → `gen_ui_agent::memory` → both command surfaces → UI. The C-104 *contract*
  (ingest/search/graph_expand) is unchanged; its *surface* grows a mode parameter.
- ~~`memory_search` FFI returns `MemoryHit{id,name,score,snippet}`~~
  **The real type is `MemoryHit{id, text, kind, score}`** (`gen_ui_db_graph::store`).
  The `name`/`snippet` shape never existed on the Rust side after C-104; React had
  drifted to it behind an `as unknown as` cast, corrected in C-113.
- **The React half of the Memory UI largely landed in C-113**, which surfaced the
  `/memory` route, mounted the previously-orphaned `MemoryPanel`, styled it, and
  un-stubbed the desktop `memory_search`/`graph_expand` commands (they were still
  returning empty `Vec<String>` — C-104 wired the mobile FFI but left the Tauri
  commands behind). What remains here is the Flutter side, tappable ContentBlocks,
  the corpus, and the toggle.
- Seed corpus: authored from `docs/reference-app/` (the KnowMe functional spec and
  moodboard/user journeys) so search demos land on the product's real domain. It cannot
  reuse `gen_ui_db::relational::SeedBundle` — that emits SQL for the relational config
  store, while memory lives in SurrealDB and must be embedded at ingest.
