---
type: Reference
id: knowme-poc-phase-goals-and-c-105-research-wait-state
title: KnowMe PoC phase goals and C-105 research wait state
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
timestamp: 2026-07-16T16:54:00.786392+00:00
created_at: 2026-07-16T16:54:00.786392+00:00
updated_at: 2026-07-16T16:54:00.786392+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T16:52:03Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This session continues the PoC-first direction captured in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md). The phase remains execution-oriented: deliver a working proof-of-concept application, with code generation and CI checks serving as proof points rather than the sole outcome.

## Revised phase objective

The phase end result is a **working proof-of-concept app**, not just pipeline verification.

### Primary goal

Build a proof-of-concept app in `apps/<name>/` using the repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package works end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Feature subset selection is informed by web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting objectives

The original codegen and CI verification scope remains in force as supporting evidence for the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - full `pnpm install`
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

## Current execution state

- Phase status: `executing`.
- Two background research agents are running:
  1. Verify the real API of the `mistral.rs` fork, including crate structure, GGUF loading, and streaming behavior.
  2. Confirm the current WebLLM npm package and browser API.
- C-105 implementation is pending the research results.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification

## Consolidated source variants

### Variant from `compassionate-babbage-7cd4bc`

Original path: `.prometheus/knowledge/wiki/knowme-poc-phase-goals-and-c-105-research-wait-state.md`  
Original SHA-256: `9a5b6ded2fdc32e3af8d4371a29711310e5b213ed77e882640be1b436a03bee7`

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-16T16:52:03Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This session continues the PoC-first direction captured in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md). The phase remains execution-oriented: deliver a working proof-of-concept application, with code generation and CI checks serving as proof points rather than the sole outcome.

## Revised phase objective

The phase end result is a **working proof-of-concept app**, not just pipeline verification.

### Primary goal

Build a proof-of-concept app in `apps/<name>/` using the repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package works end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Feature subset selection is informed by web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting objectives

The original codegen and CI verification scope remains in force as supporting evidence for the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - full `pnpm install`
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

## Current execution state

- Phase status: `executing`.
- Two background research agents are running:
  1. Verify the real API of the `mistral.rs` fork, including crate structure, GGUF loading, and streaming behavior.
  2. Confirm the current WebLLM npm package and browser API.
- C-105 implementation is pending the research results.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
