<!-- source=primary; branch=main-pre-consolidation; original_sha256=6ea9d5d1db17d233f5e6b963588233d738c71a6d9e6a07dd1918683620b96bb6 -->
---
type: Reference
id: hybrid-inference-architecture-revision-for-knowme-poc
title: Hybrid inference architecture revision for KnowMe PoC
tags:
- hybrid-mobile-architecture
- knowme-poc
- inference-architecture
- liter-llm
- mistral-rs
- webllm
- codegen
- ci-verification
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- knowme-poc-c-102-desktop-web-branding-milestone
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T02:59:53.555121+00:00
created_at: 2026-07-16T02:59:53.555121+00:00
updated_at: 2026-07-16T02:59:53.555121+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T02:01:58Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `execute_ready`
- **Commit:** [`4ed2d08`](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/commit/4ed2d08)

The phase remains scoped around delivering a working KnowMe proof-of-concept application, as revised in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md) and assessed in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md). Codegen, dependency installation, target builds, and CI are supporting proof points rather than the primary deliverable.

## Phase goal

Build a proof-of-concept app under `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical supported capability set:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web from one Rust core

Feature selection is guided by showcase-app best practices and 2026 on-device AI feasibility research.

## Supporting verification goals

The original codegen/CI phase objectives remain required as proof points:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI on every push for:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites

## Committed inference architecture revision

Four inference-related changes were researched, documented, and pushed in commit `4ed2d08`.

### C-103: `liter-llm` gateway and configuration database

`liter-llm` was selected as the cross-target provider gateway:

- `liter-llm` core crate supports desktop/mobile through the `native-http` feature.
- `liter-llm-wasm` provides fetch-based support for web.
- `liter-llm-ffi` is available for FFI integration.
- One Rust dependency covers all three targets while exposing the 142+ provider catalog.

The previous Anthropic SSE-specific path is replaced by the `liter-llm` gateway.

The configuration database follows the existing `prometheus-db` pattern in the architecture:

- Rust core for Tauri/mobile: `pglite-oxide`
- Web: PGlite
- v1 schema:
  - `providers`
  - `model_prefs`
  - `app_settings`
- API keys use keychain-backed storage.
- Settings includes an admin UI for provider and model preference management.

This work folds into:

- **C-103:** gateway + configuration schema
- **C-109:** admin UI

### C-104: memory unchanged

Memory work was intentionally left untouched. The SurrealDB graph-RAG memory direction remains part of the PoC capability target.

### C-105: `mistral.rs` local native engine

The `mistral.rs` fork replaces direct Candle wiring for native local inference:

- Uses the `mistralrs` high-level crate.
- Fork includes core, quantization, audio, and vision surfaces.
- Supports Hugging Face Hub download.
- Supports GGUF model loading.
- Supports Metal streaming on desktop.
- Same crate is planned for C-109 mobile CPU “sovereign mode.”

The fork’s audio crate was recorded as a C-107 evaluation option.

### Web local model exception: WebLLM / MLC

Firecrawl-backed research selected **WebLLM (MLC)** as the primary web local model engine:

- Identified as the 2026 consensus in-browser chat engine.
- WebGPU accelerated.
- Provides an OpenAI-compatible streaming API.
- Curated catalog includes `Qwen2.5-1.5B-Instruct-q4f16_1-MLC`.
- Uses the same model family as the native lane, giving a consistent demo story across desktop, mobile, and web.

Rejected or secondary options:

- `wllama`: rejected as primary because WASM/CPU performance is not compelling for demo use.
- `transformers.js`: reserved for web embeddings and Whisper-style tasks.

Because WebLLM is TypeScript, it is documented as an explicit exception to the Rust-core invariant. It remains behind the same `chat_send` intent seam and is feature-gated on WebGPU, with visible degradation to the `liter-llm` cloud lane when WebGPU is unavailable.

## Updated records

The revision updated the following project records:

- Spec of record:
  - §2 MoSCoW, including new M5
  - New §3.5 “Inference architecture”
  - New §3.6 “Configuration database”
  - C-table
  - §6 open items
- KBD `plan.md`:
  - C-103 rewritten with fork URLs and pin-SHA discipline
  - C-105 rewritten with fork URLs and pin-SHA discipline
  - C-109 rewritten with fork URLs and pin-SHA discipline
- `decision-log.md` with provenance and research sources
- Three OpenSpec proposal summaries

This follows the earlier desktop/web branding milestone captured in [KnowMe PoC C-102 desktop/web branding milestone](/knowme-poc-c-102-desktop-web-branding-milestone.md).

## Next execution steps

Execution can resume with the revised **C-103**:

1. Integrate `liter-llm` gateway.
2. Add the configuration database.
3. Run the first iOS-simulator target.

**C-110** CI work is available as a parallel lane.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification