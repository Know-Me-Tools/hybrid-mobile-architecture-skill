<!-- source=primary; branch=main-pre-consolidation; original_sha256=34ddd063695185a89f2661e920fc129f13a552031b320dd6ffaf3eefd29a3f3d -->
---
type: Reference
id: knowme-poc-phase-analysis-complete-with-readme-and-reference-docs
title: KnowMe PoC phase analysis complete with README and reference docs
tags:
- hybrid-mobile-architecture
- knowme-poc
- codegen
- ci-verification
- flutter-rust-bridge
- pem-install
- tauri
- local-first-sync
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- bootstrap-prerequisite-analysis-for-knowme-poc-phase
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-15T23:00:06.644719+00:00
created_at: 2026-07-15T23:00:06.644719+00:00
updated_at: 2026-07-15T23:00:06.644719+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T22:52:56Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `analysis_complete`

The phase remains revised from pipeline-only verification to a working proof-of-concept deliverable, continuing the direction captured in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md), and [Bootstrap prerequisite analysis for KnowMe PoC phase](/bootstrap-prerequisite-analysis-for-knowme-poc-phase.md).

## Primary deliverable

Build a proof-of-concept app under `apps/<name>/` using the repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and demonstrate the broadest practical set of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web delivery from one Rust core

The exact feature subset is to be selected using web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting proof points

The original codegen/CI objectives now serve as proof points for the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Completed work

All work through this checkpoint is committed and pushed.

### README overhaul

The README now reflects the current repository architecture and intended direction:

- Documents the 13-crate layered workspace diagram, including the web/WASM leg.
- Defines `AGENT_BASE_RULES.md` as an enforced standard for:
  - Humans
  - Agents
  - Skills
  - Generated projects
- Records current toolchain versions:
  - Rust 1.95
  - Flutter beta
  - Node 24
  - TypeScript 7
- Adds a **Current status & roadmap** section covering:
  - Four bootstrap pillars
  - `apps/knowme-poc` demo narrative:
    1. Chat
    2. Voice note
    3. Whisper
    4. Graph-RAG memory
    5. Cited answers
    6. Offline behavior
    7. Sync
    8. Local GGUF
  - CI direction

### Git status

Pushed to `origin/main` as a clean fast-forward from `0cfb101` to `32d8a2f`.

Commits:

- `a705685` — `AGENT_BASE_RULES.md` made canonical and wired into all generation paths; TypeScript pillar updated to 7.0.2; bootstrap analysis artifacts added.
- `32d8a2f` — README overhaul and `docs/reference-app/` checked in with KnowMe spec and moodboard; secret-pattern scan clean.

## Next step

Run:

```bash
/kbd-plan phase-codegen-and-ci-verification
```

Planning order:

1. `C-B01` bootstrap
2. PoC scaffold and first codegen
3. MoSCoW feature selection
4. CI wiring

Plan-time decisions to resolve:

- PEM option
- Sync infrastructure
- Remediation-default flags

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification