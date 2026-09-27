# Scaffold and continual-evolution assessment

Assessed 2026-09-26 against the source checkout before portability changes. Software-domain `evolve-assess`; source inspection only, not a claim of successful application builds. Evidence locations below refer to that initial source revision. Findings remain open unless subsequent verification receipts explicitly close them.

## Current suitability

The package has useful architecture instructions, profile selection, staging, ownership digests and non-destructive intent. The current generator does **not** deliver the advertised runnable web, desktop or Flutter applications. None of the five profiles has an emitted complete user-facing application with current build-and-launch evidence. Historical reference-app success must not be substituted for fresh generator output.

| Profile | Actual runnable-template payload | Missing baseline |
|---|---|---|
| sovereign-hybrid | Rust deterministic facade/test, Dart facade/test and Node HTTP facade/test | Flutter entrypoint/SDK dependency/native projects/FRB; React entrypoint/build stack; native Tauri application; actual persistent Rust feature |
| governed-web-shell | Axum echo endpoint and Node entity transport/test | React application and feature layers; typed Rust application service/repository; real service prerequisite and persistence |
| flutter-mobile | README, minimal pubspec, Rust README | Entire Flutter app, native projects, Rust crate and bridge |
| tauri-desktop | README, package metadata, Rust README | React app, Tauri manifest/native entrypoint, Rust crate |
| axum-web | README, package metadata, Cargo package header | React app and Rust executable/library targets |

Evidence: [profile claims](../../builder.manifest.json#L28), [Flutter manifest](../../assets/templates/profiles/flutter-mobile/runnable/mobile/pubspec.yaml#L1), [desktop manifest](../../assets/templates/profiles/tauri-desktop/runnable/desktop/package.json#L1), [Axum manifest](../../assets/templates/profiles/axum-web/runnable/server/Cargo.toml#L1). The builder selects and copies exactly one profile directory, without composing the richer dormant templates: [engine](../../tools/knowme-builder/src/engine.rs#L808). It marks all declared surfaces supported based on the manifest boolean, not proof: original engine lines 870–885. Validation checks only three control files: original engine lines 1157–1167. Audit checks directory existence: original engine lines 205–229.

## Architecture and evidence gaps

- No current emitted profile implements the specified feature-based clean architecture through actual UI, state/use-case, repository interface and Rust persistence. Sovereign Dart and JS facades are disconnected examples, not native bridges. The JS facade performs HTTP itself: [facade](../../assets/templates/profiles/sovereign-hybrid/runnable/desktop/src/uar-facade.mjs#L7).
- The advertised persisted/restart slice is a `BTreeMap` in one Rust runtime instance: [implementation](../../assets/templates/profiles/sovereign-hybrid/runnable/rust/src/lib.rs#L50). Its test calls `recover` on that same instance: [test](../../assets/templates/profiles/sovereign-hybrid/runnable/rust/tests/vertical_slice.rs#L6). This proves neither process restart nor disk durability. Approval-required is followed immediately by a tool-result event without approval handling.
- Governed-web-shell declares a verified session type but its handler never authenticates or authorizes and merely echoes input: [handler](../../assets/templates/profiles/governed-web-shell/runnable/server/src/lib.rs#L28). This must remain explicitly a deterministic fixture until a real service boundary is connected.
- Structural verification compares paths/metadata and parses TOML, without building: [verification](../../scripts/verify-scaffold.sh#L53). The current convergence workflow compares byte-stable generation for only two profiles, on Linux/macOS: [workflow](../../.github/workflows/production-convergence.yml#L54).
- Legacy compile CI excludes FFI and expects crates/paths that the current wrapper no longer generates: [workflow](../../.github/workflows/scaffold-ci.yml#L89). Flutter CI stops at dependency resolution: original lines 139–148.
- Historical completion evidence identifies a July commit and reference app, not the current builder: [receipt](../goal-completion-evidence.md#L3). Preserve it as historical evidence; do not reuse its completion status.

## Inputs and preflight

Current typed CLI accepts profile/mode/path only. Legacy hybrid wrapper explicitly ignores remaining options; rust-core wrapper now generates an entire hybrid profile. Conversion must preserve intent by rejecting unknown/unsupported options before any destination write. Do not silently drop organization, target or runtime requests.

Render identifiers derive from directory basename: original engine lines 1014–1023 and 1186–1200. There is no separate display name, Dart snake_case package name, Rust crate identifier, npm package name or application identifier. Leading digits, punctuation-only names, Unicode, reserved Windows names and hyphens in Dart package names require language-specific validation or normalization. Persist resolved identity so moving/renaming a project does not rename its package during upgrade.

Preflight matrix should cover all five profiles × runnable/skeleton; Windows x64/ARM64, macOS and Linux; supported build targets and required SDKs; spaces/Unicode and invalid identifiers; absent tools; existing/empty destination; current/old/unsupported state schemas. Invalid requests must reject pre-write. Missing host-only SDKs must report blocked capability rather than silently claiming certification.

## Brownfield and continual upgrades

The original `adopt_project` (engine lines 577–658) writes requested surfaces as enabled, sets runnable mode and no unsupported surfaces without inspecting the application. Its empty generated lock correctly avoids taking ownership of user code, but therefore provides no code-upgrade path. Control files are written while later conflicts are still being discovered, allowing partial adoption. Existing skill locks get proposals rather than overwrites, a useful behavior to retain.

`add_capability` (engine lines 43–99) copies isolated snippets to `.knowme-builder/additions/<kind>/<name>` and discards the generated ownership lock. It does not integrate dependencies, routing, imports, schemas or app behavior. Report this as a proposal/snippet capability, not completed application alteration.

Original `upgrade_project` (engine lines 661–760) iterates existing lock entries only. New template paths are never added; removed templates fail lookup; removals/renames have no migration representation. Rendering uses the current destination basename. It writes pristine files before discovering conflicts later in the list and always advances the lock version on apply, even with conflicts. It does not validate schemas/version compatibility, preserve a persistent transaction journal, roll back after interruption, or update project version coherently. These prevent a truthful continual-upgrade claim.

Immediate foundation: validate supported state schemas/version, retain render identity, inventory adoption without runnable claims, plan all writes/conflicts before apply, preserve lock/project versions on conflicts, and protect managed paths against symlink escape. Subsequent migration framework must provide versioned IDs and source/target compatibility, old/new content baselines, explicit add/remove/rename actions, persistent journal/backups/recovery/rollback, and nonstandard brownfield surface mappings. Destructive data migrations need separately reviewed plans and backups.

## Ordered acceptance recommendations

1. Complete portable hooks/tooling first, keeping native generation and ownership operations in Rust. Add native target diagnostics for `x86_64-pc-windows-msvc` and `aarch64-pc-windows-msvc`; installed Rust std libraries alone do not establish MSVC, Windows SDK, native dependency or launch readiness.
2. Repair baseline profiles with one complete clean-architecture feature, pinned toolchain/dependencies, generated bridges and platform entrypoints. Prove fresh output, not a maintained demo.
3. For web: build frontend/server, launch browser and API, mutate via Rust repository and recover after restart. For desktop: build and launch real Tauri on each claimed OS/architecture, execute command and prove restart persistence. For mobile: complete FRB/provider/model generation, compile FFI leaf with shared core, analyze/build and run Android and iOS on eligible hosts. Hybrid must exercise matching shared types across its surfaces.
4. Keep optional inference/auth/cloud/production UAR integrations distinct. A deterministic offline baseline is useful but cannot certify real model execution, policy enforcement, physical-device performance or production storage. Windows ARM64 optional dependencies need explicit compatibility evidence.
5. For brownfield/upgrade: exercise actual existing app fixtures, pristine/edited old output, moved directories, unsupported schemas, new/removed/renamed files, failure mid-apply, recovery and rollback. Dry runs are byte-identical; conflicts preserve user files and applied versions; successful repeat is a no-op; migrated apps rebuild and run.

Unknowns: current native Windows execution, physical mobile inference, external service availability, and current dependency/security health were not measured in this read-only audit. No pass rate or build-health score is invented.
