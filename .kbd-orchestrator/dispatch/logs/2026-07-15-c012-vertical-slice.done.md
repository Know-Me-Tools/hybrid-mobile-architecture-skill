# C-012 vertical-slice — completion summary

**Change:** `2026-07-15-c012-vertical-slice` (Wave 2, depends on C-010/C-011)
**Model:** claude-opus-4-8 · **Status:** done

## What was delivered

Completed the KnowMe-class vertical slice by adding the two missing seams —
**memory / graph-RAG** and the **first-run startup flow** — to the example apps
that C-010 (Flutter) and C-011 (React) already emit, wired identically on all
four targets (iOS sim, Android, macOS Tauri, web). Extended `audit.sh` to verify
layer contracts and added an `all` cross-surface mode. Behavior tests per the
CLAUDE.md testing philosophy (features-first, boundary-only, fakes only at the
real IO edge). This repo emits scaffolds — all app code lives in the three
scaffold scripts' heredocs, not committed as app files.

### Files modified (3, all in scope)

- **`scripts/scaffold-flutter.sh`** (+~505) — added to the emitted mobile app:
  - Bridge facade intents: `memoryIngest` / `memorySearch` / `graphExpand`
    (+ `MemoryHit` mirror of `gen_ui_db::graph::EntityHit`) and the startup
    orchestrator intents `runMigrations` / `loadSeeds` / `attachSyncShapes`.
  - `features/memory/` — `MemoryNotifier` (`@riverpod`, sync `build()`, `ref.mounted`
    guard, `applyHits` boundary seam mirroring chat's `foldStream`) + ingest→search
    panel driven by the Riverpod 3 Mutations API.
  - `features/startup/` — `StartupPhase` enum (boot-order invariant migrations→
    seeds→shapes→ready), `startup` stream provider with `@Riverpod(retry: _noRetry)`
    (FFI errors terminal), and `StartupGate` that blocks the shell until ready.
  - Router: added Memory tab (tab list refactored to a single source of truth);
    `main.dart` wraps the router host in `StartupGate`.
  - 2 new boundary tests (memory fold, boot-order invariant) → 5 total.

- **`scripts/scaffold-tauri.sh`** (+~388) — added to the emitted desktop/web app,
  Component→Hook→Store layering enforced:
  - `features/memory/` — `memoryStore` (the only `invoke()` layer; terminal error
    handling, no silent retry), `useMemory` hook, `MemoryPanel` component.
  - `features/startup/` — `startupStore` (sequences `run_migrations`→`load_seeds`→
    `attach_sync_shapes`), `useStartup` hook (derives label/progress so components
    import only the hook), `StartupGate` component; `main.tsx` wraps the app.
  - Vitest added (config + devDeps) + 5 boundary tests (memory fold, memory
    terminal-error/no-retry, boot order, boot halt-on-failed-migration, progress).
  - Documented the memory/startup Tauri commands in the `lib.rs` handler block.

- **`scripts/audit.sh`** (+~185) — layer-contract enforcement:
  - Flutter: FFI facade reachable only via providers (not screens/widgets); no raw
    SurrealQL/SQL in Dart; FFI providers opt out of Riverpod-3 retry; KnowMe-slice
    feature presence (chat/notes/memory/startup + sync chip).
  - Tauri: robust store-import-in-component and `invoke()/listen()`-outside-stores
    checks (comment-stripped to avoid prose false-positives); no raw SurrealQL
    outside stores; empty placeholder features skipped; KnowMe-slice presence.
  - New `all` mode: auto-descends into the nested `<project>/` dir, audits both UI
    surfaces, and detects the layered rust workspace (skips the monolithic rust
    module audit for `rust/crates/*`, pointing to `cargo clippy`).

## Verification

- `bash -n` clean on all three scripts.
- Ran `scaffold-flutter`, `scaffold-tauri`, and full `scaffold-hybrid` end-to-end
  in scratchpad; all four features + 5 tests emit on each surface.
- `audit.sh flutter` → 38 pass / 0 fail; `audit.sh tauri` → 44 pass / 0 fail;
  `audit.sh all` on the hybrid root → both surfaces compliant, rust workspace
  detected. (Warnings are expected: pre-codegen `.g.dart`/`.freezed.dart` absent.)
- **React boundary tests executed for real** in an isolated Vitest harness (FFI
  edge stubbed at `@tauri-apps/api/core`): **5/5 pass** — memory RRF fold, terminal
  error with no silent retry, boot order, halt-on-failed-migration (shapes never
  attach), monotonic progress.
- Dart domain layer analyzed clean standalone (`startup_phase.dart`,
  `memory_query.dart` + `MemoryHit`). Provider/screen/gate files resolve only
  after the documented `pub get` + `build_runner` step — same as C-010's chat/notes.

## Fixes made to pre-existing scaffold/audit bugs (WARNING-tier, backward-compatible)

- `audit.sh` tauri `[01]`: a single `< "$PKG"` stdin redirect let the first `grep`
  drain stdin and falsely fail every later dependency check — changed each grep to
  take `"$PKG"` explicitly. Needed for `audit.sh all` to pass on real output.
- Caught (via the new layer check) and fixed a genuine violation in my own first
  cut: `StartupGate.tsx` imported a store helper — moved the derivation into the
  hook so components import hooks only.

## Deviations / notes

- The layered rust workspace (C-001) has no monolithic `gen_ui_core` crate, so the
  `rust` platform audit (built for the single-crate model) is not run under `all`;
  the mode reports the workspace and defers to `cargo clippy` per-crate. This is
  the correct scope for C-012 (UI-surface layer contracts).
- Memory/startup FFI intents are stubbed in the bridge facades (throw
  `UnimplementedError` / no-op on web) exactly like C-010/C-011's chat/entity
  intents — they light up when `gen_ui_db` (C-003/C-004/C-005) is built and frb
  codegen runs. No networking/inference/persistence added to Dart or TS.

## Blockers

None. End-to-end pnpm/pub install still blocked upstream until PEM/Flint publish
consumable packages (external dep gap per analysis §1.7) — unchanged from C-011,
not introduced here.
