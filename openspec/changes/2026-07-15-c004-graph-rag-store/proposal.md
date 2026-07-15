# 2026-07-15-c004-graph-rag-store

> Phase: scaffold-full-hybrid-project · Wave: see plan.md · Status: proposed
> Assigned harness/model: claude-code / sonnet-5
> Depends on: c001

## Why

gen_ui_db graph: SurrealDB 3.2 embedded hybrid graph-RAG (HNSW+BM25+RRF), fastembed intents

Derived from .kbd-orchestrator/phases/scaffold-full-hybrid-project/plan.md (full change
description, libraries, and rationale there) and analysis.md (§ library verdicts,
per-platform matrix). Follows CLAUDE.md Development Philosophy: features first,
boundary tests at completion, clippy-only inner loop.

## What changes

See plan.md entry for this change ID. Tasks to be expanded at execute time
(/opsx:ff or /openspec-continue-change).

## Impact

- Constraints: scripts/ backward compatibility (WARNING tier); generated files carry
  "// TJ-ARCH-MOB-001 compliant"; layer contracts enforced.
