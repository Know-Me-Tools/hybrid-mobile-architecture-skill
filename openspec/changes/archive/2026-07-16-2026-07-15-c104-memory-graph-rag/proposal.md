# 2026-07-15-c104-memory-graph-rag

> Phase: phase-codegen-and-ci-verification · Status: proposed
> Assigned harness/model: claude/sonnet-5
> Depends on: c103
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

M2 memory: gen_ui_db_graph intents + fastembed + seed corpus; ingest -> hybrid search -> cited answers + graph panel

Derived from plan.md (full description, decisions, success criteria) and analysis.md /
assessment.md (pillar research, MoSCoW selection, gap analysis). Follows the CLAUDE.md
Development Philosophy: features first, clippy-only inner loop, boundary tests at
completion, verified dependency versions (Rule 22).

## What changes

See the plan.md entry for this change ID. Tasks expanded at execute time via /kbd-apply.

## Impact

- scripts/ changes stay backward-compatible (WARNING tier); generated files carry the
  TJ-ARCH-MOB-001 marker; scaffold fixes discovered in the PoC flow back to the scripts.
