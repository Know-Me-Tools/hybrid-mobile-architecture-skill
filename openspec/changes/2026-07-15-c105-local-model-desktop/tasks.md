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
- [ ] T9 — `tauri-plugin-gen-ui`: depend on `gen_ui_inference`
      (`features = ["local-mistral"]`), add local-inference commands + permissions.
- [ ] T10 — `gen_ui_agent` lane selection: local slots in behind the existing
      `get_model_pref(surface, lane)` lookup alongside `LANE_CLOUD`, reusing
      `run_stream`'s A2UI adaptation rather than duplicating it.
- [ ] T11 — Desktop cloud↔local toggle in the chat store + tok/s display.
- [ ] T12 — End-to-end smoke test: real model load + generation on desktop Tauri,
      and the WebLLM lane in a browser. Confirm mistral.rs's internal
      spawn_blocking behaviour empirically (design.md flags it as unverified).
