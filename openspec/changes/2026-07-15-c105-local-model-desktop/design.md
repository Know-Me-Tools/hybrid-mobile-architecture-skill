# Design — 2026-07-15-c105-local-model-desktop

> Research verified 2026-07-16. Rule 22 (verified dependency versions) — every pin
> below was confirmed against the live registry/remote, not assumed.

## Two lanes, one intent seam

Local inference is exposed through a single intent seam so the UI never branches on
platform. Native (desktop) fulfils it in Rust via mistral.rs; web fulfils it in
TypeScript via WebLLM. The web lane is a **documented exception** to the
"all inference in gen_ui_core" invariant (CLAUDE.md): WASM cannot drive Metal/CUDA,
and WebGPU is only reachable from JS. The TS adapter satisfies the same intent
contract, so the exception is contained to the transport, not the semantics.

## Web lane — WebLLM (verified 2026-07-16)

| Item | Verified value |
|---|---|
| Package | `@mlc-ai/web-llm` (Apache-2.0) |
| Version | 0.2.84 |
| Module | ESM → `lib/index.js`, types `lib/index.d.ts` |
| Model | `Qwen2.5-1.5B-Instruct-q4f16_1-MLC` |
| API | OpenAI chat-completions compatible (`engine.chat.completions.create`) |
| Streaming | `stream: true` → async generator, `chunk.choices[0]?.delta?.content` |
| WebGPU gate | `navigator.gpu` presence check before `CreateMLCEngine` |
| Weight cache | Cache API (default); IndexedDB / OPFS also selectable |
| First load | ~30–60s (network + cache write); subsequent loads sub-second |

Because the API is already OpenAI-compatible, the web lane needs **no shim** — it is a
drop-in against the same streaming shape the liter-llm cloud lane produces.

Degrade path: `navigator.gpu` absent → skip WebLLM entirely, fall through to the
liter-llm cloud lane with a visible (not silent) notice. Load the engine in a dedicated
Web Worker to keep model init off the main thread.

## Native lane — mistral.rs (GQAdonis fork), verified 2026-07-16

| Item | Verified value |
|---|---|
| Source | `https://github.com/GQAdonis/mistral.rs.git` |
| Pinned rev | `b7746a85cb2e78fb2cf11cfb6ea9abd0a167d1f3` (HEAD == refs/heads/master) |
| Crate | `mistralrs` (ergonomic SDK; workspace of 17 crates, v0.8.3) |
| MSRV | 1.88 — clears our 1.94/1.96 floor, no conflict |
| Edition | 2021 |
| macOS features | `["metal", "accelerate"]` |
| Model | Qwen2.5-1.5B-Instruct, GGUF Q4_K_M |

### API shape (from the fork's own `examples/getting_started/gguf` + `streaming`)

`GgufModelBuilder` covers download **and** load — no separate `hf-hub` call needed; it
pulls from HF Hub internally, or takes a local dir for offline use. The chat template is
fetched automatically from the tokenizer repo named by `.with_tok_model_id(...)`, so
Qwen2.5's template needs no hand-authoring (`.with_chat_template(path)` overrides).

```rust
let model = GgufModelBuilder::new("Qwen/Qwen2.5-1.5B-Instruct-GGUF",
                                  vec!["qwen2.5-1.5b-instruct-q4_k_m.gguf"])
    .with_tok_model_id("Qwen/Qwen2.5-1.5B-Instruct")
    .build().await?;
let mut stream = model.stream_chat_request(request).await?;
// yields Response::Chunk(ChatCompletionChunkResponse { choices, .. })
// → choices[0].delta.content — OpenAI-chunk-shaped, same as the cloud lane
```

`build()` / `stream_chat_request()` are already `async fn` and the crate drives its own
internal threading, so wrapping the *stream* in `spawn_blocking` would be wrong. Model
**load** is long-running I/O+compute and is the piece to isolate from latency-sensitive
paths. NOTE: no source evidence was found confirming mistral.rs's internal
`spawn_blocking` behaviour — treat as unverified and confirm empirically once building.

### Errors

`mistralrs::error::Error` — `thiserror`, `#[non_exhaustive]`: `ModelLoad` (boxed dyn —
covers network failure, corrupt GGUF, bad model ID), `Inference`, `RequestValidation`,
`ModelError { message, partial_response }` (recoverable partial output), `Channel`,
`Management`, `Json`, `UnexpectedResponse`. **There is no out-of-VRAM variant** — OOM
surfaces as `ModelLoad`/`Inference` wrapping a candle/Metal alloc error, so distinguishing
it needs `downcast_ref` (string-matching as last resort).

### RISK — floating branch dependencies (Rule 22)

Verified directly against the fork's workspace `Cargo.toml` at the pinned SHA: it tracks
two git deps by **branch, not rev** — reproducible only via `Cargo.lock`, and silently
movable under any `cargo update`:

| Dep | Declared | Resolved HEAD (2026-07-16) | Repo state |
|---|---|---|---|
| `GQAdonis/candle` (candle-core/-nn/-metal-kernels/-flash-attn) | `branch = "main"` | `8430d50bf15959e1759c5dc24ea1bc2a0fc90d95` | public, pushed 2026-06-18 |
| `GQAdonis/turboquant-rs` | `branch = "main"` | `b485a88fd1688124d6f641e88367e498cc9365f1` | public, pushed 2026-04-02 |

Both are public and reachable (an earlier read suggested turboquant-rs might be private —
it is not). `mlx-rs` is exact-pinned `=0.25.3` (macOS-only), which is fine.

The fork's own Cargo.toml carries a commented-out upstream fallback
(`huggingface/candle` rev `5404348`, v0.10.2) with the note that it is kept for
reference/fallback if the fork breaks against newer upstream mistral.rs code.

**Mitigation:** commit `Cargo.lock` (already the workspace norm) so the resolved SHAs
above are frozen for reproducible builds, and treat any future `cargo update` touching
candle/turboquant as a deliberate, re-verified action rather than routine. We do not
control these forks; the lockfile is the only pin available short of vendoring.

### Failure modes to surface gracefully (never panic)

Out of VRAM, model too large for device, network failure mid-download, corrupt GGUF.
