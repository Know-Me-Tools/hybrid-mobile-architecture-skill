---
type: Reference
id: knowme-poc-wasm-cfg-split-fix-already-merged-on-main
title: KnowMe PoC wasm cfg-split fix already merged on main
tags:
- hybrid-mobile-architecture
- knowme-poc
- wasm
- cfg-split
- git-status
- session-logs
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-live-boot-verification-passed-on-fresh-tauri-config-db
- knowme-poc-tauri-launch-wait-loop-pending-interactive-verification
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T11:49:30.344377+00:00
created_at: 2026-07-16T11:49:30.344377+00:00
updated_at: 2026-07-16T11:49:30.344377+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src/.claude/worktrees/pensive-greider-2e206c`
- **Captured:** `2026-07-16T11:41:10Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md), after live Tauri verification in [KnowMe PoC live boot verification passed on fresh Tauri config DB](/knowme-poc-live-boot-verification-passed-on-fresh-tauri-config-db.md) and adjacent wait-loop state in [KnowMe PoC Tauri launch wait-loop pending interactive verification](/knowme-poc-tauri-launch-wait-loop-pending-interactive-verification.md).

## Revised phase objective

The phase deliverable is a working proof-of-concept application, not just pipeline verification.

### Primary goal

Build a proof-of-concept app in `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Feature subset selection is guided by web research on showcase-app best practices and 2026 on-device AI feasibility.

### Supporting goals

The original codegen/CI goals remain supporting objectives demonstrated through the PoC:

- Run the real codegen pipeline:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker:
  - `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Current finding

No code commit or PR is needed for the wasm-related fix discussed in this session.

### Verified repository state

- The `embed_blocking` cfg-split in `gen_ui_db_graph/src/store.rs` was applied in the main checkout:
  - `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- Another session already included the fix in commit:
  - `60cb949` — `feat(c103): live chat e2e on desktop + iOS…`
- That commit is already on `main` and pushed to:
  - `github.com:Know-Me-Tools/hybrid-mobile-architecture-skill`
- Local `main` and `origin/main` are identical.
- There is no branch delta from this worktree that would justify opening a PR for the code fix.

## Worktree state

- Current branch: `claude/pensive-greider-2e206c`
- Branch-specific commits: none
- Session-related uncommitted files are limited to `.prometheus/` knowledge-wiki/session-log files.
- The main checkout also contains unrelated `.prometheus` files and `docs/competitive-analysis-2026-07-16.md`, not authored in this session.

## Permission-gated files

An attempt was made to commit `.prometheus` wiki/session-log files solely to create a PRable branch. The permission gate blocked this because session logs are treated as sensitive and the user did not explicitly authorize committing them.

Decision: do not work around the permission gate. Commit and PR those files only if explicitly requested.

## Next action

- If the user explicitly authorizes committing `.prometheus` wiki/session logs, commit them on `claude/pensive-greider-2e206c` and open a PR.
- Otherwise, no action is needed for the wasm fix because it is already committed, pushed, and live on `main`.
- Remaining phase work: step 3, `/kbd-apply 2026-07-15-c103-chat-live-e2e`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification