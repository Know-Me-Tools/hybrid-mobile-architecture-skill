# 2026-07-15-c110-ci

> Phase: phase-codegen-and-ci-verification · Status: proposed
> Assigned harness/model: codex/gpt-5.6-sol
> Depends on: c102 (parallel lane)
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

GitHub Actions: clippy, audit.sh all, boundary tests, dart analyze post-codegen, PoC build job

Derived from plan.md (full description, decisions, success criteria) and analysis.md /
assessment.md (pillar research, MoSCoW selection, gap analysis). Follows the CLAUDE.md
Development Philosophy: features first, clippy-only inner loop, boundary tests at
completion, verified dependency versions (Rule 22).

## What changes

See the plan.md entry for this change ID. Tasks expanded at execute time via /kbd-apply.

## Impact

- scripts/ changes stay backward-compatible (WARNING tier); generated files carry the
  TJ-ARCH-MOB-001 marker; scaffold fixes discovered in the PoC flow back to the scripts.
