# 2026-07-15-c107-whisper-scribe

> Phase: phase-codegen-and-ci-verification · Status: proposed
> Assigned harness/model: codex/gpt-5.6-sol
> Depends on: c103 (parallel lane)
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

S1 Audio Scribe: whisper-rs + whisper-tiny on-device transcription -> save-to-memory (all 3 platforms)

Derived from plan.md (full description, decisions, success criteria) and analysis.md /
assessment.md (pillar research, MoSCoW selection, gap analysis). Follows the CLAUDE.md
Development Philosophy: features first, clippy-only inner loop, boundary tests at
completion, verified dependency versions (Rule 22).

## What changes

See the plan.md entry for this change ID. Tasks expanded at execute time via /kbd-apply.

## Impact

- scripts/ changes stay backward-compatible (WARNING tier); generated files carry the
  TJ-ARCH-MOB-001 marker; scaffold fixes discovered in the PoC flow back to the scripts.
