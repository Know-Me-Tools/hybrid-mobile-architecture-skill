---
type: Reference
id: hybrid-mobile-phase-codegen-and-ci-verification-readiness
title: Hybrid Mobile phase codegen and CI verification readiness
tags:
- hybrid-mobile-architecture
- codegen
- ci-verification
- flutter-rust-bridge
- pem-install
- boundary-tests
- kbd-orchestrator
links:
- hybrid-codegen-and-ci-verification-phase-opened
- hybrid-mobile-scaffold-phase-completes-12-of-12-changes
- c-012-completes-hybrid-scaffold-vertical-slice-seams
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-15T22:14:23.303111+00:00
created_at: 2026-07-15T22:14:23.303111+00:00
updated_at: 2026-07-15T22:14:23.303111+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T22:11:47Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `assessment_ready`
- **Repository:** `github.com/Know-Me-Tools/hybrid-mobile-architecture-skill`
- **Default branch:** `main`

This records the handoff into [Hybrid codegen and CI verification phase opened](/hybrid-codegen-and-ci-verification-phase-opened.md) after the full scaffold work from [Hybrid Mobile scaffold phase completes 12 of 12 changes](/hybrid-mobile-scaffold-phase-completes-12-of-12-changes.md) and the final vertical slice seams in [C-012 completes hybrid scaffold vertical slice seams](/c-012-completes-hybrid-scaffold-vertical-slice-seams.md).

## Phase goals

1. **CI automation on every push**
   - Run `cargo clippy --workspace`.
   - Run `audit.sh all`.
   - Run boundary test suites:
     - Rust
     - Dart
     - Vitest

2. **PEM end-to-end install unblock**
   - Target package: `@prometheus-ags/prometheus-entity-management`.
   - Current blocker: `@prometheus-ags/entity-graph-core@workspace:*` fails to resolve outside the PEM monorepo.
   - Accepted resolution paths:
     - Publish the upstream `@prometheus-ags/entity-graph-core` dependency.
     - Add a pre-resolution step in `scaffold-packages.sh`.

3. **Real codegen pass on a fully scaffolded project**
   - Run `flutter_rust_bridge_codegen generate`.
   - Run `dart run build_runner build`.
   - Run full `flutter pub get`.
   - Run full `pnpm install`.
   - Confirm expected pre-codegen warnings clear once generated code and sibling packages exist:
     - `379` Dart analyze issues
     - `override_on_non_overriding_member`
     - `path_does_not_exist`

4. **End-to-end target verification**
   - Build and run the full stack on at least one real target rather than scaffold-only checks.
   - Candidate targets:
     - macOS Tauri desktop
     - iOS simulator
     - Android simulator

## Repository state

- `main` is confirmed as the default branch.
- No open PRs exist; this is expected because the work was pushed directly to `main`.
- All 17 commits are live on the remote repository.
- Push range: `cd54877..0cfb101` to `origin/main`.
- The pushed history includes:
  - Full `scaffold-full-hybrid-project` phase completion: **12/12 changes**.
  - Opening of the new `phase-codegen-and-ci-verification` phase.

## Cleanup performed before push

A repository hygiene issue was found and fixed before pushing:

- The OpenSpec archive move from `/kbd-reflect` left 17 old-path files still tracked in `HEAD` alongside their new archived copies.
- The deletion of the old-path files had not been staged.
- A final cleanup commit removed the stale tracked files before the push.

## Workflow decision

- No PR was created.
- The chosen workflow was direct push to `main`.
- The result is a single linear, fast-forward history with commits verified as they were built.

## Next action

Run the assessment command for the new phase:

```bash
/kbd-assess phase-codegen-and-ci-verification
```

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification