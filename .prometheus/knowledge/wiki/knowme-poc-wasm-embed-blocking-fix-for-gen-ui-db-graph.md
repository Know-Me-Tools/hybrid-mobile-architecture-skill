---
type: Reference
id: knowme-poc-wasm-embed-blocking-fix-for-gen-ui-db-graph
title: KnowMe PoC wasm embed_blocking fix for gen_ui_db_graph
tags:
- hybrid-mobile-architecture
- knowme-poc
- wasm
- rust
- graph-rag
- tauri
- ci-verification
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- knowme-poc-c-102-desktop-web-branding-milestone
- hybrid-codegen-and-ci-verification-assessment-readiness
sources:
- stdin
timestamp: 2026-07-16T10:45:14.263029+00:00
created_at: 2026-07-16T10:45:14.263029+00:00
updated_at: 2026-07-16T10:45:14.263029+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src/.claude/worktrees/pensive-greider-2e206c`
- **Captured:** `2026-07-16T10:43:37Z`
- **Source:** `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`
- **App:** `apps/knowme-poc`
- **Crate:** `apps/knowme-poc/rust/crates/gen_ui_db_graph`

The phase remains PoC-driven: build a working KnowMe proof-of-concept app under `apps/<name>/`, using the repository scaffolds and KnowMe reference docs in `docs/reference-app/`. This follows the revised scope in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md) and the assessed KnowMe PoC direction in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md).

## Fix summary

`cargo check -p gen_ui_db_graph --target wasm32-unknown-unknown` now passes, while native `cargo clippy -D warnings` remains clean.

The fix is confined to:

- `apps/knowme-poc/rust/crates/gen_ui_db_graph/src/store.rs:110`

`embed_blocking` is now split by target with `cfg`:

- **Native:** unchanged behavior. Embedding work is sent to `gen_ui_runtime::spawn_blocking`, keeping CPU-bound ONNX inference off the async runtime.
- **Wasm:** calls `self.embedder.embed(&texts)` inline because the browser target has no blocking thread pool. Per the crate design in `embed.rs`, the wasm embedder is a host-injected JavaScript shim using `transformers.js`, not CPU-bound Rust inference.

All embedding call sites, including `memory_ingest` and `memory_search`, already route through `embed_blocking`; therefore no other call-site changes were required.

## Rationale

The prior implementation attempted to use blocking-pool behavior in a wasm target. That is inappropriate for browser wasm because:

- there is no native blocking pool equivalent available to the crate;
- the wasm embedder delegates to host JavaScript rather than running ONNX inference in Rust;
- the native code path still needs blocking isolation to avoid starving async tasks during CPU-bound inference.

The target-specific implementation preserves native runtime safety while making the wasm build compatible with the intended browser embedding design.

## Verification

Executed successfully:

```bash
cargo check -p gen_ui_db_graph --target wasm32-unknown-unknown
```

Native lint status remained clean:

```bash
cargo clippy -D warnings
```

## Phase implications

This was a standalone, pre-existing wasm compatibility fix supporting the broader KnowMe PoC work tracked in [KnowMe PoC C-102 desktop/web branding milestone](/knowme-poc-c-102-desktop-web-branding-milestone.md). It does not complete the next phase task.

Remaining work noted for the phase:

- Continue step 3: `/kbd-apply 2026-07-15-c103-chat-live-e2e`.
- Fold the uncommitted fix from the main repository checkout into the next commit.
- Continue proving the PoC end-to-end alongside supporting codegen/CI goals from [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md):
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
  - PEM dependency install workaround/resolution
  - real target execution for Tauri desktop and Flutter mobile
  - CI coverage for `cargo clippy --workspace`, `audit.sh all`, and boundary test suites

# Citations

1. stdin