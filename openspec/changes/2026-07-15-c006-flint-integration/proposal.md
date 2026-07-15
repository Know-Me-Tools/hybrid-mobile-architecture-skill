# 2026-07-15-c006-flint-integration

> Phase: scaffold-full-hybrid-project · Wave: see plan.md · Status: proposed
> Assigned harness/model: claude-code / sonnet-5 (+kimi k2.7 API-digestion sub-lane)
> Depends on: c001

## Why

Flint integration layer: gate auth/tokens, forge Quarry+MCP+AG-UI, frf-sdk-rust spine

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
