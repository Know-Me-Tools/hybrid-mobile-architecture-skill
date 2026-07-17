<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=dd950280fce699999204779f3795e3cb1d102305cc7a3db474ad175c664c46b1 -->
---
type: Reference
id: knowme-poc-tauri-dock-icon-verification-requires-app-bundle
title: KnowMe PoC Tauri Dock icon verification requires app bundle
tags:
- hybrid-mobile-architecture
- knowme-poc
- tauri
- macos-bundle
- dock-icon
- branding
- ci-verification
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T01:25:54.338767+00:00
created_at: 2026-07-16T01:25:54.338767+00:00
updated_at: 2026-07-16T01:25:54.338767+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-16T01:19:44Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `execute_in_progress`
- **App:** `apps/knowme-poc`

The phase remains focused on the revised PoC goal established in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md) and assessed in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md): build a working KnowMe proof-of-concept app that proves the repository skill package end-to-end. Codegen, dependency installation, target builds, and CI checks are supporting proof points rather than the primary deliverable.

## Phase goals

### Primary goal

Build a proof-of-concept app under `apps/<name>/`, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must demonstrate the broadest practical set of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web surfaces from one Rust core

Feature selection is informed by web research on showcase-app best practices and 2026 on-device AI feasibility.

### Supporting goals

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
  - Boundary test suites

## Tauri Dock icon finding

Two KnowMe PoC desktop processes were running cleanly:

- `tauri dev` binary: PID `42205`
  - Unbundled bare Mach-O executable.
  - Expected to show a generic or incorrect Dock icon because it is not inside an `.app` bundle.
- Built `.app` bundle: PID `40007`
  - Proper macOS bundle.
  - Expected to show the correct icon because `Info.plist` points to `icon.icns`.

The wrong Dock/tray icon observed during development was root-caused to a **`tauri dev` bundling limitation**, not a KnowMe icon asset bug.

### Evidence

- The actual `icon.icns` was verified by converting it back to PNG.
- The converted icon is the expected KnowMe K-monogram:
  - dark rounded square
  - white `K`
  - ember dot
- `cargo run` / `tauri dev` launches a bare Mach-O executable without an `Info.plist`.
- macOS therefore cannot resolve `CFBundleIconFile` and may use a cached or generic icon; in this session it displayed a Firefox icon.
- A real `.app` bundle produced by `tauri build` or `tauri build --debug` contains the bundle metadata required for correct icon resolution:
  - `Info.plist`
  - `CFBundleIconFile: icon.icns`

## Verification artifact

A debug bundle was built and launched for verification:

```text
$REPO_ROOT/apps/knowme-poc/desktop/src-tauri/target/debug/bundle/macos/knowme-poc.app
```

Expected result: the Dock icon for the launched `.app` bundle should display the correct KnowMe K-monogram rather than the Firefox/generic icon seen under `tauri dev`.

## Decision

If the debug `.app` bundle shows the correct Dock icon, no code fix is required. The behavior should be documented as expected Tauri/macOS development behavior:

- Use `tauri dev` for development iteration, but do **not** use it to verify macOS Dock icon branding.
- Use `tauri build` or `tauri build --debug` when verifying:
  - Dock icon
  - app bundle metadata
  - `Info.plist`-driven branding behavior

## Next action

Confirm that the launched debug `.app` bundle displays the correct KnowMe K-monogram Dock icon. If confirmed, proceed to commit the branding, menu, titlebar, and icon work.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification