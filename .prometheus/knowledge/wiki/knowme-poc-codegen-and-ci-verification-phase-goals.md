---
type: Reference
id: knowme-poc-codegen-and-ci-verification-phase-goals
title: KnowMe PoC codegen and CI verification phase goals
tags:
- hybrid-mobile-architecture
- knowme-poc
- codegen
- ci-verification
- flutter-rust-bridge
- pem-install
- tauri
- flutter
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- c-103-execute-handoff-for-knowme-poc-live-chat-milestone
- hybrid-codegen-and-ci-verification-assessment-readiness
- knowme-poc-c-102-desktop-web-branding-milestone
sources:
- stdin
timestamp: 2026-07-16T08:16:35.362075+00:00
created_at: 2026-07-16T08:16:35.362075+00:00
updated_at: 2026-07-16T08:16:35.362075+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T08:13:25Z`
- **Source:** `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This phase follows the PoC-first scope established in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), assessed in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md), and continues execution after [C-103 execute handoff for KnowMe PoC live chat milestone](/c-103-execute-handoff-for-knowme-poc-live-chat-milestone.md). It supersedes the earlier pipeline-only framing captured in [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

## Revised phase goal

The phase end result is a working proof-of-concept application, not only pipeline verification. The original codegen and CI goals remain supporting objectives that the PoC must prove in passing.

## Primary deliverable

Build a proof-of-concept app under `apps/<name>/` using the repository scaffolds and skills, based on the KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Feature subset selection should be informed by web research into showcase-app best practices and 2026 on-device AI feasibility.

## Supporting proof points

The original codegen and CI verification scope remains required, but as evidence for the working PoC:

- Run the real codegen pipeline on the PoC:
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

## Execution status

Current KBD position indicates the phase is in execution:

```text
Position: phase-codegen-and-ci-verification
status: executing
```

Recent related execution milestones include [KnowMe PoC C-102 desktop/web branding milestone](/knowme-poc-c-102-desktop-web-branding-milestone.md) and the live-chat handoff milestone, both within the same PoC-first phase.

# Citations

1. stdin
