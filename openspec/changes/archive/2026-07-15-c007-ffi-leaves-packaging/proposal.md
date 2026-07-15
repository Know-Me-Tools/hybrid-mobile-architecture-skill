# 2026-07-15-c007-ffi-leaves-packaging

> Phase: scaffold-full-hybrid-project · Wave: see plan.md · Status: proposed
> Assigned harness/model: opencode / glm-5.2 (escalate frb issues to sonnet-5)
> Depends on: c001, c002

## Why

FFI leaves + publishing scaffolds: gen_ui_ffi (frb), tauri-plugin-gen-ui, gen_ui_wasm, package skeletons

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
