<!-- source=primary; branch=main-pre-consolidation; original_sha256=5a6b08fa8bccad0b44b0dae821d46d6642f76484e1916186d450a7a87cee0328 -->
---
type: Reference
id: hybrid-scaffold-assessment-completes-with-11-crate-rust-workspace-plan
title: Hybrid scaffold assessment completes with 11-crate Rust workspace plan
tags:
- hybrid-mobile-architecture
- scaffolding
- rust-workspace
- flutter-rust-bridge
- wasm
- compile-speed
- testing-philosophy
- tauri
links:
- hybrid-mobile-architecture-scaffold-phase-initialization
- hybrid-mobile-scaffold-phase-assessment-readiness
- hybrid-mobile-scaffold-assessment-identifies-wasm-and-packaging-gaps
- hybrid-scaffold-assessment-waits-on-remaining-research-agents
- hybrid-scaffold-assessment-receives-testing-policy-research
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T17:40:30.464649+00:00
created_at: 2026-07-15T17:40:30.464649+00:00
updated_at: 2026-07-15T17:40:30.464649+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T17:22:54Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `assessment_complete`
- **Assessment report:** `.kbd-orchestrator/phases/scaffold-full-hybrid-project/assessment.md`

This completes the assessment flow that began with [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md) and progressed through [Hybrid Mobile scaffold phase assessment readiness](/hybrid-mobile-scaffold-phase-assessment-readiness.md), [Hybrid Mobile scaffold assessment identifies WASM and packaging gaps](/hybrid-mobile-scaffold-assessment-identifies-wasm-and-packaging-gaps.md), [Hybrid scaffold assessment waits on remaining research agents](/hybrid-scaffold-assessment-waits-on-remaining-research-agents.md), and [Hybrid scaffold assessment receives testing policy research](/hybrid-scaffold-assessment-receives-testing-policy-research.md).

## Phase goals

- Create a complete generated instance of the hybrid mobile architecture:
  - Flutter mobile application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts from the reference library.
- Verify generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment satisfies minimum tool version requirements.

## Assessment result

`kbd-assess` completed for `scaffold-full-hybrid-project`.

Three deep-research passes informed the assessment:

1. Compile-speed research
2. Testing-philosophy research
3. UI/UX skills research

Headline result: **six gaps share one root cause**. The existing monolithic `gen_ui_core` crate blocks WASM support, slows compilation, prevents concurrent worktrees, and prevents publishing. The proposed remedy is a layered Rust workspace split into 11 crates.

## Required workspace architecture

Replace the monolithic `gen_ui_core` crate with an **11-crate layered workspace**:

```text
gen_ui_types        # pure, wasm-safe foundation; trait boundaries land here first
  -> protocol
  -> client
  -> mcp
  -> db
  -> inference
  -> agent
      -> gen_ui_ffi              # Flutter FFI leaf
      -> tauri-plugin-gen-ui     # Tauri leaf
      -> gen_ui_wasm             # Web/WASM leaf
```

Key design requirements:

- `gen_ui_types` must remain pure and WASM-safe.
- Trait boundaries must be defined first in `gen_ui_types`.
- Each L2 crate must be independently buildable to support worktree-parallel development.
- Platform-specific surfaces must remain leaf crates:
  - Flutter: `gen_ui_ffi`
  - Tauri: `tauri-plugin-gen-ui`
  - Web: `gen_ui_wasm`

## Critical FFI panic-profile bug

The existing scaffold sets:

```toml
panic = "abort"
```

in the release profile. This is incorrect for FFI targets because it breaks `flutter_rust_bridge` panic-to-Dart-exception conversion and would hard-kill the mobile app on any panic.

Required policy:

- FFI targets must use unwind panic behavior.
- `panic = "abort"` is allowed only for the WASM profile.

```toml
# FFI/mobile release profile
panic = "unwind"

# WASM-only profile
panic = "abort"
```

## Compile-speed policy

Cranelift findings:

- Useful only for the Apple Silicon host development loop.
- Requires nightly.
- Expected debug codegen speedup: approximately 20–40%.
- Does **not** support iOS cross-compilation.
- Does **not** support Android cross-compilation.
- Does **not** support `wasm32`.

Decision:

- Put Cranelift behind an opt-in `dev-fast` profile.
- Do not make Cranelift the default.

Higher-value everyday compile-speed controls:

- Dependency-optimized dev profiles.
- `line-tables-only` debuginfo.
- `bacon`-driven clippy-only inner loop.
- Cross-target `cargo check` gates.

## Codified engineering philosophy

The assessment codified project philosophy in:

- `CLAUDE.md`
- `AGENTS.md`

Policies now recorded there:

- Correctness comes from:
  - the 40 architecture rules
  - Rust skills
  - compiler-as-harness workflows
- Speed comes from minimal compilation.
- Feature delivery policy: **features first, test later**.
- Testing policy is backed by:
  - MSR 2026 over-mocking study
  - matklad's testing canon
- Internal mocks are prohibited.
- Snapshot tests are preferred where appropriate.
- Add 3–5 behavior tests per completed feature.
- Stop after two failed test-fix attempts.
- Architecture must support worktree-parallel development.
- UI/UX skill use is mandatory:
  - 10-item external shortlist
  - 5 project-local skills to author
- Publishing map requires:
  - 5+ Rust crates
  - 2 `pub.dev` packages
  - 3 npm packages

## Proposed changes

Eight changes were proposed for `/kbd-plan` as `C-1` through `C-8`.

Known sequencing:

- `C-1`: workspace rewrite; must land first.
- `C-2` through `C-5`: can run in parallel worktrees after `C-1`.
- `C-6` and `C-7`: independent.
- `C-8`: philosophy documentation; already completed.

## Next action

Run:

```bash
/kbd-plan scaffold-full-hybrid-project
```

Purpose: convert the 8 recommended changes into an executable plan, starting with the workspace rewrite.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project