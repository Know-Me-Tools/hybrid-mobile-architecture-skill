<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=f7320f67530fc4b2fce18bfd4be078c2482f4bf014ebb0f65d6911506d53e440 -->
---
type: Reference
id: hybrid-codegen-and-ci-verification-assessment-readiness
title: Hybrid codegen and CI verification assessment readiness
tags:
- hybrid-mobile-architecture
- codegen
- ci-verification
- flutter-rust-bridge
- pem-install
- boundary-tests
links:
- hybrid-mobile-scaffold-phase-completes-12-of-12-changes
- hybrid-codegen-and-ci-verification-phase-opened
- kbd-status-before-codegen-and-ci-verification-assessment
- hybrid-mobile-phase-codegen-and-ci-verification-readiness
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-15T22:25:52.101603+00:00
created_at: 2026-07-15T22:25:52.101603+00:00
updated_at: 2026-07-15T22:25:52.101603+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-15T22:14:32Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `assessment_ready`

This record captures the phase state immediately before assessment. It follows the completed scaffold phase in [Hybrid Mobile scaffold phase completes 12 of 12 changes](/hybrid-mobile-scaffold-phase-completes-12-of-12-changes.md) and continues the phase opened in [Hybrid codegen and CI verification phase opened](/hybrid-codegen-and-ci-verification-phase-opened.md). It is also consistent with [KBD status before codegen and CI verification assessment](/kbd-status-before-codegen-and-ci-verification-assessment.md) and [Hybrid Mobile phase codegen and CI verification readiness](/hybrid-mobile-phase-codegen-and-ci-verification-readiness.md).

## Phase goals

### CI automation

Wire a CI pipeline that runs automatically on every push:

- `cargo clippy --workspace`
- `audit.sh all`
- Boundary test suites:
  - Rust
  - Dart
  - Vitest

### PEM end-to-end install unblock

Unblock installation of `@prometheus-ags/prometheus-entity-management` outside the PEM monorepo.

Current blocker:

- `@prometheus-ags/entity-graph-core@workspace:*` dependency cannot resolve outside the PEM monorepo.

Accepted resolution paths:

- Publish the upstream `@prometheus-ags/entity-graph-core` dependency.
- Add a pre-resolve step in `scaffold-packages.sh` so scaffolded projects can install successfully without being inside the PEM monorepo.

### Real codegen pass on a fully scaffolded project

Run the full codegen/install sequence against a fully scaffolded project:

```sh
flutter_rust_bridge_codegen generate
dart run build_runner build
flutter pub get
pnpm install
```

Expected verification outcome:

- Pre-codegen warnings clear after generated code and sibling packages exist.
- Known pre-codegen issues to verify as resolved:
  - `379` `dart analyze` issues
  - `override_on_non_overriding_member`
  - `path_does_not_exist`

### End-to-end target verification

Verify the full stack builds and runs on at least one real target, rather than relying only on scaffold-level checks.

Acceptable target examples:

- macOS Tauri desktop
- iOS simulator
- Android simulator

## Current assessment state

- The phase is positioned at `phase-codegen-and-ci-verification`.
- The status is `assessment_ready`.
- No implementation result is recorded in this source; it defines the pending assessment goals and acceptance checks.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification