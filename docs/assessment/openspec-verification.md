# OpenSpec verification: portable tooling and project evolution

## Verification state

- Change: `portable-tooling-and-project-evolution` (archived as `2026-09-27-portable-tooling-and-project-evolution`)
- Candidate commit: `e7ce27b0790bf2f3dc30a460c7474b649e8e1e96`
- OpenSpec status: **28 of 28 tasks complete**
- Overall verdict: **PASS — implementation, native execution, cross-model review, and strict anti-theater evidence pass**
- Pending tasks: **none**

This report maps the change tasks, requirements, and scenarios to current implementation,
tests, and retained evidence. It does not promote source generation, cross-target
installation, compilation, or a locally available simulator to native execution evidence.
Task 24 is closed by the successful corrective exact-head native matrix. Task 28 is
closed by the distinct-model PASS receipt and strict anti-theater score of 0.0.

## Direct verification at the candidate commit

| Check | Result |
|---|---|
| Pre-archive `openspec validate portable-tooling-and-project-evolution --strict --json` | Pass; one change validated with no issues |
| Final `openspec instructions apply --change portable-tooling-and-project-evolution --json` | 28 tasks total; 28 complete; none remaining |
| `npm test` in `runtime/` | Pass; 30 tests, 0 failures |
| `cargo test --locked --manifest-path tools/knowme-builder/Cargo.toml` | Pass; 18 unit tests and 27 CLI tests, 0 failures |

The native workflow's release authority is `.github/workflows/scaffold-ci.yml`.
[Run 36322460747](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/actions/runs/36322460747)
passed every job at the candidate commit; the final cross-model review and anti-theater receipt are retained separately.

## Task evidence map

| Task | Status | Concrete evidence |
|---|---|---|
| 1. Inspect source, consumers, and scaffold/upgrade contracts | Pass | Source and consumer inventory in `docs/assessment/portable-tooling-audit.md:3-33`; scaffold and evolution baseline in `docs/assessment/scaffold-audit.md:3-54`. |
| 2. Initialize OpenSpec for supported tools | Pass | Initialization scope and limitations in `docs/portability/project-tools.md:6-17`; preserved change artifacts under `openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/`. |
| 3. Build Compass graph and Program IR | Pass | Final candidate graph metrics and partial-publication limitation in `docs/portability/project-tools.md:19-32`; configuration in `.compass/config.toml:1-28`. |
| 4. Install maintenance-team definitions with explicit ownership | Pass | Four-role ownership ledger in `.agent-team/state.json:4-101`; installation and scope statement in `docs/portability/project-tools.md:46-57`. |
| 5. Independently review the plan and resolve compiler identity | Pass | Initial warning, registry resolution, and anti-theater result in `docs/assessment/review/plan-findings.json:1-30`; resolution recorded in `docs/assessment/portable-tooling-plan.md:26-28`. |
| 6. Complete research package while preserving limitations | Pass | Partial-verification receipt in `docs/research/portable-tooling-20260926/receipt.json:1-10`; confidence, contradiction, and provenance fields in `docs/research/portable-tooling-20260926/manifest.json:24-38`. |
| 7. Verify Compass MCP discovery and query | Pass | Protocol behavior and bounded query description in `docs/portability/project-tools.md:34-44`; retained responses in `docs/assessment/evidence/compass-mcp-discovery.json:1` and `docs/assessment/evidence/compass-mcp-query.json:1`. |
| 8. Build strict TypeScript 7 sources to shipped modules | Pass | Exact compiler/dependency pins in `runtime/package.json:6-18`; strict NodeNext compilation in `runtime/tsconfig.json:2-7`; dependency lock in `runtime/package-lock.json:1`; current runtime suite passes. |
| 9. Convert hooks, settings, installation, synchronization, and verification | Pass | Protocol, malformed-input, merge, idempotence, and preservation tests in `runtime/tests/portable-consumer.test.mjs:13-47`; install/sync lifecycle in `runtime/tests/harness-installer.test.mjs:10-117`. |
| 10. Convert scaffold wrappers without dropping arguments | Pass | Argument-array process test and explicit invalid-option rejection in `runtime/tests/portable-consumer.test.mjs:50-67`. |
| 11. Add Windows x64/ARM64 diagnostics and prerequisite outcomes | Pass | Requested-capability and host/target distinction in `tools/knowme-builder/src/native.rs:9-85,101-164`; non-Windows refusal test in `tools/knowme-builder/tests/cli.rs:1154-1171`. |
| 12. Complete enumerated first-party shell/Python conversion | Pass | Inventory in `docs/assessment/script-migration-ledger.json:1`; package collector rejects first-party shell/Python while identifying vendor exceptions in `runtime/src/stage-skill-package.mts:31-45`. |
| 13. Prove isolated staged package operation and mirror integrity | Pass | Full/mini isolated installation and byte comparison in `runtime/tests/staged-package.test.mjs:10-30`; owned mirror lifecycle in `runtime/tests/harness-installer.test.mjs:10-117`. |
| 14. Verify committed candidate through clean-clone consumer gate | Pass | Isolated clone, committed verifier, mirror inspection, and copied-project installation in `runtime/src/test-consumer-install.mts:15-43`. |
| 15. Inventory brownfield surfaces without false runnable claims | Pass | Actual detected/missing surface inventory and explicit unverified warning in `tools/knowme-builder/src/engine.rs:822-897`; preview assertions in `tools/knowme-builder/tests/cli.rs:76-143`. |
| 16. Preserve user files, rendering identity, and ownership | Pass | Stable identity and ownership model in `tools/knowme-builder/src/model.rs:37-88`; identity preflight and user-file conflict coverage in `tools/knowme-builder/tests/cli.rs:660-721,805-875`. |
| 17. Preflight upgrade conflicts before application | Pass | Complete plan construction before writes in `tools/knowme-builder/src/engine.rs:1074-1180`; no partial restoration/version advancement in `tools/knowme-builder/tests/cli.rs:805-851`. |
| 18. Implement explicit versioned migrations | Pass | Typed add/remove/rename/preserve operations in `tools/knowme-builder/src/migrations.rs:25-70`; alpha.3-to-alpha.4 migration and repeat no-op in `tools/knowme-builder/tests/cli.rs:308-362`. |
| 19. Provide journals, guarded rollback, and interrupted recovery | Pass | Prepared/applied journal and rollback protocol in `tools/knowme-builder/src/upgrade_journal.rs:146-253`; later-edit and interrupted-process coverage in `tools/knowme-builder/tests/cli.rs:972-1096`. |
| 20. Extend recovery to semantic migrations and historical fixtures | Pass | Checked-in alpha.3 fixture exercised in `tools/knowme-builder/tests/cli.rs:308-362`; semantic conflict and invalid inventory fail closed in `tools/knowme-builder/tests/cli.rs:573-656`. |
| 21. Integrate capability additions into project architecture | Pass | Planned application-owned registry and descriptor writes in `tools/knowme-builder/src/engine.rs:51-223`; multi-surface integration and upgrade survival in `tools/knowme-builder/tests/cli.rs:365-425`. |
| 22. Complete runnable baseline applications and persisted slice | Pass | Fresh hybrid generation coverage in `tools/knowme-builder/tests/cli.rs:281-304`; shared Rust notes domain in `assets/templates/baselines/web/rust/gen_ui_notes/src/lib.rs:2-20`; Tauri boundary in `assets/templates/baselines/tauri/desktop/src-tauri/src/main.rs:8-50`; Flutter FFI boundary in `assets/templates/baselines/flutter/rust/gen_ui_ffi/src/api/notes.rs:15-46`. Local build/run results are retained in `docs/assessment/generated-application-certification.md:15-30`. |
| 23. Verify bridge/codegen and architectural boundaries | Pass | Flutter bridge/provider generation and Rust/Flutter checks in `.github/workflows/scaffold-ci.yml:184-196`; deterministic architecture-marker tests in `runtime/tests/native-helpers.test.mjs:60-74`; current runtime suite passes. |
| 24. Build and execute claimed targets on native runners | Pass | Exact-head [run 36322460747](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/actions/runs/36322460747) passed Windows x64 and ARM64 packaged UI relaunch, iOS simulator relaunch, Android ARM64 APK inspection, and Android x86_64 instrumentation relaunch. |
| 25. Rebuild/run migrated historical and brownfield fixtures | Pass, with native repetition covered by task 24 | Local historical and brownfield results in `docs/assessment/generated-application-certification.md:24-25`; brownfield build/run and byte preservation in `.github/workflows/scaffold-ci.yml:82-90`; historical migration/build/run gate in `.github/workflows/scaffold-ci.yml:146-155`. |
| 26. Stage identical full/mini payloads | Pass | Variant-independent payload construction and hashing in `runtime/src/stage-skill-package.mts:8-58`; identical hash/file-list and isolated install assertions in `runtime/tests/staged-package.test.mjs:10-30`; current runtime suite passes. |
| 27. Independently review runtime and recovery | Pass | Initial blocking findings and resolved rereviews in `docs/assessment/review/runtime-findings.json:1-60`, `runtime-rereview.json:1-3`, `journal-findings.json:1-24`, `journal-rereview.json:1-3`, `remaining-runtime-findings.json:1-40`, and `remaining-runtime-rereview.json:1-3`. |
| 28. Complete generated-application certification review | Pass | The retained cross-model BLOCK receipts drove the strict Android correction and exact-head rerun; `findings-final-rereview-2.json` records PASS with zero findings and the strict anti-theater gate scores 0.0. |

## Requirement and scenario evidence map

### Portable tool runtime

#### R1. First-party portable execution — implemented and locally verified

Contract: `openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/specs/portable-tool-runtime/spec.md:8-14`.

- Shipped TypeScript compiler/runtime contract: `runtime/package.json:6-18` and
  `runtime/tsconfig.json:2-7`.
- First-party shell/Python rejection with isolated vendor exceptions:
  `runtime/src/stage-skill-package.mts:31-45`.
- Current runtime verification: 30 tests passed.

**Scenario 1: Clean Windows consumer — covered.** Hook execution consumes real stdin,
produces protocol JSON, and returns successfully for malformed advisory inputs in
`runtime/tests/portable-consumer.test.mjs:13-25`. Copied-package installation avoids a
full source checkout and preserves consumer configuration in
`runtime/tests/portable-consumer.test.mjs:27-47`. Cross-platform process invocation uses
argument arrays in `runtime/tests/portable-consumer.test.mjs:50-60`. The retained Windows
portable-tooling run is identified, with its exact commit, in
`docs/portability/project-tools.md:66-70`; native generated-application proof is recorded by task 24.

#### R2. Honest platform evidence — implemented and locally verified

Contract: `openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/specs/portable-tool-runtime/spec.md:16-21`.

- Target installation, host-native support, SDK availability, build, and execution are
  represented separately in `tools/knowme-builder/src/native.rs:9-85,101-164`.
- Documentation explicitly rejects treating installed Windows standard libraries on macOS
  as a Windows build/run receipt in `docs/portability/project-tools.md:59-64,76-85`.

**Scenario 2: Cross target installed on macOS — covered.** The non-Windows CLI test requests
both MSVC targets and requires a failed result containing the Windows-runner limitation in
`tools/knowme-builder/tests/cli.rs:1154-1171`.

#### R3. Reproducible package payload — implemented and locally verified

Contract: `openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/specs/portable-tool-runtime/spec.md:23-28`.

- Full and mini variants consume the same collected byte map in
  `runtime/src/stage-skill-package.mts:8-58`.
- Hashes cover sorted paths and contents; platform-invalid paths and source-checkout staging
  are rejected before installation.

**Scenario 3: Staged package smoke — covered.** Both variants are copied outside the source
checkout, verified, installed, and uninstalled; their payload hashes and file lists must be
identical in `runtime/tests/staged-package.test.mjs:10-30`.

### Project evolution

#### R4. Non-destructive brownfield integration — implemented and locally verified

Contract: `openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/specs/project-evolution/spec.md:9-14`.

- Adoption partitions actual profile surfaces into detected and missing lists, retains a
  skeleton/unverified status, and records incremental integration steps in
  `tools/knowme-builder/src/engine.rs:880-910`.
- Existing adopted projects continue to report persisted detected/missing surfaces in
  `tools/knowme-builder/src/engine.rs:810-878`.

**Scenario 4: Adoption preview — covered.** `adopt --check` reports detected surfaces,
missing surfaces, and integration steps while leaving `.knowme-builder` absent; apply then
preserves the user file and a repeated apply is unchanged in
`tools/knowme-builder/tests/cli.rs:76-143`.

#### R5. Continuous versioned upgrades — implemented and locally verified

Contract: `openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/specs/project-evolution/spec.md:16-37`.

- Explicit migration operations and compatibility checks:
  `tools/knowme-builder/src/migrations.rs:25-70,180-341`.
- Persistent journal, original/applied digests, metadata snapshots, and guarded rollback:
  `tools/knowme-builder/src/upgrade_journal.rs:146-253`.
- Current Builder verification: 18 unit tests and 27 CLI tests passed.

**Scenario 5: Edited managed output — covered.** User bytes remain unchanged, a proposed
sidecar is emitted, and the alpha.3 version remains applied in
`tools/knowme-builder/tests/cli.rs:573-604`. Same-version conflict preflight also prevents
partial restoration in `tools/knowme-builder/tests/cli.rs:805-851`.

**Scenario 6: Repeated migration — covered.** The named alpha.3-to-alpha.4 migration records
its ID, and a second apply returns `changed: false` in
`tools/knowme-builder/tests/cli.rs:308-350`.

**Scenario 7: Interrupted upgrade — covered.** A persisted prepared journal blocks further
check/apply operations until rollback restores the pre-application state in
`tools/knowme-builder/tests/cli.rs:1045-1096`. Prefix-level interruption cases are also unit
tested in `tools/knowme-builder/src/upgrade_journal.rs:340-455`.

**Scenario 8: User edit after upgrade — covered.** Rollback detects bytes that match neither
the original nor applied digest, preserves the later edit and applied metadata, and succeeds
only after resolution in `tools/knowme-builder/tests/cli.rs:972-1036`.

**Scenario 9: Concurrent Builder operation — covered.** A native exclusive lock causes apply
to fail without restoring the missing managed file; apply succeeds after the lock is released
in `tools/knowme-builder/tests/cli.rs:1099-1151`.

#### R6. Verified runnable baselines — implementation and native execution verified

Contract: `openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/specs/project-evolution/spec.md:39-44`.

- Runnable profiles emit web, Tauri, Flutter/FFI, and shared Rust boundaries with a persisted
  notes slice; representative source locations are listed under task 22.
- Fresh-output build, codegen, architecture, and runtime gates are defined in
  `.github/workflows/scaffold-ci.yml:60-211`.
- Host-specific execution claims are supported by run 36322460747. Task 28 remains the
  independent certification gate.

**Scenario 10: Missing native prerequisites — covered.** `new --mode runnable` accepts
repeatable `--target` and `--verify-ffi`, runs requested-capability inspection before
destination-state checks or staging, and returns before writes when inspection fails in
`tools/knowme-builder/src/engine.rs:1648-1683`. The missing-target CLI test proves the
destination remains absent in `tools/knowme-builder/tests/cli.rs:145-167`.

## Design coherence

The implementation follows the reviewed boundary in
`openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/design.md:5-10`: Node owns portable
hook and orchestration behavior; Rust owns native diagnostics, generation, adoption, and
evolution. One Rust generator remains authoritative. Generated ownership and rendering inputs
are explicit, upgrade plans are validated before managed application writes, and recovery is
persisted rather than inferred from an in-memory failure state.

Evidence is also separated coherently. Source generation emits an explicit warning that it is
not host certification (`tools/knowme-builder/src/engine.rs:1669-1682`); platform diagnostics
do not promote a cross-target installation to linking or execution; and the certification
receipt requires UI-driven persistence across process relaunch rather than accepting a build
or SQLite-file creation alone (`docs/assessment/generated-application-certification.md:32-52`).

The synchronized main specifications in `openspec/specs/portable-tool-runtime/spec.md:1-30`
and `openspec/specs/project-evolution/spec.md:1-46` preserve the six requirements and ten
scenarios from the change deltas. Strict validation passes.

## Archive result

All implementation and certification gates pass. The delta requirements were already
synchronized into the main specifications, and the completed change is archived under
`openspec/changes/archive/2026-09-27-portable-tooling-and-project-evolution/`.
Strict validation passes for both affected main specifications. Repository-wide strict
validation still reports unrelated legacy changes without deltas and older placeholder
purpose sections; those pre-existing items are outside this change.
