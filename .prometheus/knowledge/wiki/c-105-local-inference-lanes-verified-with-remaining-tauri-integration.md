---
type: Reference
id: c-105-local-inference-lanes-verified-with-remaining-tauri-integration
title: C-105 local inference lanes verified with remaining Tauri integration
tags:
- hybrid-mobile-architecture
- knowme-poc
- local-inference
- mistral-rs
- tauri
- cargo-lock
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-phase-goals-and-c-105-research-wait-state
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T17:24:34.107663+00:00
created_at: 2026-07-16T17:24:34.107663+00:00
updated_at: 2026-07-16T17:24:34.107663+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T17:17:57Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This session continues the PoC-first scope captured in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the C-105 research wait state in [KnowMe PoC phase goals and C-105 research wait state](/knowme-poc-phase-goals-and-c-105-research-wait-state.md).

## Phase objective

The phase end result is a **working proof-of-concept application**, not only pipeline verification. Codegen and CI checks are supporting proof points.

### Primary PoC goal

Build a proof-of-concept app in `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical supported capability set:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core
- Feature subset selected using web research on showcase-app best practices and 2026 on-device AI feasibility

### Supporting verification goals

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

## Completed this session

- **C-104 backend memory/graph-RAG**
  - Verified.
  - A concurrent session archived C-104 and carried deferred Memory UI work forward as C-111.
- **C-107 Scribe/whisper** and **C-110 CI**
  - Found already built by concurrent sessions.
  - Re-verified with clippy, audit, and CI YAML checks.
  - Marked merged.
- **C-105 T1-T8**
  - Both local-inference lanes are working behind the frozen `InferenceProvider` seam.
  - Both lanes are built, verified, committed, and pushed.

## Fixed integration traps

### `mistral.rs` fork dependency mismatch

The pinned `mistral.rs` fork did not compile as pinned:

- Its Candle fork moved to `safetensors` `0.8`.
- `mistral.rs` still expected `safetensors` `0.7`.
- Result: `candle-core::Dtype` no longer unified with `mistralrs-quant`'s type expectations.

Fix applied:

- Used the fallback documented in the fork's own `Cargo.toml`.
- Patched Candle to upstream commit `5404348`.
- This also removed a floating branch reference from the dependency graph.

### `Cargo.lock` was incorrectly ignored

A blanket `*.lock` `.gitignore` rule ignored `Cargo.lock`, even though it was required to pin critical dependency resolutions:

- `mistral.rs` floating `turboquant-rs#main` branch
- `regex` `1.12.4`, which allows the `mistral.rs` and `liter-llm` lanes to coexist

Risk:

- CI would silently re-resolve dependencies and potentially break without a committed lockfile.

Fix applied:

- Narrowed the ignore rule.
- Lockfiles are now committed.

## Research corrections caught by compilation

Initial API research was incorrect in three areas:

- Error types
- `with_max_seq_len`
- Error variant shapes

The compiler caught the mismatches before more code was written against incorrect assumptions. This reinforces the project practice that the compiler is the harness for validating API assumptions during implementation.

## Remaining C-105 work

- **T9:** Wire `gen_ui_inference` into `tauri-plugin-gen-ui` with local-inference Tauri commands and permissions.
- **T10:** Add `gen_ui_agent` lane selection.
- **T11:** Add store toggle and tokens-per-second display.
- **T12:** Run an end-to-end smoke test with a real model download.
  - This should also answer whether `mistral.rs` performs its own `spawn_blocking` internally.

## Next action

Proceed with **C-105 T9**: integrate `gen_ui_inference` into `tauri-plugin-gen-ui` by adding local-inference commands and required permissions, then continue through lane selection, UI store toggle/tok-s display, and real-model smoke verification.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification