# C-007 ffi-leaves-packaging — DONE (claude/opus-4.8, in-session)

Fleshed out the three FFI/web leaf crates (previously C-001 seam stubs) into full
working surfaces and added the publishing scaffolds, all as generator scripts (the
repo produces projects, it is not itself an app). Leaves stay THIN and re-export
only the FROZEN `gen_ui_types` seam types over intent-level APIs — never raw
SQL/SurrealQL across a bridge — so Wave-1 lanes (C-003/4/5 db, C-006 client/agent)
wire implementations behind these signatures without touching the leaf surface.

## Files modified
- `scripts/scaffold-rust-core.sh` — expanded the three leaf-crate blocks:
  - **gen_ui_ffi** (frb 2.12): `src/api.rs` (init + submodules) + `src/api/{streams,entity,chat}.rs`.
    `init_core` wires the global Tokio runtime + Android logger. `entity`/`chat` are
    the EntityTransport CRUD + chat/`memory_search`/`graph_expand` intents. `streams`
    exposes `StreamSink<A2uiEvent|ChangeEvent|SyncStatus>` (chat / entity-invalidation
    / sync-chip feeds), gated behind a `frb-streams` feature since `StreamSink<T>` is
    codegen-emitted. Added `flutter_rust_bridge.yaml` (frb codegen config) + `.gitignore`
    (frb_generated.rs, wasm pkg/) at the workspace root.
  - **tauri-plugin-gen-ui** (Tauri 2): `src/lib.rs` (`init()` Builder + `.setup()` runtime
    init + event-channel constants), `src/commands.rs` (same intent surface as
    `#[tauri::command]`), `src/error.rs` (serializable, maps CoreError), `build.rs`
    (`tauri_plugin::Builder` COMMANDS list), `permissions/{default,write}.toml`, and
    `package.links` (required by tauri-plugin's build script — injected via awk).
  - **gen_ui_wasm** (wasm-bindgen): `src/lib.rs` `WasmA2uiAdapter` wrapping the shared
    `gen_ui_protocol::A2uiAdapter` (browser folds StreamEvent→A2uiEvent with the SAME
    Rust logic as native) + `console_error_panic_hook`; `build-wasm.sh` (wasm-pack
    bundler + `wasm-opt -Oz`, `wasm-release` profile).
  - `bacon.toml` clippy job changed from `--all-features` to default features (+ new
    `clippy-frb` job) so the pre-codegen inner loop isn't broken by the codegen-only
    `frb-streams` feature.
- `scripts/scaffold-hybrid.sh` — calls `scaffold-packages.sh` after the surfaces; updated
  root README structure + `.gitignore` for the new package dirs.

## Files created
- `scripts/scaffold-packages.sh` — emits 5 publishable skeletons:
  - `@prometheus-ags/gen-ui-react` (npm) — `ContentBlock` union (mirrors Rust serde
    shape) + `ContentBlockView` **exhaustive** JSX switch (11 variants, `assertNever`).
  - `@prometheus-ags/gen-ui-wasm` (npm) — wrapper re-exporting the wasm-pack `pkg/` output.
  - `@prometheus-ags/tauri-plugin-gen-ui` guest-js (npm) — typed `invoke()` wrappers +
    `listen()` helpers; layer contract note (stores-only).
  - `gen_ui_flutter` (pub.dev) — FFI plugin pubspec (ffiPlugin android/ios/macos) + re-export shim.
  - `gen_ui_widgets` (pub.dev) — `ContentBlock` sealed hierarchy + `ContentBlockView`
    **exhaustive** Dart `switch` (no default branch → missing variant is a compile error).
- `openspec/changes/2026-07-15-c007-ffi-leaves-packaging/tasks.md`.

## VERIFIED (gate — all clean)
- `cargo metadata` OK (12 crates); **full-workspace `cargo clippy --workspace --all-targets -D warnings` CLEAN** (rustc 1.93.1).
- Cross-target: `gen_ui_wasm` checks on **wasm32-unknown-unknown**; `gen_ui_ffi` checks on **aarch64-apple-ios**.
- `tauri-plugin-gen-ui` builds through its tauri 2 `build.rs` + permission autogen.
- `@prometheus-ags/gen-ui-react`: `tsc --noEmit` clean against real React 19 types;
  **negative test** confirmed the exhaustive guard (dropping a case → TS2345 not-assignable-to-never).
- guest-js: `tsc --noEmit` clean against real `@tauri-apps/api` v2.
- `gen_ui_flutter` + `gen_ui_widgets`: `dart analyze` **No issues found**.
- All generated files carry `// TJ-ARCH-MOB-001 compliant` (line 2 for the shebang'd `build-wasm.sh`).

## DEVIATIONS / notes
1. **`frb-streams` feature gate.** frb 2.12's `StreamSink<T>` is a per-crate type emitted
   by `flutter_rust_bridge_codegen generate` into `frb_generated.rs`, so the streams
   module cannot `cargo check` before codegen runs. Gated behind a default-off feature
   (enabled by the project build post-codegen); the non-stream surface checks clean
   standalone. Also added a crate-level `[lints.rust] unexpected_cfgs` allow for
   `cfg(frb_expand)` (a benign codegen-only cfg the `#[frb]` macro references) so the
   pre-codegen build is warning-clean under `-D warnings`.
2. **`bacon.toml` edited** (C-001 config, not a `gen_ui_types` trait seam): its `--all-features`
   clippy job would have force-enabled `frb-streams` and broken the fresh-scaffold inner
   loop. Switched to default features + added a post-codegen `clippy-frb` job. Backward-compatible.
3. **`package.links`** must equal the plugin crate name for Tauri 2 plugins (build script
   requirement) — injected into the emitted manifest via awk since `emit_crate` fixes the
   `[package]` block shape.
4. Did NOT touch `audit.sh` (its layer-contract extension is C-012's scope) or
   `gen_ui_types` seams (frozen). Scope held to C-007.
