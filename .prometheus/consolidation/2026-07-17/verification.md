# Consolidation Verification Evidence

Date: 2026-07-17
Integration branch: `codex/consolidate-main`

## Preserved history

- Root `.prometheus`: 252 final wiki pages, exceeding the 238-page source union.
- Desktop `.prometheus`: 20 final wiki pages, matching the 20-page source union.
- Tauri `.prometheus`: 3 final wiki pages, matching the 3-page source union.
- Rust `.prometheus`: 34 final wiki pages, matching the 34-page source union.
- Root `events.jsonl`: 731 de-duplicated event records with conflicting variants retained under provenance.
- Source provenance and SHA-256 entries are recorded in `.prometheus/consolidation/2026-07-17/pre-consolidation-manifest.json` and the generated wiki merge manifests.

## Integrated KnowMe app proof

The integrated KnowMe example app was verified from the consolidated tree before the final scaffold repair pass:

| Surface | Evidence |
| --- | --- |
| Desktop dependencies | Frozen install completed from tracked package metadata. |
| Desktop static checks | `pnpm exec tsc --noEmit` passed. |
| Desktop behavior tests | Vitest passed 10/10 tests. |
| Desktop production build | Vite production build passed. |
| Desktop Tauri build | Tauri release `--no-bundle` build passed on Rust 1.96. |
| Desktop real launch | Clean app-data launch reached ready, ran migrations/seeds/local sync, created config, memory, and model-cache data. |
| Desktop public workflow | Seeded memory search returned ranked BossFang results; a configuration-specific Ollama `llama3.2:1b` prompt streamed `ContentBlock` output through the real UI. This historical proof does not satisfy the newer zero-configuration downloaded-Mistral requirement; see the addendum below. |
| Production web | Served built web bundle rendered without browser console errors after the PGlite startup race and favicon fixes. |
| Rust workspace | Workspace clippy with warnings denied, graph behavior tests, and full workspace tests passed. |
| Flutter app | FRB/Riverpod generation, analyze, tests, iOS simulator build, and simulator launch passed; Rust boot reached ready and the shell rendered. |
| Architecture | `bash scripts/audit.sh all apps/knowme-poc` reported zero failures. |

## Final clean scaffold gate

Temporary project: `$TMPDIR/knowme-commit-gate/generated`

| Gate | Command | Result |
| --- | --- | --- |
| Environment | `bash scripts/check-env.sh` through `scripts/scaffold-hybrid.sh` | Passed; Rust, Flutter beta/Dart MCP, Node 24, pnpm, Tauri CLI, and Prometheus Skill System detected. |
| Scaffold generation | `bash scripts/scaffold-hybrid.sh $TMPDIR/knowme-commit-gate/generated --org ai.prometheusags --uar embedded` | Passed; Rust workspace, publishable packages, Flutter app, Tauri app, project skills, and docs generated. |
| PEM npm version | `rg '3\.0\.0-alpha\.0' desktop/package.json desktop/pnpm-lock.yaml` | Passed; generated desktop uses `@prometheus-ags/prometheus-entity-management` 3.x alpha and locks its 3.x graph dependency. |
| Rust pin | `rg '1\.96' rust/rust-toolchain.toml rust/Cargo.toml` | Passed; generated Rust uses toolchain/channel and crate rust-version `1.96`. |
| PEM Flutter package codegen compatibility | `rg 'abstract class|SyncStatus.fromJson' flutter_packages/prometheus_entity_management/lib` | Passed; Freezed 3-compatible abstract classes and Rust enum JSON decoding emitted. |
| Flutter analysis | `flutter analyze` in generated `mobile/` | Passed; no issues found. |
| Flutter tests | `flutter test` in generated `mobile/` | Passed; 6/6 tests including golden variants. |
| Desktop frozen install | `pnpm install --frozen-lockfile` in generated `desktop/` | Passed. |
| Desktop typecheck | `pnpm exec tsc --noEmit` in generated `desktop/` | Passed. |
| Desktop tests | `pnpm test -- --run` in generated `desktop/` | Passed; 5/5 tests. |
| Desktop production build | `pnpm build` in generated `desktop/` | Passed; Vite build completed. Upstream PGlite emitted direct-eval and chunk-size warnings. |
| Architecture audit | `bash scripts/audit.sh all $TMPDIR/knowme-commit-gate/generated` | Passed; zero failures. Warnings were placeholders/missing optional query layers and no generated app `.freezed.dart` files. |

## Final scaffold repairs captured

- `scripts/scaffold-hybrid.sh` now emits publishable local packages before Flutter/Tauri app generation, so path dependencies exist during first installs.
- `scripts/scaffold-packages.sh` now runs Flutter-bundled codegen for the generated Flutter PEM package, emits Freezed 3-compatible classes, and includes `SyncStatus.fromJson`.
- `scripts/scaffold-flutter.sh` now runs `flutter pub run build_runner build`, Flutter-bundled `dart fix --apply`, and golden baseline generation during scaffold.
- Documentation and audit guidance now use `flutter pub run build_runner` so standalone system Dart cannot shadow Flutter beta's bundled Dart.
- `scripts/check-env.sh` now verifies Dart MCP via Flutter's bundled Dart SDK.

## Current UI/runtime verification addendum

The Shadcn/Assistant UI and conversation-persistence iteration remains green for TypeScript,
Vitest (10/10), Vite, Tauri `--no-bundle`, targeted Rust tests, Riverpod/FRB generation, iOS
simulator build/launch, and the full architecture audit. The current browser UI was also checked
in both light and dark themes after repairing the Shadcn semantic-token aliases; both variants
rendered the Flat 2.0 surfaces with zero browser console errors.

The zero-configuration native lane now uses the pinned Qwen2.5 0.5B GGUF through llama.cpp on
both Flutter and Tauri. A real iOS simulator integration test exercised the complete public path
from Flutter UI through Riverpod, FRB, `gen_ui_agent`, llama.cpp, and streamed A2UI content. The
current Tauri release application then built successfully with the same llama.cpp engine and its
audio dependencies linked into one binary, and `tauri dev` launched the current application
without an Ollama environment variable. The former downloaded-Mistral/Candle paragraph above is
therefore superseded; Mistral remains an optional engine rather than the reference app default.

For web, WebLLM produced a real zero-key response. The production Axum host rendered the built
React application with no console errors; restricted verification shells without IndexedDB now
fall back to PGlite's in-memory filesystem while normal browsers continue to use persistent IDB.

The consolidation manifest contains 2,616 source-to-canonical/provenance mappings. A read-only
integrity verifier found zero missing canonical or history destinations across the root, desktop,
Tauri, and Rust wiki scopes. Machine-specific absolute paths were redacted to `$REPO_ROOT` or
`$HOME` in both the repository wiki and its private Karpathy mirror.

The exact staged Git index was exported with `git checkout-index` into a fresh temporary tree.
From that tree, `pnpm install --frozen-lockfile`, `pnpm exec tsc --noEmit`, all 10 Vitest tests,
and the production Vite build passed without relying on repository `node_modules`, ignored
`dist`, or cached application data. A staged-diff Gitleaks scan examined 3.79 MB and reported no
leaks.
