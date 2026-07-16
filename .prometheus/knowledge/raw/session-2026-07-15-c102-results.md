# Session results 2026-07-15/16 — C-102 first codegen run + desktop branding round (knowme-poc)

Project: hybrid-mobile-architecture-src (TJ-ARCH-MOB-001 skill package)
Phase: phase-codegen-and-ci-verification. Changes C-101 and C-102 merged to main
(commits 86e7d1d and 2c169a6). Spec of record now at
docs/reference-app/knowme-poc-architecture-and-implementation-plan.md.

## Outcome

The first-ever full codegen pipeline run against a scaffolded app (apps/knowme-poc)
succeeded after ~25 real defects were found and fixed — every fix applied to the
scaffold scripts (source of truth) AND the generated app in parallel, each verified by
re-running the failing tool before moving on. Final state: cargo check --workspace
clean (13 crates), flutter analyze 0 errors/0 warnings, tsc --noEmit clean, tauri dev
runs with zero console errors on both the native window and a plain browser tab, and
tauri build --debug produces a .app bundle with the correct KnowMe Dock icon.

## Durable lessons (highest value for future sessions)

1. isTauri() gating rule: one Vite bundle serves both the native Tauri webview and
   plain web. ANY Tauri API called unconditionally at module/init scope
   (getCurrentWindow(), listen()) throws in a plain browser (no __TAURI_INTERNALS__)
   and can blank the whole app WITH NO console error (module-graph abort). Every
   Tauri call must be gated behind isTauri() and degrade to a no-op. Three violations
   found: Titlebar.tsx module-scope getCurrentWindow(), chatStore.initListeners(),
   flintSurfaceStore.start().
2. Tauri v2 denies ALL IPC/events by default. Without src-tauri/capabilities/default.json
   the frontend's own event.listen() throws "event.listen not allowed" at runtime.
   Scaffolds must emit a capabilities file (core:default + window controls + plugin
   defaults) from day one.
3. Register stub Tauri commands from day one. The scaffold's frontend called
   run_migrations/load_seeds/attach_sync_shapes unconditionally at startup while
   invoke_handler was commented out ("uncomment when gen_ui_core is wired") — every
   launch hard-failed with "Command run_migrations not found". Frozen signatures with
   Ok(()) stub bodies let the app boot before backends land; Wave-1 fills them in
   without touching frontend call sites.
4. tauri dev cannot show a real Dock icon on macOS. cargo run produces a bare Mach-O
   executable with no Info.plist, so macOS shows a generic/cached icon (it showed
   Firefox's!). The icon asset can be perfect and it won't matter. Only tauri build
   (or --debug --bundles app) produces the .app bundle with CFBundleIconFile wired.
   Verify icons via the bundle, never via dev mode.
5. tauri scaffold essentials that create-tauri-app implies but our scaffold missed:
   build.rs + [build-dependencies] tauri-build (generate_context! needs OUT_DIR);
   main.rs must reference the actual [lib] name (never literal app_lib); icons must
   exist before the app can even cargo check (generate_context! reads them at compile
   time); generate placeholder icons with stdlib-python PNG + `npx tauri icon`.
6. flutter_rust_bridge 2.12 codegen quirks: rust_input takes Rust module syntax
   (crate::api), NOT a filesystem path; frb auto-injects `mod frb_generated;` at line 1
   which lands ABOVE inner doc comments (//!) and causes E0753 — move the injected line
   below the doc block; api modules must `pub use` (not `use`) the types their
   signatures reference, because frb_generated.rs re-exports via
   `use crate::api::x::*` and private imports are invisible to a glob.
7. Riverpod 3.3.2 API surface realities (verified by source inspection): Mutation
   exists internally (riverpod/src/core/mutations.dart) but is NOT on the public
   export allowlist — use local bool pending-state instead; riverpod_generator drops
   "Notifier" from provider names (class ChatNotifier -> chatProvider); AsyncValue
   has .value (nullable getter), not .valueOrNull.
8. Dependency pins must be verified against live registries at scaffold-authoring
   time (Base Rules 22/23). Found invented versions (shadcn_flutter ^0.1.6 — latest
   real is 0.0.53, riverpod_lint ^4.0.0 — doesn't exist) and stale ones
   (riverpod_sqflite, freezed 2.x vs required 3.x, json_annotation, Dart SDK floor).
   custom_lint/riverpod_lint removed entirely — unresolvable analyzer conflict as of
   2026-07.
9. pnpm git+path subdirectory dependencies are unreliable: @flint/react pinned as
   git+https://...flint-forge.git#<sha>&path:packages/flint-react fetched a tarball
   containing ONLY package.json+SKILL.md (no src). Workaround (user-approved): clone
   the pinned commit, build with tsc (excluding upstream test files with pre-existing
   strict-TS errors), vendor dist into the pnpm store path, add .mjs copies for the
   exports "import" condition. Real fix belongs in flint-forge packaging.
10. PEM tarball pre-resolve fell back: pnpm pack failed inside PEM_HOME (corepack
    packageManager pin mismatch), so the strip-PEM fallback is what actually ran for
    the desktop app. Re-enabling the tarball path requires fixing corepack state in
    the PEM monorepo checkout.
11. pnpm supply-chain gate (ERR_PNPM_IGNORED_BUILDS): esbuild's postinstall is blocked
    by default, so Vite cannot start until `pnpm approve-builds` runs (user-approved
    esbuild + es5-ext). The bare install exits 0 — the failure only appears when the
    dev server starts. Also: pnpm's pre-script "deps status check" re-runs install and
    DOES fail the beforeDevCommand where a direct install wouldn't.
12. set -euo pipefail trap catalogue (bash scaffolds): cargo-ndk --version exits 1
    when invoked directly (must be `cargo ndk`); grep-no-match kills scripts —
    guard command substitutions with `|| VAR=""`; `ls nomatch* | head -1` still fails
    under pipefail because ls's own exit propagates.
13. TS 7.0.2 removed baseUrl (error TS5102) — keep paths only; a missing
    src/vite-env.d.ts breaks .css and ?raw imports under tsc --noEmit.
14. CSS @import ordering with Tailwind 4: the Google Fonts @import must precede
    @import "tailwindcss", otherwise PostCSS errors (@import must precede all other
    statements) because the tailwind import expands to rules first.
15. data-tauri-drag-region JSX gotcha: ={false} renders the attribute as the string
    "false" and Tauri checks presence, not value — omit the attribute entirely on
    non-draggable children. For reliable dragging call
    getCurrentWindow().startDragging() from onMouseDown (button 0) on the bar.

## KnowMe brand tokens (extracted from docs/reference-app HTML, now in desktop CSS)

Dark (default): bg #0B0F14, bg-2 #111620, surface #161D29, card #1C2535, card-hov
#202B40, border #1F2D40, muted #253044, fg #E8EDF3, fg-sub #A7B0BC, ember #FF6A3D
(brand), ember-2 #E04E28, cyan #00C2DC (AI voice), green #22C55E, amber #F59E0B,
red #EF4444. Light overrides: bg #F7F7F8, ember #E04E28, cyan #0891B2.
Fonts: Space Grotesk (display, negative tracking), Inter (UI/body), Roboto (long-form,
weight 300 leads), JetBrains Mono (uppercase tracked eyebrows 0.1-0.12em, code).
Logo: rounded-bar K monogram, ember dot at the joint; wordmark Know + ember Me.
Icon source: desktop/branding/app-icon-source.svg -> npx tauri icon.

## Desktop shell decisions (this session, user-directed)

- Custom branded titlebar (decorations:false), platform-aware controls (traffic-light
  left on macOS, Windows-style right elsewhere), drag via attribute + startDragging().
- Native menu: File (Exit, CmdOrCtrl+Q) / View (Fullscreen, separator, Toggle
  Developer Tools LAST — user-specified placement, CmdOrCtrl+Alt+I, devtools cargo
  feature enabled) / Help (About). Menu event ids: "exit", "toggle_devtools".
- tauri-plugin-os added for platform detection (its platform() is SYNCHRONOUS in 2.x).

## Process notes

- Auto-mode classifier correctly blocked two actions: corepack disable (global change
  with an existing fallback) and building a manually-cloned external repo (untrusted
  code integration — later user-approved via AskUserQuestion). Pattern: use fallbacks
  first, escalate with explicit user choice when integration of external code is
  genuinely needed.
- The /loop goal ("functioning app tested on web and desktop via Tauri") was met and
  the loop stopped by user choice. C-103..C-110 remain (chat live e2e, memory
  graph-RAG, local model, sync, whisper, MCP+agent, settings, CI).
