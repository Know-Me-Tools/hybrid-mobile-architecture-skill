### 2026-07-15 — kbd-analyze (bootstrap pillars) verdicts
- ADOPT: prometheus-skill-system (public; full install flow documented; verify via pk doctor
  + mcp-health + required binaries), @fission-ai/openspec 1.6.0 (bare 'openspec' npm is
  squatted — scoped name mandatory; channel-aware upgrade), Flutter beta 3.47.0 (releases-JSON
  currency check; dart mcp-server gate; our install-flutter.sh must be fixed — shallow stable
  clone), node@24 pinned (NOT --lts) + bun + pnpm + typescript@latest.
- USER REVISION: TypeScript pillar 6.0+ → 7.0.2 (latest). Scaffold pins updated ^5.x→^7.0.0
  (stale pins = live Rule-22 violation in our own generators, fixed).
- USER DIRECTIVE: 40 Prometheus Base Rules → canonical AGENT_BASE_RULES.md, wired into
  CLAUDE/AGENTS/dispatch-preamble/scaffold-emission/skill-templates. Provenance: user.
- BUILD (extend own): check-env.sh → 4-pillar bootstrap with operational gates; 7-item delta.
- Open: remediation aggressiveness default (recommend check-only default, --install, --full
  for long ops); skill-system clone location; staleness warn-vs-fail (recommend warn).

### 2026-07-15 — Inference architecture revision (user-directed, post-C-102)
- USER DIRECTIVE: replace bespoke Anthropic SSE with **liter-llm gateway**
  (git@github.com:GQAdonis/liter-llm.git fork — 142+ providers, streaming, tool calling;
  crates verified: liter-llm core with native-http feature, liter-llm-ffi, liter-llm-wasm
  → one dependency covers desktop/mobile/web). Requires a **config DB** for provider/model
  settings + administration: pglite-oxide (Tauri/mobile, Rust core) + PGlite (web).
  Folded into C-103 (schema+gateway) and C-109 (admin UI). Provenance: user.
- USER DIRECTIVE: local model inference + download via **mistral.rs fork**
  (git@github.com:GQAdonis/mistral.rs.git — mistralrs library crate: HF download,
  GGUF/ISQ load, Metal/CPU, candle-based; crates verified). Replaces candle-direct in
  C-105 native + C-109 mobile. Fork extras (audio/vision/mcp crates) noted, out of scope.
- RESEARCH (firecrawl, 2026-07): web local-model lane → **WebLLM (MLC)** on WebGPU —
  consensus in-browser chat engine (OpenAI-compatible streaming, curated MLC models incl.
  Qwen2.5-1.5B-Instruct-q4f16_1 matching the native model family, browser-cached).
  wllama (llama.cpp WASM) rejected as primary (CPU speeds don't demo well);
  transformers.js reserved for embeddings/whisper-class web tasks. Documented exception
  to the Rust-core invariant: TS adapter in the web surface behind the same intent seam.
  Sources: webllm.mlc.ai; lofttools.com/blog/browser-llms-2026-webllm-transformers-js;
  localmode.dev/blog/compare/webllm-vs-wllama.
- Memory plan (C-104) explicitly unchanged ("memory is good"). Cargo git deps pinned to
  SHAs at C-103/C-105 implementation time (Rule 22/23).

### 2026-07-16 — C-103 T6-T11: chat live end-to-end, pinned SHAs, tooling defects found

**Pinned dependency SHA (Rule 22/23 provenance)**
- `liter-llm` — `git = "https://github.com/GQAdonis/liter-llm.git"`,
  `rev = "78b7496ca7b09a1aa6c3c666af0a149bbdf5249f"` (crate version `1.9.3` at that
  commit). Used with `native-http` feature on all native targets (desktop Tauri, mobile
  FFI); `wasm-http` reserved for the `gen_ui_wasm` web leaf (unused by gen_ui_agent).

**T6/T7 — gen_ui_agent::ChatAgent (chat orchestration + streaming)**
- `chat_send`/`chat_events` intent functions no longer use the `gen_ui_types::CoreResult<T>`
  type alias directly in their signatures — **flutter_rust_bridge 2.12.0 does not resolve
  type aliases used as a function's return type**, silently generating an opaque, fieldless
  `RustOpaqueInterface` Dart handle instead of a throwing `Future<T>` (confirmed empirically:
  a spelled-out `Result<String, String>` return generates correctly; the identical
  `CoreResult<String>` alias does not). Fixed by spelling out `Result<T, CoreError>` at the
  FFI-facing boundary only; `gen_ui_agent`'s internal API keeps using `CoreResult<T>`.
- `A2uiEvent`/`ContentBlock` (Rust enums with data-carrying variants) cross the FFI wire as
  JSON `String`s (`chat_events` returns `Stream<String>`, decoded via new
  `A2uiEvent.fromWire`/`ContentBlock.fromWire` Dart factories) rather than native frb type
  mirroring. Root cause: frb classifies any enum with data-carrying variants as needing
  `freezed` Dart codegen, but this project's `riverpod_generator` (all published versions
  3.0.0–4.0.4) and any stable `freezed` release have **disjoint `analyzer` version
  requirements** — no published version combination resolves — and freezed's prerelease
  line that *would* resolve is separately rejected by frb's own `>=1.0.0` semver gate
  (excludes prereleases). This is an external ecosystem conflict, not fixable within this
  project as pinned; revisit if `freezed` publishes a stable release compatible with
  `analyzer >=11`, or if `riverpod_generator` relaxes its `analyzer` bound.
- Known gap, documented not silently fixed: `chat_send` returns a run_id and the caller
  makes a separate `chat_events`/`chat_subscribe` call to attach a listener — a very fast
  response/error can complete and deregister before that second call attaches. Mitigated
  (subscribe immediately after send resolves, no intervening await) but not fully closed on
  either platform, since `chat_send` must complete before the run_id to subscribe with is
  known.

**T10 — first live provider round-trip**
- No provider API key was available this session; used Ollama (`ollama/<model>` model-hint
  + empty API key, liter-llm's own supported local-provider pattern — see the vendored
  crate's `tests/local_llm.rs`) instead of a cloud provider. `deepseek-v4-flash:cloud`
  failed with an Ollama Cloud subscription-tier error (round-tripped correctly as a
  streamed `RunError`, proving the error path); `llama3.2:1b` (free, local, pulled via
  `ollama pull`) succeeded — full `RunStarted → Block{Text} → RunFinished` sequence,
  response `"Hello."` for a one-word-greeting prompt. Proven via
  `crates/gen_ui_agent/tests/ollama_live.rs` (ignored by default; real integration test,
  not a mock) rather than driving the Tauri GUI directly (no visual access to a native
  macOS window from this session) — `pnpm tauri dev` was confirmed to compile and launch
  cleanly with the dev Ollama wiring active, but a human running it and typing into the
  chat box is the only way to see the full windowed round-trip.

**T11 — first iOS Simulator run: real defects found and fixed**
- The iOS Xcode project had **zero wiring to any Rust build** before this — no podspec, no
  build phase referenced `gen_ui_ffi` anywhere. Ran
  `flutter_rust_bridge_codegen integrate --rust-crate-name gen_ui_ffi --rust-crate-dir
  ../rust/crates/gen_ui_ffi` to generate the missing `mobile/rust_builder/` (cargokit +
  platform podspecs) — the correct frb-native integration (an Xcode script phase builds
  the Rust crate automatically), which supersedes `scripts/ios/build-xcframework.sh`'s
  manual-XCFramework approach (that script's crate name was also stale —
  `gen_ui_core` from the original architecture doc vs. this PoC's actual `gen_ui_ffi` —
  fixed regardless, kept as a documented manual-build fallback).
- `flutter_packages/gen_ui_flutter` declared `ffiPlugin: true` for ios/android/macos with
  zero native build glue ever scaffolded (no podspec, no build.gradle) and is unused dead
  code (nothing under `mobile/lib` imports it) — this alone broke `pod install` outright.
  Fixed its `pubspec.yaml` to plain Dart-only rather than deleting the package.
- **freezed 3.0 breaking change** (confirmed via freezed's own CHANGELOG.md): classes
  annotated `@freezed` must now be declared `abstract class` or `sealed class`, not a plain
  `class`. `flutter_packages/prometheus_entity_management`'s `view.dart`/`entity.dart` still
  used the pre-3.0 syntax for `FilterSpec`/`SortSpec`/`ViewDescriptor`/`EntityRecord`/
  `ListResult` (`ChangeEvent` already correctly used `sealed class`) — a real, reproducible
  Xcode kernel-snapshot build failure (confirmed not a stale-cache artifact via a
  `flutter clean` rebuild that failed identically before the fix). Fixed by adding
  `abstract` to all five.
- After all four fixes: **the app compiled and launched live on iOS Simulator for the
  first time in this PoC's history** (Xcode build 24.4s once the Rust binary was cached,
  Dart VM Service attached, screenshot captured). It then hit a separate, pre-existing
  bug on boot: `main.dart`'s `StartupNotifier` unconditionally awaits `runMigrations()` →
  `loadSeeds()` → `attachSyncShapes()` before showing any UI, and all three remain literal
  `UnimplementedError` stubs in `rust_bridge_provider.dart` — **no Rust-side mobile
  startup orchestrator (migrations/seeds/sync-shape-attach over FFI) was ever
  implemented**. T3 built this for desktop only (pglite-oxide +
  `Startup<Uninitialized/Migrated/Ready>` in `gen_ui_db`); the equivalent mobile-facing
  `gen_ui_ffi` intent functions do not exist. This blocks the entire mobile app, not just
  chat — reported as a finding, deliberately NOT fixed under C-103 (a real T3/T4-class
  scope, not chat-live-e2e's goal). **Recommended next KBD change**: implement the mobile
  startup orchestrator (SurrealDB via `gen_ui_db_graph`, matching desktop's typestate
  pattern) so the app's main UI — including this phase's chat work — is reachable on
  mobile at all.
