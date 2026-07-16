---
type: Reference
id: knowme-poc-native-build-fixed-dart-freezed-3-blocker-identified
title: KnowMe PoC native build fixed; Dart freezed 3 blocker identified
tags:
- hybrid-mobile-architecture
- knowme-poc
- flutter
- tauri
- freezed
- codegen
- ci-verification
- pem
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- knowme-poc-c-102-desktop-web-branding-milestone
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T10:43:57.687462+00:00
created_at: 2026-07-16T10:43:57.687462+00:00
updated_at: 2026-07-16T10:43:57.687462+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T10:43:29Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

The phase remains governed by the revised PoC-first scope from [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md) and the assessed `apps/knowme-poc` plan in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md). Codegen and CI verification are supporting proof points, not the primary deliverable.

## Phase goal

Build a proof-of-concept app under `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the widest practical set of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

The feature subset is selected through web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting verification goals

The original codegen/CI scope remains required as proof that the PoC exercises the architecture:

- Run real codegen on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - full `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC

## Current build status

- Native/linker build now succeeds completely.
- All framework-linking issues are resolved.
- The latest remaining failure is a separate, pre-existing Dart-side bug in `prometheus_entity_management`.
- This unblocks the native/linker portion of the C-107/C-110 work tracked after the prior desktop/web milestone in [KnowMe PoC C-102 desktop/web branding milestone](/knowme-poc-c-102-desktop-web-branding-milestone.md).

## Dart/freezed 3.x blocker

`prometheus_entity_management` had generated-model source declarations incompatible with `freezed` 3.x. The affected classes were missing the `abstract` keyword now required by the `freezed` 3.x breaking change, confirmed against the upstream migration guide.

Affected classes:

- `EntityRecord`
- `ListResult`
- `FilterSpec`
- `SortSpec`
- `ViewDescriptor`

Remediation performed:

- Added the required `abstract` keyword to all five `freezed` classes.
- Regenerated code.
- Relaunched the build.

## Next actions

1. Await the current build result.
2. If no further blockers appear, confirm first successful app boot.
3. Mark T11 complete after boot confirmation.
4. Commit:
   - C-107/C-110 work
   - `freezed` compatibility fix
5. Move to T12 documentation.
6. Mark C-103 complete.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification