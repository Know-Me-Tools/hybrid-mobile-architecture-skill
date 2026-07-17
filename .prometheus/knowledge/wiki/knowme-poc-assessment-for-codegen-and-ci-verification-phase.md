---
type: Reference
id: knowme-poc-assessment-for-codegen-and-ci-verification-phase
title: KnowMe PoC assessment for codegen and CI verification phase
tags:
- hybrid-mobile-architecture
- knowme-poc
- codegen
- ci-verification
- flutter-rust-bridge
- pem-install
- graph-rag
- local-first-sync
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- hybrid-codegen-and-ci-verification-assessment-readiness
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-15T22:36:14.155038+00:00
created_at: 2026-07-15T22:36:14.155038+00:00
updated_at: 2026-07-15T22:36:14.155038+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T22:29:16Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `assessment_complete`
- **Assessment report:** `.kbd-orchestrator/phases/phase-codegen-and-ci-verification/assessment.md`

The phase scope was revised from pipeline-only verification to delivering a working proof-of-concept application. This completes `kbd-assess` for the phase and follows the earlier [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), which superseded the pre-assessment pipeline focus in [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

## Revised phase goal

Build `apps/knowme-poc` from the KnowMe reference documentation under `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC is the primary deliverable. Codegen, dependency installation, target builds, and CI verification are supporting proof points that must be demonstrated through the app.

## Required capability narrative

Research concluded that the showcase should be **one continuous demo narrative, not a tile grid**. The recommended flow is:

1. Record a voice note.
2. Run on-device transcription.
3. Auto-ingest the transcript into the memory graph.
4. Ask chat a question.
5. Stream a cited answer.
6. Demonstrate airplane-mode functionality.
7. Show desktop sync.

Rationale:

- Wonderous-style showcase apps succeed by presenting a coherent experience rather than isolated samples.
- Linearlite demonstrates one workflow scaled well.
- Jan and LM Studio prove a minimal model/chat loop is more credible than broad but shallow feature chrome.

## MoSCoW feature selection

### Must

- **Chat:** streaming `ContentBlock` spine.
- **Memory:** SurrealDB graph-RAG with cited answers and seed corpus.
- **Sync:** local-first sync for one entity type.
- **Models:** minimal model management:
  - Download GGUF.
  - Switch cloud ↔ local.
  - Use Metal on macOS.

### Should

- **Audio Scribe:** Whisper-based transcription; selected because it is the AI feature that works across all three target surfaces.
- **MCP skill:** one minimal skill integration.
- **Hands agent:** one manually triggered agent.
- **Mobile local model:** tiny CPU model on mobile.

### Won't

- **Vision:** excluded because candle Metal is broken on iOS.
- **Scheduled mobile agents:** excluded because iOS background execution limits would make the demo dishonest.
- **Registry/management UIs:** excluded as UI chrome without sufficient crate coverage.

## Supporting verification goals

The original codegen/CI goals remain in scope, but as evidence produced by the PoC:

- Run the real codegen pipeline on `apps/knowme-poc`:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM package install blocker:
  - Blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Key gaps identified during assessment

1. **Flutter Rust Bridge version mismatch**
   - Codegen tool: `flutter_rust_bridge_codegen` `2.11`.
   - Crate: `2.12`.
   - Must align before running the pipeline.

2. **Codegen pipeline has not run**
   - The real codegen pipeline is the highest-information next step.
   - It must run against the PoC rather than remaining theoretical.

3. **PEM install blocker requires a plan-time decision**
   - `@prometheus-ags/entity-graph-core@workspace:*` cannot resolve outside the PEM monorepo.
   - Assessment notes that three resolution options were laid out in the full report.

4. **Rust intent stubs need real wiring**
   - Required concrete integrations:
     - Chat SSE / streaming
     - Graph-RAG
     - GGUF model handling
     - `whisper-rs` as a new dependency

5. **No CI is wired yet**
   - CI must run clippy, audit, and boundary suites against the PoC on every push.

## Recommended implementation sequence

Use `/kbd-plan phase-codegen-and-ci-verification` to convert the assessment into an ordered change list. Suggested sequence:

1. Fix toolchain/version alignment.
2. Scaffold `apps/knowme-poc`.
3. Run first real codegen.
4. Implement Must features in order:
   - M1
   - M2
   - M4
   - M3
5. Add Should features.
6. Wire CI.

Plan-time decisions required:

- PEM dependency unblock path.
- Sync infrastructure approach.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification

## Consolidated source variants

### Variant from `agent-a6bf13877ab890979`

Original path: `.prometheus/knowledge/wiki/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md`  
Original SHA-256: `e13696070e37e7697a6d9cb182b9fc4e0de2ec4a64c06576dc61ae4d1e813d5e`

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-15T22:29:16Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `assessment_complete`
- **Assessment report:** `.kbd-orchestrator/phases/phase-codegen-and-ci-verification/assessment.md`

The phase scope was revised from pipeline-only verification to delivering a working proof-of-concept application. This completes `kbd-assess` for the phase and follows the earlier [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), which superseded the pre-assessment pipeline focus in [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

## Revised phase goal

Build `apps/knowme-poc` from the KnowMe reference documentation under `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC is the primary deliverable. Codegen, dependency installation, target builds, and CI verification are supporting proof points that must be demonstrated through the app.

## Required capability narrative

Research concluded that the showcase should be **one continuous demo narrative, not a tile grid**. The recommended flow is:

1. Record a voice note.
2. Run on-device transcription.
3. Auto-ingest the transcript into the memory graph.
4. Ask chat a question.
5. Stream a cited answer.
6. Demonstrate airplane-mode functionality.
7. Show desktop sync.

Rationale:

- Wonderous-style showcase apps succeed by presenting a coherent experience rather than isolated samples.
- Linearlite demonstrates one workflow scaled well.
- Jan and LM Studio prove a minimal model/chat loop is more credible than broad but shallow feature chrome.

## MoSCoW feature selection

### Must

- **Chat:** streaming `ContentBlock` spine.
- **Memory:** SurrealDB graph-RAG with cited answers and seed corpus.
- **Sync:** local-first sync for one entity type.
- **Models:** minimal model management:
  - Download GGUF.
  - Switch cloud ↔ local.
  - Use Metal on macOS.

### Should

- **Audio Scribe:** Whisper-based transcription; selected because it is the AI feature that works across all three target surfaces.
- **MCP skill:** one minimal skill integration.
- **Hands agent:** one manually triggered agent.
- **Mobile local model:** tiny CPU model on mobile.

### Won't

- **Vision:** excluded because candle Metal is broken on iOS.
- **Scheduled mobile agents:** excluded because iOS background execution limits would make the demo dishonest.
- **Registry/management UIs:** excluded as UI chrome without sufficient crate coverage.

## Supporting verification goals

The original codegen/CI goals remain in scope, but as evidence produced by the PoC:

- Run the real codegen pipeline on `apps/knowme-poc`:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM package install blocker:
  - Blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Key gaps identified during assessment

1. **Flutter Rust Bridge version mismatch**
   - Codegen tool: `flutter_rust_bridge_codegen` `2.11`.
   - Crate: `2.12`.
   - Must align before running the pipeline.

2. **Codegen pipeline has not run**
   - The real codegen pipeline is the highest-information next step.
   - It must run against the PoC rather than remaining theoretical.

3. **PEM install blocker requires a plan-time decision**
   - `@prometheus-ags/entity-graph-core@workspace:*` cannot resolve outside the PEM monorepo.
   - Assessment notes that three resolution options were laid out in the full report.

4. **Rust intent stubs need real wiring**
   - Required concrete integrations:
     - Chat SSE / streaming
     - Graph-RAG
     - GGUF model handling
     - `whisper-rs` as a new dependency

5. **No CI is wired yet**
   - CI must run clippy, audit, and boundary suites against the PoC on every push.

## Recommended implementation sequence

Use `/kbd-plan phase-codegen-and-ci-verification` to convert the assessment into an ordered change list. Suggested sequence:

1. Fix toolchain/version alignment.
2. Scaffold `apps/knowme-poc`.
3. Run first real codegen.
4. Implement Must features in order:
   - M1
   - M2
   - M4
   - M3
5. Add Should features.
6. Wire CI.

Plan-time decisions required:

- PEM dependency unblock path.
- Sync infrastructure approach.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
