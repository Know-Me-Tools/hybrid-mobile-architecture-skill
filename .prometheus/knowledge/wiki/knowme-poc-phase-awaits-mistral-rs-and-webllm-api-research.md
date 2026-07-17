---
type: Reference
id: knowme-poc-phase-awaits-mistral-rs-and-webllm-api-research
title: KnowMe PoC phase awaits mistral.rs and WebLLM API research
tags:
- hybrid-mobile-architecture
- knowme-poc
- codegen
- ci-verification
- mistral-rs
- webllm
- tauri
- flutter
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T16:52:20.797675+00:00
created_at: 2026-07-16T16:52:20.797675+00:00
updated_at: 2026-07-16T16:52:20.797675+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T16:51:37Z`
- **Phase source:** `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`

## Phase goal

The phase has been revised from pipeline-only verification to delivery of a working proof-of-concept app. This continues the PoC-first scope documented in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md).

## Primary objective

Build a proof-of-concept app under `apps/<name>/` using this repository's scaffolds and skill packages, guided by the KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical set of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform delivery from one Rust core:
  - Flutter mobile
  - Tauri desktop
  - Web

The feature subset should be selected using web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting objectives

The original codegen and CI verification goals remain in scope, but are now validated through the working PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker:
  - `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Current execution state

Two background research agents are running before C-105 implementation resumes:

1. **mistral.rs fork verification**
   - Confirm real API surface.
   - Inspect crate structure.
   - Verify GGUF model loading path.
   - Verify streaming support.
2. **WebLLM verification**
   - Confirm current npm package name and installation details.
   - Confirm browser API shape.

Implementation of `C-105` is pending the research reports.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
