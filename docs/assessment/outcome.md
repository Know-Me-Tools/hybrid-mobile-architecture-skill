# Conversion and suitability assessment

The conversion/tooling pass is implemented. The package is **not yet certified
to generate complete runnable applications on every declared surface**. That
requires the baseline repair and native execution work in the
[reviewed plan](portable-tooling-plan.md).

## Delivered

- Replaced all 79 inventoried first-party shell/Python executables, including
  hooks, emitted helpers, maintenance commands and extensionless test fixtures.
  TypeScript 7.0.2 emits Node `.mjs`; native APK/ELF work uses Rust.
- Added both Windows MSVC targets to pinned Rust 1.97.1 and compiled both native
  crates for x64 and ARM64. Native Windows execution is a separate pending gate.
- Added ownership-safe installer behavior, explicit argument handling, brownfield
  manifest inventory and stable rendering identity for moved projects.
- Added managed-file upgrade journals, conflict preflight, guarded rollback,
  native process locks and interrupted-state recovery.
- Initialized OpenSpec for all supported tools, configured and exercised Compass
  MCP, and exported a four-role maintenance team for four native harnesses.
- Staged identical full/mini payloads and exercised isolated install/uninstall.
  Source-pack publication has not been performed.

## Verification

- Node 22.23.3: 22 behavioral tests pass, including staged package consumers.
- Rust 1.97.1: Builder clippy and 24 tests pass; native platform helper clippy
  and four real ELF tests pass. Both crates pass checks for both Windows targets.
- Real Docusaurus scaffold/production build and full tray/Tauri template gate
  pass. Catalog/GitOps checks pass; no deployment was performed.
- Package authority, 36 skill contracts/108 activation cases, security boundary,
  resource/mirror integrity, scaffold structure and OpenSpec validation pass.
  Activation cases are metadata checks, not application runtime tests.
- Independent adversarial reviews found concrete defects; fixes were re-reviewed
  with no remaining findings in the bounded conversion/recovery scope. Initial
  findings remain alongside re-review receipts.

## Suitability findings and next work

The original baseline demonstrates 4 of 21 readiness criteria (19.05%); this is
an evidence checklist, **not a test pass rate**. Its untouched baseline is in
`assessment.json`. The implementation receipt records later improvements.

The next substantive work is a real persisted clean-architecture feature in
each web, Tauri and Flutter/FFI baseline. Complete entrypoints, dependency locks,
bridge/codegen and composition roots, then build and run each supported target.
Reject unsupported combinations before writing. Optional auth, inference and
UAR integrations need their own prerequisites and runtime evidence.

Brownfield adoption must expand from canonical manifest inventory to explicit
layout mappings and integrated capability changes. Continuous evolution needs
versioned add/remove/rename, dependency, codegen and schema migrations tested
against historical outputs and user-edited applications. The current journal
restores managed files; it does not implement those semantic migrations or
application-data backup. A successful no-op is not proof of a migrated app.

Research exported 30 sources and 65 claims with confidence 0.66 and partial
verification. One contradiction remains unresolved; review-model independence
was not verified. Compass's refreshed graph is partial (276 omitted edges).
Read these limitations with the [research receipt](../research/portable-tooling-20260926/receipt.json)
and [tool setup record](../portability/project-tools.md).

Remaining execution evidence includes native Windows, Android/iOS device or
simulator runs, Flutter installation and live PostgreSQL checks. The Docusaurus
build reported 20 moderate transitive dependency advisories; assess those before
publishing a generated production site. None of these gaps is marked passed.
