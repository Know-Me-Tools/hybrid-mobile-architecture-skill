---
type: Reference
id: analyze-completion-for-knowme-poc-codegen-and-ci-phase
title: Analyze completion for KnowMe PoC codegen and CI phase
tags:
- hybrid-mobile-architecture
- knowme-poc
- bootstrap
- codegen
- ci-verification
- typescript-7
- environment-checks
- base-rules
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- bootstrap-prerequisite-analysis-for-knowme-poc-phase
sources:
- stdin
timestamp: 2026-07-15T22:53:22.267276+00:00
created_at: 2026-07-15T22:53:22.267276+00:00
updated_at: 2026-07-15T22:53:22.267276+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T22:49:36Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `analysis_complete`
- **Commit:** `a705685`

This record captures completion of `kbd-analyze` for the revised phase. It continues the PoC-first direction established in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), assessed in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md), and expanded by [Bootstrap prerequisite analysis for KnowMe PoC phase](/bootstrap-prerequisite-analysis-for-knowme-poc-phase.md).

## Revised phase objective

The phase deliverable is now a working proof-of-concept application, not only codegen and pipeline verification.

### Primary goal

Build a PoC app under `apps/<name>/` using repository scaffolds and skills, based on the KnowMe reference documentation in `docs/reference-app/`:

- Functional spec
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and demonstrate the broadest practical set of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Feature selection should be informed by web research into showcase-app best practices and 2026 on-device AI feasibility.

### Supporting proof points

The original codegen and CI goals remain required, but as supporting proof points for the PoC:

- Run the real codegen pipeline:
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

## Base rules integration

The full 40-rule set is now canonical at `AGENT_BASE_RULES.md` and is wired into all generation paths:

- **Human/agent work:** `CLAUDE.md` and `AGENTS.md` reference `AGENT_BASE_RULES.md` as binding authority.
- **Dispatched agents:** dispatch preamble lists `AGENT_BASE_RULES.md` as authority #0.
- **Generated projects:** `scaffold-hybrid.sh` copies `AGENT_BASE_RULES.md` into each scaffolded project and emits `CLAUDE.md`/`AGENTS.md` declaring it binding.
- **Skills:** all 5 project-skill templates include a binding-rules preamble.

Applying the rules immediately exposed a generator violation: scaffolds pinned TypeScript `^5.6`/`^5.9`, which violates Rule 22 against training-data-era versions. All 4 sites were updated to TypeScript `^7.0.0` per directive to move toward latest `7.0.2`; bootstrap is simplified to `typescript@latest` instead of a fixed pin.

**PoC-time caveat:** verify the Go-native TypeScript 7 compiler against Vite/Vitest tooling.

## Bootstrap findings

Live-source verification produced four bootstrap pillars and associated gotchas:

1. **Prometheus skill system**
   - `prometheus-skill-system` is public.
   - Install flow is documented.
   - Gotcha: docs say `skill-pack`, but the actual slug is `skill-system`.

2. **OpenSpec**
   - Latest verified package is `@fission-ai/openspec` `1.6.0`.
   - The bare `openspec` npm package name is squatted garbage and must not be used.

3. **Flutter beta**
   - Latest verified Flutter beta is `3.47.0`.
   - Existing `install-flutter.sh` is broken for this requirement because its shallow stable clone cannot switch channels.

4. **Node**
   - Node 24 is Active LTS.
   - Bootstrap should pin `fnm install 24`.
   - Do not use `--lts`, because it will resolve to Node 26 in October.

The current machine is the first bootstrap test case and is stale on:

- Flutter: `3.45` → `3.47`
- OpenSpec: `1.4.1` → `1.6.0`

## Decision

Extend `check-env.sh` into a 4-pillar bootstrap with operational gates. This adds change **C-B01** ahead of PoC implementation work.

Planned order:

1. **C-B01:** bootstrap remediation and environment gates
2. PoC scaffold and codegen
3. MoSCoW feature implementation
4. CI wiring and verification

Plan-time decisions still required:

- PEM integration option
- Sync infrastructure choice
- Default flags for remediation behavior

# Citations

1. stdin