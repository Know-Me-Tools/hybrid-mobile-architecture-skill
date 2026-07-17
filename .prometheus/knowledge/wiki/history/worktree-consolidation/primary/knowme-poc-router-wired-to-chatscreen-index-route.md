<!-- source=primary; branch=main-pre-consolidation; original_sha256=204c0a6912bd7d88296618187b3ec3d0db1dec41fe97262cf3ee1ebfb33d12eb -->
---
type: Reference
id: knowme-poc-router-wired-to-chatscreen-index-route
title: KnowMe PoC router wired to ChatScreen index route
tags:
- hybrid-mobile-architecture
- knowme-poc
- tauri
- router
- chat-ui
- codegen
- ci-verification
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-c-102-desktop-web-branding-milestone
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
sources:
- stdin
timestamp: 2026-07-16T11:41:29.846451+00:00
created_at: 2026-07-16T11:41:29.846451+00:00
updated_at: 2026-07-16T11:41:29.846451+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T11:30:11Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`
- **Source:** `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`

The phase remains under the revised PoC-first scope from [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md): build a working proof-of-concept app in `apps/<name>/`, with codegen and CI verification as supporting proof points. It follows the KnowMe PoC implementation trajectory recorded in [KnowMe PoC C-102 desktop/web branding milestone](/knowme-poc-c-102-desktop-web-branding-milestone.md) and the assessment in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md).

## Phase goal

Build a working KnowMe proof-of-concept app using repository scaffolds and skills, based on reference materials in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase a broad practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web from one Rust core

## Supporting verification goals

The original codegen/CI phase goals remain supporting objectives demonstrated through the PoC:

- Run the real codegen pipeline:
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

## Router issue found and fixed

A pre-existing scaffold gap was identified: the router was never wired to a real application route.

### Fault

- The root component rendered a literal placeholder string: `"outlet placeholder"`.
- A `protectedRoute` redirected to `/login`.
- `/login` did not exist.
- This prevented the app from opening to a usable UI.
- The issue was unrelated to the previously handled lock-race fix.

### Fix

- Added a `ChatScreen`.
- Wired `ChatScreen` as the index route.
- `ChatScreen` uses already-built chat infrastructure:
  - `ChatTranscript`
  - `useChat`
  - `chatStore`
- Type-check is clean after the route wiring change.

## Current execution state

- App relaunch is in progress with the router fix applied.
- Next validation step: wait for rebuild completion and confirm the desktop window opens with the actual chat UI visible.

# Citations

1. stdin