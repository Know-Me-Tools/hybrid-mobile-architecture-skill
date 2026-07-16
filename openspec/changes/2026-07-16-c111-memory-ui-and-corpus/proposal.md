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

- UI-only + fixture data; no change to the verified C-104 backend contract.
- `memory_search` FFI returns `MemoryHit{id,name,score,snippet}`; the frontend consumes
  that shape directly (see C-103 decision-log note on the former `Vec<String>` stub).
