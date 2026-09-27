# Conversion and suitability assessment

The conversion, migration engine, and runnable baseline implementation are
complete in the candidate worktree. Local macOS ARM64 evidence covers the web,
Tauri, Flutter bridge/codegen, Android package, and iOS simulator build paths.
Release certification remains open until the committed candidate passes the
native CI matrix, including Windows x64 and Windows ARM64 execution and the
pinned Flutter two-launch persistence checks.

## Delivered

- Replaced all 79 inventoried first-party shell/Python executables, including
  hooks, emitted helpers, maintenance commands and extensionless test fixtures.
  TypeScript 7.0.2 emits Node `.mjs`; native APK/ELF work uses Rust.
- Added both Windows MSVC targets to pinned Rust 1.97.1 and compiled both native
  crates for x64 and ARM64. Native Windows execution is a separate pending gate.
- Added ownership-safe installer behavior, explicit argument handling, brownfield
  manifest inventory and stable rendering identity for moved projects.
- Added managed-file upgrade journals, conflict preflight, guarded rollback,
  native process locks, interrupted-state recovery, and an explicit
  `2.0.0-alpha.3` to `2.0.0-alpha.4` semantic migration with add, remove,
  rename, dependency, and codegen operation metadata.
- Replaced manifest-only runnable claims with complete clean-architecture
  React/Axum, React/Tauri, and Flutter/Rust FFI baselines. Each baseline uses
  the shared Rust domain/repository boundary and a persisted notes vertical
  slice.
- Integrated supported capability additions through application-owned registry
  seams. Unsupported auth, module, and legacy-embed mutations fail before any
  destination write until certified adapters exist.
- Initialized OpenSpec for all supported tools, configured and exercised Compass
  MCP, and exported a four-role maintenance team for four native harnesses.
- Staged identical full/mini payloads and exercised isolated install/uninstall.
  A clean clone of the committed candidate also passes consumer installation.
  Source-pack publication has not been performed.

## Verification

- Node: 25 behavioral tests pass, including staged package consumers and the
  Kimi Code, MiniMax Code, and Zed discovery roots.
- Rust 1.97.1: Builder clippy and 43 tests pass; native platform helper clippy
  and four real ELF tests pass. Both crates pass checks for both Windows targets.
- A real Chromium flow invokes Axum, writes SQLite, restarts the server, and
  reads the persisted note. Tauri builds and launches on macOS ARM64 and creates
  its SQLite state. Flutter Rust Bridge and Riverpod generation, Flutter
  analysis, Rust tests/clippy, an Android ARM64 APK, and an iOS simulator build
  pass locally.
- Package authority, 36 skill contracts/108 activation cases, security boundary,
  resource/mirror integrity, scaffold structure and OpenSpec validation pass.
  Activation cases are metadata checks, not application runtime tests.
- Independent adversarial reviews found concrete defects in migration
  enumeration, UI architecture, relocatable locks, generated-source markers,
  and native runtime proof. The source defects are fixed; the final review stays
  open until the committed native matrix supplies its required evidence.
  Initial and intermediate findings remain alongside the final receipt.

## Suitability findings and release boundary

The original baseline demonstrates 4 of 21 readiness criteria (19.05%); this is
an evidence checklist, **not a test pass rate**. Its untouched baseline is in
`assessment.json`. The implementation receipt records later improvements.

The package now has real persisted clean-architecture baselines, a historical
alpha.3 fixture, semantic migration planning, conflict proposals, rollback,
and one certified brownfield capability integration seam. This proves the
supported baseline and feature-addition paths; it does not certify arbitrary
legacy layouts or optional auth, inference, UAR, module, and legacy-embed
integrations. Those combinations remain explicit pre-write rejections until
they have adapters and runtime evidence. Destructive application-data
migrations remain outside this release.

Research exported 30 sources and 65 claims with confidence 0.66 and partial
verification. One contradiction remains unresolved; review-model independence
was not verified. Compass's refreshed graph is partial (276 omitted edges).
Read these limitations with the [research receipt](../research/portable-tooling-20260926/receipt.json)
and [tool setup record](../portability/project-tools.md).

The release-blocking evidence is the committed GitHub Actions matrix: native
Windows x64 and ARM64 packaged-UI create/relaunch/read proof, the pinned Flutter
3.47.5 Android ARM64 and iOS
simulator two-launch persistence checks, and rebuild/run of the historical and
brownfield fixtures. Physical-device-only inference and live PostgreSQL remain
separate capability claims and are not implied by baseline certification.
