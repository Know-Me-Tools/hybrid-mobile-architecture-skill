<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=001c0aec8ffdbce73589f2cad50beee5b8ca1b4fe7a8385886ebf7b568b77cf7 -->
---
type: Reference
id: hybrid-codegen-and-ci-verification-phase-opened
title: Hybrid codegen and CI verification phase opened
tags:
- hybrid-mobile-architecture
- codegen
- ci-verification
- flutter-rust-bridge
- pem-install
- boundary-tests
- kbd-orchestrator
links:
- hybrid-mobile-scaffold-phase-completes-12-of-12-changes
- c-012-completes-hybrid-scaffold-vertical-slice-seams
sources:
- stdin
timestamp: 2026-07-15T22:12:02.189310+00:00
created_at: 2026-07-15T22:12:02.189310+00:00
updated_at: 2026-07-15T22:12:02.189310+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-15T22:05:07Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `assessment_ready`
- **Opening commit:** `90efb28`

This phase follows completion of the full scaffold phase recorded in [Hybrid Mobile scaffold phase completes 12 of 12 changes](/hybrid-mobile-scaffold-phase-completes-12-of-12-changes.md) and the final vertical-slice seams from [C-012 completes hybrid scaffold vertical slice seams](/c-012-completes-hybrid-scaffold-vertical-slice-seams.md).

## Phase goals

1. **CI automation**
   - Wire CI to run on every push:
     - `cargo clippy --workspace`
     - `audit.sh all`
     - Boundary test suites:
       - Rust
       - Dart
       - Vitest

2. **PEM end-to-end install unblock**
   - Resolve the PEM package install failure for `@prometheus-ags/prometheus-entity-management`.
   - Current blocker: `@prometheus-ags/entity-graph-core@workspace:*` dependency fails outside the PEM monorepo.
   - Acceptable resolution paths:
     - Publish the upstream dependency.
     - Add a pre-resolve step in `scaffold-packages.sh`.

3. **Real generated-project codegen pass**
   - Run codegen against a fully scaffolded project:
     - `flutter_rust_bridge_codegen generate`
     - `dart run build_runner build`
     - Full `flutter pub get`
     - Full `pnpm install`
   - Confirm pre-codegen warnings clear once generated code and sibling packages exist:
     - 379 `dart analyze` issues
     - `override_on_non_overriding_member`
     - `path_does_not_exist`

4. **End-to-end runtime verification**
   - Build and run the full stack on at least one real target instead of relying only on scaffold checks.
   - Candidate targets:
     - macOS Tauri desktop
     - iOS simulator
     - Android simulator

## Current state

- `kbd-new-phase` completed successfully.
- New phase `phase-codegen-and-ci-verification` was opened and committed at `90efb28`.
- Phase was seeded from the prior phase reflection.
- KBD position marker indicates the phase is ready for assessment:

```text
Position: phase-codegen-and-ci-verification | status: assessment_ready
```

## Next action

Run:

```sh
/kbd-assess phase-codegen-and-ci-verification
```

Purpose: evaluate current implementation state and identify gaps before planning CI, PEM install resolution, codegen verification, and real-target runtime validation.

# Citations

1. stdin