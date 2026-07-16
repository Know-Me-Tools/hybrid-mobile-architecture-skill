---
type: Reference
id: knowme-poc-pr-4-status-and-title-bar-skill-verification
title: 'KnowMe PoC PR #4 status and title bar skill verification'
tags:
- hybrid-mobile-architecture
- knowme-poc
- tauri
- title-bar
- mobile-navigation
- mistral-rs
- webllm
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-phase-goals-and-c-105-research-wait-state
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T18:06:19.629524+00:00
created_at: 2026-07-16T18:06:19.629524+00:00
updated_at: 2026-07-16T18:06:19.629524+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src/.claude/worktrees/pensive-greider-2e206c`
- **Captured:** `2026-07-16T17:24:04Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`
- **Open PR:** [PR #4](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/pull/4)

This session continues the PoC-first direction documented in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md): the phase exit criterion is a working proof-of-concept app, with codegen and CI verification as supporting proof points.

## Phase objective

The phase end result is a **working proof-of-concept app in `apps/<name>/`**, not only pipeline verification.

The PoC is based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core
- Feature subset selected via web research on showcase-app best practices and 2026 on-device AI feasibility

## Supporting verification goals

The original codegen and CI goals remain supporting objectives to be proven through the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## PR #4 status

PR #4 is open with:

- Title bar skill delivered.
- Mobile navigation tracked but not implemented.
- C-105 wait-state resolved as stale.

## C-105 local AI wait-state resolution

The previous C-105 wait-state was stale. The wiki note was a phase snapshot, not an unresolved research question. The research decision had already been made on `2026-07-15`:

- Native: `mistral.rs` fork
- Web: WebLLM

A concurrent session also landed T1–T8 on `main` while this session was active:

- Commits: `79bb7af`, `dddfe85`
- Fork pinned.
- Dependency conflicts resolved:
  - `regex`
  - `safetensors` / Candle `Dtype` mismatch, patched to the fork's documented fallback
- `MistralEngine` implemented.
- WebLLM lane implemented.
- `design.md` written.

Decision: mark C-105 `in_progress` and avoid racing the concurrent session.

Remaining C-105 work:

- T9: plugin commands
- T10: agent lane selection
- T11: cloud↔local toggle plus tokens/second display
- T12: e2e smoke test

This updates the prior C-105 state captured in [KnowMe PoC phase goals and C-105 research wait state](/knowme-poc-phase-goals-and-c-105-research-wait-state.md).

## C-112 title bar skill delivered and verified

C-112 is complete. The PoC title bar implementation is considered strong and already handles browser compatibility correctly.

Key implementation rule:

- Every Tauri call is gated behind `isTauri()` because Tauri imports throw at module scope in a browser.

Documentation changes made:

- Surface-gating requirement moved to the skill's opening section.
- Added a per-surface decision table.
- Added explicit rule: **never default the desktop title bar onto web or mobile**.
- Documented allowed alternatives:
  - No bar
  - Plain web header carrying brand tokens but no window controls
  - Mobile app bar

Drag behavior captured:

- `data-tauri-drag-region` alone leaves dead zones around a centered lockup.
- Explicit `startDragging()` is load-bearing, not redundant.

Registration and verification:

- Registered in the scaffold script.
- Registered in the activation hook triggers.
- Registered in all three documentation lists.
- Verified installation into a scratch project.

## C-113 mobile navigation tracked but deferred

C-113 is tracked but not implemented.

Reason for deferral:

- The user requested a consistent PWA-by-platform rule.
- That platform policy should not be decided unilaterally.
- The task list requires research first so current iOS HIG and Material 3 guidance bind the design choice.

Next step: decide the PWA/platform navigation rule, then implement C-113.

## OpenSpec caveat

`openspec validate` errors with:

```text
must have at least one delta
```

Observed behavior:

- The error occurs on every change in this phase.
- None of the phase changes carry `specs/` delta files.
- The issue is not blocking archives currently.

Engineering concern:

- Phase proposals are not producing spec deltas.
- This should be fixed before `/kbd-reflect`.

## Recommended next actions

1. Merge PR #4.
2. Choose one follow-up path:
   - Decide C-113's PWA/platform navigation rule and implement mobile navigation.
   - Pick up C-106, C-108, C-109, or C-111.
3. Leave C-105 T9–T12 to the session already owning that work.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification