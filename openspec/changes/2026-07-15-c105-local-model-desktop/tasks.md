# Tasks — 2026-07-15-c105-local-model-desktop

> Two lanes behind one intent seam (`gen_ui_types::inference::InferenceProvider`,
> frozen at C-001): mistral.rs native on desktop, WebLLM on web. See design.md for
> the verified API contracts, the two dependency conflicts resolved, and the
> corrections the compiler forced on the initial API research.

- [x] T1 — Research + pin: mistral.rs fork API verified against the source at the
      pinned rev (crate layout, GgufModelBuilder, streaming, error taxonomy, MSRV
      1.88 vs our 1.95 floor). `mistralrs` pinned by SHA
      `b7746a85cb2e78fb2cf11cfb6ea9abd0a167d1f3` (Rule 22).
- [x] T2 — WebLLM research: `@mlc-ai/web-llm` 0.2.84, OpenAI-compatible streaming,
      `navigator.gpu` gate, Cache API weights. Model id
      `Qwen2.5-1.5B-Instruct-q4f16_1-MLC` verified present in the prebuilt catalog.
- [x] T3 — **regex conflict resolved**: mistral.rs (via serde-saphyr) needs
      `regex <1.13`; lock held 1.13.1 via liter-llm's loose `^1`. Pinned 1.12.4 —
      satisfies both lanes, cloud lane verified unaffected.
- [x] T4 — **safetensors/candle conflict resolved**: the fork's own crates don't
      compile (candle#main moved to safetensors 0.8, mistral.rs expects 0.7 →
      E0308 on `Dtype`). `[patch]`ed candle to upstream rev `5404348` per the
      fork's own documented fallback. Also removes a floating branch from our graph.
- [x] T5 — `MistralEngine` implementing `InferenceProvider` (load/generate/unload).
      Qwen2.5-1.5B-Instruct Q4_K_M; chat template auto-fetched from the tokenizer
      repo; errors classified into CoreError transient/terminal (message-based —
      mistral.rs exposes no structured OOM variant).
- [x] T6 — Target-gating: `mistralrs` verified absent from wasm32 and iOS graphs
      even with `--features local-mistral` forced on, and from desktop's default
      graph. Clippy clean per-crate and workspace-wide.
- [x] T7 — **Cargo.lock committed**: narrowed the blanket `*.lock` ignore that was
      silently dropping it. It is the only pin holding mistral.rs's floating
      `turboquant-rs#main` to a reviewed SHA, and it carries the regex resolution.
- [x] T8 — WebLLM web lane (`features/chat/api/webllmLane.ts`): emits the same
      `CoreA2uiEvent`s as the Tauri path so the store stays lane-agnostic;
      `navigator.gpu` gate with visible cloud degrade; dynamic import; idempotent
      load that does not cache failures. `tsc --noEmit` clean.
- [x] T9 — `tauri-plugin-gen-ui`: depends on `gen_ui_inference`
      (`features = ["local-mistral"]`); constructs `MistralEngine` in
      `run_migrations` and hands it to `state::init_with_inference`. Added
      get/set_active_lane + has_local_engine commands, registered in build.rs's
      COMMANDS (permissions autogenerate from it) and the default permission set.
- [x] T10 — `gen_ui_agent` lane selection: `chat::send` reads the `active_lane`
      app setting (unset → cloud, so existing installs are unchanged) and routes
      to `send_local`, which resolves the `chat`/`local` model_pref and drives the
      `InferenceProvider` trait object. Local `load()` runs before `send` returns
      the run_id — a first-run download is minutes long, and reporting "started"
      before the model exists would leave the UI streaming nothing.
      Selecting `local` with no engine is `NoLocalEngine`, never a silent cloud
      fallback. `ModelPref` gained `params` (both storage engines already carried
      it) for temperature/top_p/max_tokens/context_len with per-key fallbacks.
- [x] T11 — LaneSwitcher + laneStore/useLane: toggle hidden entirely when no
      local lane exists; download progress; tok/s on local runs only (on cloud it
      would measure the network and the provider's load, not this machine);
      failed switches surface the error rather than silently reverting.
- [x] T11b — **Fixed a pre-existing desktop A2UI bug found while wiring tok/s**:
      the plugin emits `A2uiEvent` verbatim (`{"type":"block"}` /
      `{"type":"run_finished"}`), but `driver.ts` switched on
      `contentBlock`/`messageComplete` — matching neither, so the desktop lane
      rendered nothing and had not since C-103. An `as never` cast at the call
      site hid it from tsc. Added `createA2uiWireAdapter` (maps the real wire
      shape; binds run-scoped events to the store's message id; accumulates
      per-token deltas into one growing block, matching the WebLLM lane) plus
      5 tests covering the contract that had gone unverified.
- [x] T12a — Live no-engine guard test: **passing**. `set_active_lane("local")`
      with no engine fails loudly instead of falling through to cloud.
- [ ] T12b — Live local-model test (`chat_send_streams_a_real_local_response`):
      real ~1GB GGUF download + Metal generation through the public `chat::send`
      path. `#[ignore]`d and feature-gated (`test-local-mistral`) following the
      `ollama_live.rs` precedent — the only honest verification, since the fork's
      own crates failed to build together until the candle patch and no
      type-check would have caught that.
- [ ] T12c — Verify the WebLLM lane in a real browser.
- [ ] T12d — Confirm mistral.rs's internal spawn_blocking behaviour empirically
      (design.md flags it as unverified).
