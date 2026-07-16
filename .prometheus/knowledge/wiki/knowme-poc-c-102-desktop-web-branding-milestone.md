---
type: Reference
id: knowme-poc-c-102-desktop-web-branding-milestone
title: KnowMe PoC C-102 desktop/web branding milestone
tags:
- hybrid-mobile-architecture
- knowme-poc
- tauri
- branding-ux
- codegen
- ci-verification
- graph-rag
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T01:42:23.246542+00:00
created_at: 2026-07-16T01:42:23.246542+00:00
updated_at: 2026-07-16T01:42:23.246542+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T01:25:30Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `execute_in_progress`
- **Commit:** [`2c169a6`](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/commit/2c169a6)

The phase remains focused on building a working KnowMe proof-of-concept app, following the revised scope captured in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md) and assessed in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md). The original codegen and CI verification objectives are supporting proof points rather than the primary deliverable.

## Phase goal

Build a proof-of-concept application under `apps/<name>/` using the repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web from one Rust core

Feature selection is guided by web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting verification goals

The following original phase goals remain in scope and must be proven through the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker:
  - `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC

## C-102 result

C-102 branding/UX round is complete, committed, and pushed to `main`.

Completed and verified follow-up items:

- Branded draggable titlebar
- File/View/Help menu with Exit
- Real KnowMe icon
  - Verified correct in the Dock via a built `.app` bundle
- Migrations startup fix

C-102 is now solid across desktop and web.

## Remaining planned work

Pending changes after C-102:

- **C-103:** live chat
- **C-104:** memory graph-RAG
- **C-105:** local model
- **C-106:** sync
- **C-107:** whisper
- **C-108:** MCP/agent
- **C-109:** settings
- **C-110:** CI

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification