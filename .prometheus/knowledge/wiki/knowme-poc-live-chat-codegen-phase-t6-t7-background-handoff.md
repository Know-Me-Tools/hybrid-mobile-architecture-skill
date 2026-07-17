---
type: Reference
id: knowme-poc-live-chat-codegen-phase-t6-t7-background-handoff
title: KnowMe PoC live chat codegen phase T6-T7 background handoff
tags:
- hybrid-mobile-architecture
- knowme-poc
- contentblock-streaming
- liter-llm
- flutter-rust-bridge
- tauri
- codegen
- ci-verification
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- hybrid-codegen-and-ci-verification-assessment-readiness
- c-103-execute-handoff-for-knowme-poc-live-chat-milestone
- knowme-poc-c-102-desktop-web-branding-milestone
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T08:13:18.434671+00:00
created_at: 2026-07-16T08:13:18.434671+00:00
updated_at: 2026-07-16T08:13:18.434671+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src/.claude/worktrees/gallant-blackburn-b9ccea`
- **Captured:** `2026-07-16T07:43:33Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

## Phase goal update

The phase remains under the PoC-first scope established in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), rather than the earlier pipeline-only verification framing in [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

### Primary goal

Build a working proof-of-concept app under `apps/<name>/` using the repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Feature scope is selected via web research into showcase-app best practices and 2026 on-device AI feasibility.

### Supporting verification goals

The original codegen and CI goals remain supporting objectives to be proven through the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - full `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC

## Current execution state

Work is continuing from the live-chat milestone described in [C-103 execute handoff for KnowMe PoC live chat milestone](/c-103-execute-handoff-for-knowme-poc-live-chat-milestone.md), following prior C-102 desktop/web branding progress in [KnowMe PoC C-102 desktop/web branding milestone](/knowme-poc-c-102-desktop-web-branding-milestone.md).

- Change: `2026-07-15-c103-chat-live-e2e`
- Completed and merged: **T1-T3**
- Dispatched to background agent: **T6+T7**
- Pending after background completion: **T8** and **T9**
- Requires user check before execution: **T10/T11** because they need:
  - a real provider API key
  - simulator go-ahead

## Background agent assignment

T6+T7 were dispatched to a background agent in an isolated worktree because the work requires designing new logic and touching multiple integration layers:

- `gen_ui_agent` crate, currently empty
- FFI layer
- Tauri command layer

Assigned scope:

- **T6:** liter-llm chat orchestration
- **T7:** `ContentBlock` streaming wiring

## Next action

Wait for the T6+T7 background agent to complete, then:

1. Review the diff.
2. Continue the per-task `kbd-apply` loop with **T8** for Flutter/Tauri live consumption.
3. Proceed to **T9** for build verification.
4. Check with the user before **T10/T11** due to provider-key and simulator requirements.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
