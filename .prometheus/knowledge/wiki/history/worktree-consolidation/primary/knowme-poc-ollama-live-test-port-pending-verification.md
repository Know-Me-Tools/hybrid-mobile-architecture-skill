<!-- source=primary; branch=main-pre-consolidation; original_sha256=3f5ad7d99ee501a21b181f1216dc4ee029b7d712e515961d293006a56115385c -->
---
type: Reference
id: knowme-poc-ollama-live-test-port-pending-verification
title: KnowMe PoC Ollama live-test port pending verification
tags:
- hybrid-mobile-architecture
- knowme-poc
- ollama
- live-test
- codegen
- ci-verification
- tauri
- graphstore
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
timestamp: 2026-07-16T12:20:16.357382+00:00
created_at: 2026-07-16T12:20:16.357382+00:00
updated_at: 2026-07-16T12:20:16.357382+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T12:07:15Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md). The phase deliverable remains a working proof-of-concept application in `apps/<name>/`; codegen and CI verification are supporting proof points.

## Phase goals

### Primary goal

Build a proof-of-concept app in `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional spec
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web from one Rust core

Feature subset selection is informed by web research on showcase-app best practices and 2026 on-device AI feasibility.

### Supporting goals

The original codegen/CI phase objectives are retained as supporting objectives proven through the PoC:

- Run the real codegen pipeline on the PoC:
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

## Current execution state

- Background task output was still buffering; no manual polling should continue until the background task notification arrives.
- Commits were pushed for:
  - `C-103`
  - `C-107`
  - `C-110`
  - `versions.toml` / `audit-gate`
- An in-flight git merge conflict occurred with another session's parallel `C-103` implementation.
  - The merge was aborted.
  - Verified work on `main` was kept.
- Valuable work from the other branch was ported onto the current architecture:
  - `ollama_live.rs`
  - `dev_ollama.rs`
- The ported Ollama live-test code compiles cleanly.
- Workspace clippy remains clean.
- A real live test is currently running against a local Ollama instance to verify behavior before committing the port.

## Next actions

1. Await the running live-test result from the background task.
2. If the live test passes, commit:
   - ported `ollama_live.rs`
   - `dev_ollama.rs` wiring
3. Proceed to `C-104` backend wiring under the approved backend-only scope:
   - `memory_search`
   - `memory_ingest`
   - `graph_expand`
   - route through `gen_ui_ffi` and `tauri-plugin-gen-ui`
   - connect to the real `GraphStore`
   - add desktop `GraphStore` initialization

# Citations

1. stdin