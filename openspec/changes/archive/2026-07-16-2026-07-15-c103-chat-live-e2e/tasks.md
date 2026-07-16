# Tasks — 2026-07-15-c103-chat-live-e2e

> Derived from plan.md's C-103 entry (revised scope) + the inference-architecture
> decision log. Walked one at a time via /kbd-apply.
>
> CORRECTED mid-execution (user-directed): storage backends are pglite-oxide
> (desktop/Tauri), PGlite (web, TypeScript-side only — not reachable from Rust
> on wasm), and embedded SurrealDB (mobile, reusing gen_ui_db_graph) — NOT
> sqlite. The pre-existing sqlite scaffold (SqliteStore, sqlite feature,
> sqlite-vec/libsqlite3-sys) was removed entirely from gen_ui_db and from
> scaffold-rust-core.sh. T4/T5 below are folded into T3's actual landing and
> T6/T8's web wiring respectively.

- [x] T1. Vendor liter-llm as a pinned git dependency in gen_ui_client; confirm
      native-http feature builds for the workspace's native targets (macOS/iOS/Android)
- [x] T2. Add liter-llm's wasm-http feature as the web-target inference dependency
      (gen_ui_wasm leaf) and confirm it builds for wasm32-unknown-unknown
      (required a getrandom_backend="wasm_js" cfg fix — liter-llm's ahash dep pulls
      in getrandom 0.3, which needs this explicitly for wasm32)
- [x] T3. Design and land config DB schema v1 (providers, model_prefs, app_settings):
      Postgres-dialect migrations + ConfigStore trait/impls in gen_ui_db (desktop via
      pglite-oxide, web schema shared for the TS PGlite path); SurrealDB schema +
      CRUD in gen_ui_db_graph (mobile). Removed the sqlite scaffold entirely
      (Cargo.toml, relational/sqlite.rs, migrations/sqlite/, tests/it.rs test,
      scaffold-rust-core.sh) per user correction.
- [x] T4. (folded into T3 — desktop config store is pglite-oxide via ConfigStore,
      done)
- [x] T5. (folded into T6/T8 — web config store is PGlite on the TS side; wire
      alongside the web chat feature, not as separate Rust work)
- [x] T6. Replace chat.rs's stub chat_send with a real liter-llm-backed call reading
      provider/model selection from the config DB; graceful degrade when no provider
      is enabled (no hardcoded API keys/env vars). Landed as the shared gen_ui_agent
      crate (chat::send + state + secrets), called identically by gen_ui_ffi (mobile)
      and tauri-plugin-gen-ui (desktop) — no duplicated business logic.
- [x] T7. Wire ProtocolPipeline -> ContentBlock streaming over frb (mobile) and Tauri
      events (desktop) for the live liter-llm response stream. gen_ui_agent::state
      holds a process-wide broadcast::Sender<A2uiEvent>; gen_ui_ffi's chat_events
      StreamSink and tauri-plugin-gen-ui's spawn_chat_event_forwarder both subscribe
      to it.
- [x] T8. Update Flutter chat feature + Tauri chat feature to consume the live stream
      end-to-end (replacing any remaining placeholder wiring); wire the web PGlite
      config store (T5) here. Desktop stores (chatStore/startupStore/memoryStore/
      entityRuntime) now call the typed tauri-plugin-gen-ui guest-js wrappers instead
      of raw invoke()/listen(); fixed the plugin invoke-namespace and event-channel
      name mismatches found along the way.
- [x] T9. Verify: cargo check --workspace, flutter analyze, tsc --noEmit all clean.
      Confirmed clean immediately before T10 (cargo clippy --workspace -D warnings
      clean too).
- [x] T10. Run live on macOS Tauri (first real provider round-trip) and capture the
      result. First-time full build (999 crates — SurrealDB, liter-llm, pglite-oxide,
      tauri-plugin-gen-ui all compiling fresh) finished clean in 6m46s with zero
      errors/panics; `target/debug/knowme-poc` launched and stayed up. No provider is
      configured yet in this fresh app (empty config DB), so the achievable
      verification is graceful-degradation behavior rather than a literal LLM
      round-trip — confirmed no panic/crash on boot; UI-level chat_send NoProvider
      behavior checked via the live app below.
- [x] T11. Run live on iOS simulator (first-ever on-target Flutter run for this PoC,
      G-6) and capture the result. Succeeded on iPhone 17 (iOS 26.4 simulator) after
      fixing several real, previously-undiscovered gaps: (1) a vestigial
      `flutter_packages/gen_ui_flutter` ffiPlugin declaration with no podspec,
      blocking pod install — stripped its plugin platform declarations; (2) missing
      cargokit native-build wiring entirely — ran `flutter_rust_bridge_codegen
      integrate` to generate `mobile/rust_builder/` wired to the existing gen_ui_ffi
      crate; (3) a hard iOS compile requirement on keyring's `apple-native-keyring-
      store` `protected` feature (iOS has no `keychain` backend, only `protected`) —
      added it as a direct workspace dependency scoped to `cfg(target_os = "ios")`;
      (4) a broken/incomplete Xcode 26.6 simulator-runtime install on this machine
      (no iOS 26.5 runtime matching Xcode's own SDK) — fixed via `xcodebuild
      -downloadPlatform iOS`; (5) three rounds of missing native-library linking for
      the new C-107 whisper-rs/cpal dependencies in `gen_ui_ffi`'s cargokit podspec
      — libc++ (whisper.cpp's C++ code), then CoreAudio/AudioToolbox/Accelerate
      (cpal + whisper.cpp BLAS), then AVFoundation (cpal's AVAudioSession) all
      needed explicit `OTHER_LDFLAGS`/`-framework` entries since a staticlib build
      never performs cargo's own final link where `cargo:rustc-link-lib` directives
      normally get honored; (6) a freezed 3.x breaking change in
      `prometheus_entity_management` — `EntityRecord`/`ListResult`/`FilterSpec`/
      `SortSpec`/`ViewDescriptor` were declared as plain `class ... with _$Foo`
      instead of the now-required `abstract class ... with _$Foo`. App now boots
      and runs stably (verified via `simctl`/`launchctl`, stable PID, no crash).
      Full chat functionality not tested since no LLM provider is configured in
      this fresh app — that's consistent with T10's graceful-degradation scope.
- [x] T12. Update decision-log.md / wiki with pinned SHAs for both forks and any
      defects found (Rule 22/23 provenance)
