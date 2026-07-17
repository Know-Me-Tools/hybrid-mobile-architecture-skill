---
type: Reference
id: knowme-poc-first-codegen-run-and-tauri-desktop-fixes
title: KnowMe POC first codegen run and Tauri desktop fixes
tags:
- knowme-poc
- tauri
- codegen
- desktop-branding
- flutter-rust-bridge
- pnpm
- riverpod
- build-validation
links:
- codegen-and-ci-verification-session-ended-with-no-changes
- codegen-and-ci-verification-completed-with-unknown-change
- phase-codegen-and-ci-verification-completed-with-unknown-change
sources:
- /private/tmp/claude-501/-Users-gqadonis-Projects-hybrid-mobile-architecture-src/84f55edb-0314-410c-95ac-9b3d4008fd28/scratchpad/session-2026-07-15-c102-results.md
timestamp: 2026-07-16T01:38:44.952902+00:00
created_at: 2026-07-16T01:38:44.952902+00:00
updated_at: 2026-07-16T01:38:44.952902+00:00
revision: 0
---

## Context

- **Project:** `hybrid-mobile-architecture-src` / `apps/knowme-poc`
- **Skill package:** `TJ-ARCH-MOB-001`
- **Phase:** `phase-codegen-and-ci-verification`
- **Spec of record:** `docs/reference-app/knowme-poc-architecture-and-implementation-plan.md`
- **Merged changes:** `C-101` and `C-102` on `main` at commits `86e7d1d` and `2c169a6`

This session provides concrete validation evidence for the codegen/CI verification phase, superseding earlier completion-only or no-change records such as [Codegen and CI verification session ended with no changes](/codegen-and-ci-verification-session-ended-with-no-changes.md), [Codegen and CI verification completed with unknown change](/codegen-and-ci-verification-completed-with-unknown-change.md), and [Phase codegen and CI verification completed with unknown change](/phase-codegen-and-ci-verification-completed-with-unknown-change.md).

## Outcome

The first full codegen pipeline run against the scaffolded `apps/knowme-poc` app succeeded after approximately 25 real defects were found and fixed. Each fix was applied in parallel to:

- Scaffold scripts, as the source of truth.
- The generated app.

Each defect was verified by re-running the previously failing tool before continuing.

Final validated state:

- `cargo check --workspace` clean across 13 crates.
- `flutter analyze` clean: 0 errors, 0 warnings.
- `tsc --noEmit` clean.
- `tauri dev` runs with zero console errors in both:
  - Native Tauri window.
  - Plain browser tab.
- `tauri build --debug` produces a `.app` bundle with the correct KnowMe Dock icon.

The `/loop` goal, “functioning app tested on web and desktop via Tauri,” was met and stopped by user choice. Remaining changes: `C-103` through `C-110` for chat live E2E, memory graph/RAG, local model, sync, whisper, MCP/agent, settings, and CI.

## Durable engineering lessons

### Tauri API calls must be gated by `isTauri()`

One Vite bundle serves both the native Tauri webview and the plain web app. Any Tauri API called unconditionally at module or initialization scope can throw in a normal browser because `__TAURI_INTERNALS__` is absent. This can blank the app with no console error due to module graph abort.

Rule:

- Every Tauri API call must be gated behind `isTauri()`.
- Non-Tauri environments must degrade to no-op behavior.

Violations found and fixed:

- `Titlebar.tsx`: module-scope `getCurrentWindow()`.
- `chatStore.initListeners()`.
- `flintSurfaceStore.start()`.

### Tauri v2 requires explicit capabilities

Tauri v2 denies all IPC and events by default. Without `src-tauri/capabilities/default.json`, frontend `event.listen()` throws at runtime:

```text
event.listen not allowed
```

Scaffolds must emit capabilities from day one, including:

- `core:default`
- Window controls
- Plugin defaults

### Register stub Tauri commands immediately

The frontend called these commands unconditionally at startup:

- `run_migrations`
- `load_seeds`
- `attach_sync_shapes`

The `invoke_handler` was commented out with the intent to enable it later when `gen_ui_core` was wired. Result: every launch failed with:

```text
Command run_migrations not found
```

Scaffold rule:

- Register commands from day one.
- Freeze signatures.
- Use `Ok(())` stub bodies until backend implementation lands.
- Later waves can fill implementations without changing frontend call sites.

### macOS Dock icons cannot be validated with `tauri dev`

`tauri dev` / `cargo run` produces a bare Mach-O executable without an `Info.plist`. macOS may show a generic or cached icon, including an unrelated icon. In this session, it showed Firefox’s icon.

Icon validation rule:

- Do not validate Dock icons via dev mode.
- Validate via bundled app output from `tauri build` or `tauri build --debug --bundles app`, where `CFBundleIconFile` is wired.

### Required Tauri scaffold basics

The scaffold missed pieces that `create-tauri-app` normally implies:

- `build.rs` must exist.
- `[build-dependencies] tauri-build` is required because `generate_context!` needs `OUT_DIR`.
- `main.rs` must reference the actual `[lib]` name; never hard-code `app_lib`.
- Icons must exist before `cargo check`, because `generate_context!` reads them at compile time.
- Placeholder icons can be generated with stdlib Python PNG generation plus `npx tauri icon`.

### flutter_rust_bridge 2.12 codegen quirks

Verified quirks:

- `rust_input` expects Rust module syntax such as `crate::api`, not a filesystem path.
- `frb` auto-injects `mod frb_generated;` at line 1.
  - If the file begins with inner doc comments (`//!`), this causes `E0753`.
  - Move the injected line below the doc block.
- API modules must `pub use` any types referenced by signatures.
  - Plain `use` is insufficient.
  - `frb_generated.rs` re-exports through `use crate::api::x::*`, and private imports are invisible to a glob.

### Riverpod 3.3.2 public API realities

Verified by source inspection:

- `Mutation` exists internally at `riverpod/src/core/mutations.dart` but is not on the public export allowlist.
  - Use local boolean pending state instead.
- `riverpod_generator` drops `Notifier` from provider names.
  - `class ChatNotifier` generates `chatProvider`.
- `AsyncValue` has `.value` as a nullable getter.
  - It does not have `.valueOrNull`.

### Dependency pins must be registry-verified

Dependency pins must be checked against live registries at scaffold-authoring time. Problems found:

- Invented versions:
  - `shadcn_flutter ^0.1.6`; latest real version was `0.0.53`.
  - `riverpod_lint ^4.0.0`; did not exist.
- Stale or incompatible packages:
  - `riverpod_sqflite`
  - `freezed` 2.x where 3.x was required
  - `json_annotation`
  - Dart SDK floor
- `custom_lint` and `riverpod_lint` were removed entirely due to an unresolvable analyzer conflict as of 2026-07.

### pnpm git subdirectory dependencies were unreliable

The dependency:

```text
@flint/react = git+https://...flint-forge.git#<sha>&path:packages/flint-react
```

fetched a tarball containing only:

- `package.json`
- `SKILL.md`

It did not include `src`.

User-approved workaround:

1. Clone the pinned commit.
2. Build with `tsc`.
3. Exclude upstream test files that already had strict TypeScript errors.
4. Vendor `dist` into the pnpm store path.
5. Add `.mjs` copies for the package `exports.import` condition.

The permanent fix belongs in `flint-forge` packaging.

### PEM tarball pre-resolve fell back

`pnpm pack` failed inside `PEM_HOME` because the monorepo checkout had a `corepack` / `packageManager` pin mismatch. The desktop app therefore used the strip-PEM fallback path. Re-enabling the tarball path requires fixing corepack state in the PEM monorepo checkout.

### pnpm ignored build scripts can break Vite later

`ERR_PNPM_IGNORED_BUILDS` blocked `esbuild` postinstall by default. A bare install exited 0, but Vite could not start until `pnpm approve-builds` was run.

User-approved packages:

- `esbuild`
- `es5-ext`

Additional finding:

- pnpm’s pre-script “deps status check” re-runs install and does fail the `beforeDevCommand`, even where a direct install would not.

### Bash `set -euo pipefail` trap catalogue

Scaffold scripts must account for these failures:

- `cargo-ndk --version` exits 1 when invoked directly.
  - Use `cargo ndk` instead.
- `grep` with no match kills scripts.
  - Guard command substitutions with `|| VAR=""`.
- `ls nomatch* | head -1` still fails under `pipefail` because `ls` exits non-zero and propagates.

### TypeScript and Vite requirements

- TypeScript 7.0.2 removed `baseUrl`; using it causes `TS5102`.
  - Keep `paths` only.
- Missing `src/vite-env.d.ts` breaks `.css` and `?raw` imports under `tsc --noEmit`.

### Tailwind 4 import ordering

With Tailwind 4, the Google Fonts `@import` must precede:

```css
@import "tailwindcss";
```

Otherwise PostCSS errors because `@import` must precede all other statements and the Tailwind import expands to rules first.

### `data-tauri-drag-region` JSX gotcha

In JSX, `data-tauri-drag-region={false}` renders the attribute as the string `"false"`. Tauri checks attribute presence, not value.

Rules:

- Omit `data-tauri-drag-region` entirely on non-draggable children.
- For reliable dragging, call `getCurrentWindow().startDragging()` from `onMouseDown` on the bar when `button === 0`.

## KnowMe brand tokens applied to desktop CSS

### Dark theme defaults

| Token | Value | Notes |
|---|---:|---|
| `bg` | `#0B0F14` | base background |
| `bg-2` | `#111620` | secondary background |
| `surface` | `#161D29` | surfaces |
| `card` | `#1C2535` | cards |
| `card-hov` | `#202B40` | card hover |
| `border` | `#1F2D40` | borders |
| `muted` | `#253044` | muted elements |
| `fg` | `#E8EDF3` | foreground |
| `fg-sub` | `#A7B0BC` | subdued foreground |
| `ember` | `#FF6A3D` | brand color |
| `ember-2` | `#E04E28` | brand secondary |
| `cyan` | `#00C2DC` | AI voice |
| `green` | `#22C55E` | success |
| `amber` | `#F59E0B` | warning |
| `red` | `#EF4444` | error |

### Light overrides

- `bg`: `#F7F7F8`
- `ember`: `#E04E28`
- `cyan`: `#0891B2`

### Fonts

- **Space Grotesk:** display, negative tracking.
- **Inter:** UI and body.
- **Roboto:** long-form text, weight 300 leads.
- **JetBrains Mono:** uppercase tracked eyebrows at `0.1em`–`0.12em`, and code.

### Logo and icon

- Logo: rounded-bar `K` monogram with an ember dot at the joint.
- Wordmark: `Know` + ember `Me`.
- Icon source: `desktop/branding/app-icon-source.svg`.
- Icon generation: `npx tauri icon`.

## Desktop shell decisions

User-directed desktop shell decisions:

- Custom branded titlebar with `decorations: false`.
- Platform-aware window controls:
  - macOS traffic-light controls on the left.
  - Windows-style controls on the right elsewhere.
- Dragging implemented via drag-region attributes plus `startDragging()`.
- Native menu:
  - **File**
    - Exit
    - Shortcut: `CmdOrCtrl+Q`
  - **View**
    - Fullscreen
    - Separator
    - Toggle Developer Tools last, per user direction
    - Shortcut: `CmdOrCtrl+Alt+I`
    - DevTools cargo feature enabled
  - **Help**
    - About
- Menu event IDs:
  - `exit`
  - `toggle_devtools`
- Added `tauri-plugin-os` for platform detection.
  - Its `platform()` API is synchronous in Tauri 2.x.

## Process notes

The auto-mode classifier correctly blocked two actions:

1. Disabling `corepack`, because it was a global change with an existing fallback.
2. Building a manually cloned external repository, because it was untrusted code integration.

Pattern retained for future sessions:

- Use fallbacks first.
- Escalate only with explicit user choice when integration of external code is genuinely needed.

# Citations

1. [1] /private/tmp/claude-501/-Users-gqadonis-Projects-hybrid-mobile-architecture-src/84f55edb-0314-410c-95ac-9b3d4008fd28/scratchpad/session-2026-07-15-c102-results.md
