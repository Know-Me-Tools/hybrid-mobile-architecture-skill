# 2026-07-15-c101-bootstrap-pillars

> Phase: phase-codegen-and-ci-verification · Status: proposed
> Assigned harness/model: claude/sonnet-5
> Depends on: none
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

Four-pillar bootstrap: check-env.sh rewrite (node24/bun/ts7/openspec/skill-system/flutter-beta), install-flutter.sh fix, frb 2.12 alignment, live run on this box

Derived from plan.md (full description, decisions, success criteria) and analysis.md /
assessment.md (pillar research, MoSCoW selection, gap analysis). Follows the CLAUDE.md
Development Philosophy: features first, clippy-only inner loop, boundary tests at
completion, verified dependency versions (Rule 22).

## What changes

See the plan.md entry for this change ID. Tasks expanded at execute time via /kbd-apply.

## Impact

- scripts/ changes stay backward-compatible (WARNING tier); generated files carry the
  TJ-ARCH-MOB-001 marker; scaffold fixes discovered in the PoC flow back to the scripts.
