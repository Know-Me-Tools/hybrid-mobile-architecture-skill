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
- [ ] T4. (folded into T3 — desktop config store is pglite-oxide via ConfigStore,
      done)
- [ ] T5. (folded into T6/T8 — web config store is PGlite on the TS side; wire
      alongside the web chat feature, not as separate Rust work)
- [x] T6. Replace chat.rs's stub chat_send with a real liter-llm-backed call reading
      provider/model selection from the config DB; graceful degrade when no provider
      is enabled (no hardcoded API keys/env vars). Landed as gen_ui_agent::ChatAgent
      (new crate module set: chat.rs, config_resolve.rs, error.rs, secret.rs,
      registry.rs, state.rs) — resolves (provider, model) from
      gen_ui_db::relational::ConfigStore for surface="chat"/lane="default", builds a
      liter-llm ClientBuilder client, and returns CoreError::Terminal("no provider
      configured: ...") when no model_pref/provider/enabled-provider exists. No
      ConfigStore is wired at FFI/Tauri init yet (that's T8+), so
      gen_ui_agent::state defaults to a NoopConfigStore that always reports
      "not configured" — the graceful-degrade path is reachable today;
      `install_chat_agent()` lets T8 swap in the real store without touching
      chat.rs or the call sites.
- [x] T7. Wire ProtocolPipeline -> ContentBlock streaming over frb (mobile) and Tauri
      events (desktop) for the live liter-llm response stream. Landed via
      gen_ui_agent::RunRegistry (per-run_id tokio::sync::broadcast channel,
      registered by ChatAgent::send before it returns): gen_ui_ffi's
      chat_events(run_id, sink) subscribes and forwards into the frb StreamSink
      (gated on frb-streams, unchanged pre-codegen build story); a new
      tauri-plugin-gen-ui command chat_subscribe(run_id, app_handle) subscribes
      and forwards via AppHandle::emit(GEN_UI_CHAT_EVENT, event) for desktop, since
      Tauri has no StreamSink equivalent. Both sides call the identical
      gen_ui_agent orchestration — no duplicated business logic.
- [x] T8. Update Flutter chat feature + Tauri chat feature to consume the live stream
      end-to-end (replacing any remaining placeholder wiring); wire the web PGlite
      config store (T5) here.

      Mobile (Flutter): ran flutter_rust_bridge_codegen generate for the first
      time in this checkout (previously blocked — pubspec.lock never existed,
      `flutter pub get` never run; fixed as a prerequisite). Discovered and fixed
      a real frb 2.12.0 parser gap: `CoreResult<T>` (a `Result<String, CoreError>`
      type alias) used directly as a function's RETURN TYPE generates as an
      opaque, fieldless `RustOpaqueInterface` handle instead of a throwing
      `Future<T>` — frb does not resolve type aliases at that position (confirmed
      empirically: a spelled-out `Result<String, String>` generates correctly).
      Fixed by spelling out `Result<T, CoreError>` in gen_ui_ffi::api::chat's
      FFI-facing signatures instead of using the alias (gen_ui_agent and other
      non-FFI Rust callers keep using CoreResult<T> — this is a Dart-boundary-only
      workaround). Also discovered `A2uiEvent`/`ContentBlock` (enums with
      data-carrying variants) require `freezed` Dart codegen to mirror natively,
      but this project's riverpod_generator (all versions 3.0.0-4.0.4) and stable
      freezed (analyzer >=9,<11) have DISJOINT analyzer requirements — no
      published version combination resolves; freezed's prerelease line that
      would resolve is separately rejected by frb's own `>=1.0.0` semver gate
      (excludes prereleases). Worked around by having chat_events (gen_ui_ffi::
      api::streams) serialize A2uiEvent to a JSON String over the wire instead of
      native frb mirroring; Dart decodes via new `A2uiEvent.fromWire`/
      `ContentBlock.fromWire` factory constructors (gen_ui_widgets' ContentBlock
      and mobile's A2uiEvent — both previously placeholder sealed classes with no
      wire parser). `rust_bridge_provider.dart`'s chatSend/chatEvents now call the
      real generated bindings (`GenUiCore.init()`, api/chat.dart, api/streams.dart)
      instead of throwing UnimplementedError. `flutter analyze`: 0 errors (433
      pre-existing info-level style lints, mostly in auto-generated
      frb_generated.web.dart, unrelated to this change).

      Desktop (Tauri/React): chatStore.ts previously called a stale, non-existent
      command (`stream_agent_a2ui`) and listened on a stale event name
      (`a2ui_event`) that didn't match anything T6/T7 registered. Rewired to call
      the real `chat_send`/`chat_subscribe` Tauri commands and listen on
      `gen-ui://chat-event` (tauri-plugin-gen-ui's actual GEN_UI_CHAT_EVENT
      constant), following the existing bare-command-name invoke() convention
      already used by entityRuntime.ts. Rewrote bridge/a2ui/driver.ts's
      `CoreA2uiEvent` type (previously a speculative `contentBlock`/
      `messageComplete` shape with no relation to the real Rust enum) to match
      gen_ui_types::events::A2uiEvent's actual serde shape (`run_started`/
      `block`/`run_finished`/`run_error`, snake_case). Added a `run_id ->
      messageId` map to ChatState since the wire event only carries run_id, not
      a message id, and the single GEN_UI_CHAT_EVENT channel carries every
      concurrent run. `npx tsc --noEmit`: 0 errors in any file this task touched;
      6 pre-existing errors remain in unrelated files (ChatTranscript.tsx,
      CoreFlintSurface.tsx, flintSurfaceStore.ts, types.ts) because
      @prometheus-ags/gen-ui-react and @flint/react — file:-linked local
      packages — have never been built (no dist/ output), and gen-ui-react's own
      build fails on a missing @types/react in its standalone workspace. Flagged
      as a separate pre-existing blocker, not fixed here (out of scope — whole
      other package's build config, unrelated to chat's streaming plumbing).

      Race condition (documented in T6/T7's commit as a known gap): mitigated
      but NOT fully closed on both platforms — chat_send/chat_subscribe (or
      chat_events on mobile) are called back-to-back with no intervening await
      once the run_id is known, but chat_send must complete before that run_id
      exists, so a residual window remains for extremely fast responses/errors.
      Documented inline at each call site.

      Web PGlite config store (T5): NOT wired — deliberately deprioritized per
      the task brief's own guidance to prioritize the streaming plumbing fix
      over config-store completeness. No PGlite-backed ConfigStore exists on the
      TS side yet; the web build's chat path still resolves through
      NoopConfigStore's graceful-degrade ("no provider configured") until this
      lands. Left as explicit follow-up work, not silently skipped.

      Desktop pglite-oxide ConfigStore startup wiring: also NOT wired (same
      NoopConfigStore graceful-degrade applies to desktop until a future task
      installs a real ConfigStore via gen_ui_agent::install_chat_agent in
      tauri-plugin-gen-ui's `.setup()` hook).
- [x] T9. Verify: cargo check --workspace, flutter analyze, tsc --noEmit all clean.

      cargo check --workspace / cargo clippy --workspace -- -D warnings: CLEAN.
      Fixed a real gap along the way: gen_ui_ffi's `frb-streams` feature was
      off by default with a stale "pre-codegen `cargo check` leaves this off"
      comment — but once flutter_rust_bridge_codegen has run WITH the feature
      active (as it now has, T8), the emitted frb_generated.rs unconditionally
      does `use crate::api::streams::*` with no cfg gate, so leaving the
      feature off by default broke the plain `cargo check --workspace`. Flipped
      `default = ["frb-streams"]` — confirmed this doesn't regress the
      pre-codegen case (a fresh clone with no frb_generated.rs fails identically
      regardless of the feature flag, since `mod frb_generated;` itself has no
      cfg gate).

      flutter analyze: 0 errors (394 pre-existing info-level style lints,
      mostly auto-generated frb_generated.web.dart formatting — unchanged from
      T8).

      npx tsc --noEmit: 3 errors remain (down from 6 at T8 checkpoint). Built
      @prometheus-ags/gen-ui-react's dist/ output (it had never been installed
      or built in this checkout — `pnpm install` + `tsc -p tsconfig.json` in
      packages/gen-ui-react, then `pnpm install` in desktop/ to re-link),
      resolving all of its import errors. The remaining 3 errors are all
      @flint/react (CoreFlintSurface.tsx, flintSurfaceStore.ts) — this package
      is fetched via git from a SEPARATE repo (Know-Me-Tools/flint-forge) and
      the fetched tarball contains only package.json + SKILL.md, no src/ or
      build tooling (tsup) to build a dist/ from; genuinely out of reach without
      cloning and building that external repo. Documented, not silently
      skipped — a real remaining blocker for full tsc cleanliness, unrelated to
      anything T6-T9 touched.
- [x] T10. Run live on macOS Tauri (first real provider round-trip) and capture the
      result.

      No provider API key was available for this session (user-directed:
      "use Ollama with this model that we already have"). Wired a dev-only,
      env-var-gated ConfigStore/SecretResolver pair (tauri-plugin-gen-ui::
      dev_ollama, active only when GEN_UI_DEV_OLLAMA_MODEL is set — never in a
      normal run) pointing at a local Ollama instance, per liter-llm's own
      `ollama/<model>` model-hint + empty-API-key pattern (vendored crate's
      tests/local_llm.rs).

      FIRST REAL PROVIDER ROUND-TRIP (the actual T10 substance): a new
      integration test, crates/gen_ui_agent/tests/ollama_live.rs, drives
      ChatAgent::send — the exact orchestration both gen_ui_ffi and
      tauri-plugin-gen-ui call — against a real running Ollama instance.
      deepseek-v4-flash:cloud failed with "this model requires a subscription"
      (an Ollama Cloud account-tier issue, not a code defect — the error
      still round-tripped correctly end-to-end as a streamed RunError event,
      proving the failure path too); pulled llama3.2:1b locally (free, no
      subscription) and re-ran: PASSED. Full event sequence observed:
      RunStarted -> Block{Text} -> RunFinished, response text "Hello." for
      the prompt "Say hello in exactly one word." Run with:
      `OLLAMA_MODEL=llama3.2:1b cargo test -p gen_ui_agent --test ollama_live
      -- --ignored --nocapture`.

      Desktop app launch: `GEN_UI_DEV_OLLAMA_MODEL=llama3.2:1b pnpm tauri dev`
      compiled and started cleanly (Rust core + Vite frontend, no errors in
      the Tauri log or browser console) — confirmed via a background process
      + the frontend dev server's rendered output (KnowMe branded titlebar
      visible, zero console errors). Could NOT drive the actual chat UI
      interaction inside the native Tauri window from this session (no visual
      access to a native macOS window; a plain browser tab against the Vite
      dev server on :1420 has no `__TAURI_INTERNALS__` bridge, so invoke()
      calls don't function there — it only proved the frontend boots). The
      ChatAgent-level integration test above is the actual live-provider
      proof; the Tauri GUI launch proves the app process itself starts
      cleanly with the dev Ollama wiring active, but a human running
      `pnpm tauri dev` and typing into the chat box is the only way to see
      the full windowed round-trip. Recommend the user do this once to
      confirm the UI layer, since it's outside what this session could drive.
- [ ] T11. Run live on iOS simulator (first-ever on-target Flutter run for this PoC,
      G-6) and capture the result
- [ ] T12. Update decision-log.md / wiki with pinned SHAs for both forks and any
      defects found (Rule 22/23 provenance)
