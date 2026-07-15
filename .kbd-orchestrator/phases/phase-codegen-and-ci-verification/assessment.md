# Assessment — phase-codegen-and-ci-verification

> Generated 2026-07-15 · Goal (revised at assess, user-directed): build a proof-of-concept
> app in `apps/<name>/` from the KnowMe reference docs (`docs/reference-app/`), using the
> scaffolds/skills in this repo, showcasing the broadest practical capability range.
> Supporting goals: real codegen pass, PEM unblock, run-on-target verification, CI.

## 1. Current state

### What the previous phase left us (all merged & verified on main)
- 13-crate layered Rust workspace scaffold (`gen_ui_types` seams → db/db_graph/client/mcp
  → agent → ffi/tauri-plugin/wasm), clippy/wasm/boundary-test verified.
- Flutter scaffold v2 (Riverpod 3.3.2, PEM Dart port, chat/notes/memory/startup features,
  audit PASS 38/0) and Tauri scaffold (React 19/Vite 8, PEM 3.0.0-alpha.0 wiring,
  memory/startup, audit PASS 44/0) — both emitting the KnowMe-slice seams already.
- Project-level MCP (Dart/Flutter + shadcn) config for all 4 harnesses; project skills.
- `docs/reference-app/` contains the KnowMe functional spec + moodboard (same documents
  analyzed in the prior phase — eight tiles, four commitments, sovereignty model).
- `apps/` exists, empty.

### What has NEVER been exercised (the honest gap)
- `flutter_rust_bridge_codegen generate` has never run against the emitted `gen_ui_ffi`.
- `dart run build_runner build` never run (the 379 pre-codegen analyze warnings unresolved).
- `pnpm install`/`npm run tauri dev` never completed (PEM workspace:* blocker).
- No app has ever been launched on a real target.
- No CI.

## 2. Environment readiness (checked live)

| Tool | State | Gap |
|---|---|---|
| flutter_rust_bridge_codegen | **2.11.1** installed | ⚠ scaffold pins frb crate 2.12 — codegen/crate versions must align → `cargo install flutter_rust_bridge_codegen@2.12.x` (or pin crate to 2.11) |
| Dart / Flutter | 3.13 beta / 3.45 beta | OK (exceeds MCP-server 3.9/3.35 floor) |
| iOS simulators | iPhone 16 family available | OK |
| Flutter devices | macOS desktop + Chrome | OK (Android emulator not checked — not required for first target) |
| pnpm / tauri-cli | 11.11.0 / 2.10.0 | OK |
| Rust toolchain | 1.95 pinned | OK |
| cargo-ndk | missing | Only blocks Android native builds — defer |

## 3. PoC feature selection (web-researched)

Research verdict: **a story, not a tile grid.** Deprecated Flutter Gallery vs praised
Wonderous; Linearlite's one-workflow-at-scale; Jan/LM Studio's download→load→chat loop.
The demo narrative: *record a voice note → on-device transcription → auto-ingest into
memory graph → ask chat about it → streamed cited answer → airplane mode still works →
open desktop, it synced.*

### MoSCoW (full research + sources in phase notes)

**MUST**
- M1 Chat with streamed cloud responses (text/thinking/code/citation blocks) — the ContentBlock spine.
- M2 Memory: ingest → hybrid search → cited answer + related-graph panel — SurrealDB HNSW+BM25+graph, fastembed; our biggest differentiator. Ship a pre-baked seed corpus (Linearlite lesson).
- M3 Local-first sync of ONE entity type (memories/notes): offline edit mobile → appears desktop — PEM + Electric read-path + write queue + Flint.
- M4 Models minimal: download one GGUF (Qwen2.5-1.5B Q4_K_M class), switch cloud↔local, local chat on macOS Metal — candle engine made tangible.

**SHOULD**
- S1 Audio Scribe: whisper-tiny via whisper-rs — the ONLY AI feature that works on all 3 platforms; feeds M2's ingest narrative.
- S2 One preconfigured MCP skill (SSE) → toolUse/toolResult blocks in chat.
- S3 Hands as ONE manual-trigger agent with live step-stream (PMPO loop, artifact block) — honest about mobile.
- S4 Tiny local model on mobile CPU (Qwen-0.5B Q4, "sovereign mode" labeled) — proves FFI+inference on device.

**COULD**
- C1 Scheduled Hands on desktop only (tokio interval — trivial there).
- C2 Prompt Lab as thin second PEM entity (cut first).
- C3 Minimal Settings (UarMode switch, sync toggle, delete-local-data).

**WON'T (explicit)**
- Ask Image / vision: candle Metal broken on iOS (#1841), sub-1B VLMs captioning-grade — the PoC's biggest money pit.
- Real cron Hands on mobile: iOS BGTaskScheduler is discretionary; iOS 26 BGContinuedProcessingTask mandates user initiation — demoing scheduled mobile agents would be dishonest or flaky.
- Skills registry UI, full Models management, full Prompt Lab: product chrome, zero new crate coverage.

Coverage check: MUST+SHOULD exercises every headline crate except vision — all 11
ContentBlock variants reachable, SSE streaming, protocol pipeline, PEM graph, SurrealDB
graph-RAG, Electric sync, Flint, candle (Metal desktop + CPU mobile), whisper, MCP, PMPO.

## 4. Gap analysis → work implied

| # | Gap | Work |
|---|---|---|
| G-1 | frb codegen 2.11 vs crate 2.12 mismatch | Align versions before first codegen run |
| G-2 | Codegen pipeline never run | Scaffold the PoC into `apps/`, run frb codegen + build_runner, fix what falls out (expect FFI-surface type issues — first real exercise) |
| G-3 | PEM `entity-graph-core@workspace:*` blocker | Options: (a) pack/patch step in scaffold-packages.sh that pre-resolves workspace deps from the PEM monorepo checkout; (b) upstream publish (out of our control); (c) PoC web/desktop uses the local `@prometheus-ags/gen-ui-react` + our own entity providers only, deferring PEM-the-npm-package. Decide at plan. |
| G-4 | Rust intent stubs are `UnimplementedError` | Wire the real paths the PoC needs: chat SSE (needs an Anthropic or gate key at runtime), memory ingest/search (gen_ui_db_graph), sync (or stub sync status for PoC v1), GGUF load/generate, whisper transcription (new dep: whisper-rs), one MCP SSE server |
| G-5 | No app in `apps/` | `scaffold-hybrid.sh apps/knowme-poc` then implement MoSCoW features on the emitted skeleton |
| G-6 | Run-on-target never done | macOS Tauri first (fastest loop), then iOS simulator Flutter, Chrome web |
| G-7 | No CI | GitHub Actions: clippy + audit.sh all + boundary tests, PoC build job |
| G-8 | whisper-rs not in workspace | Add feature-gated dep in gen_ui_inference (or a small gen_ui_audio crate) |

## 5. Risks / open questions

1. **First real codegen run will surface FFI-surface issues** (frb type-compat across the
   layered crates was designed for but never executed). Budget iteration time in the plan.
2. **API keys at demo time**: chat's cloud path needs ANTHROPIC_API_KEY (or a running
   flint-gate). PoC should degrade gracefully to local-model-only when absent.
3. **Flint services live?** M3's sync needs a reachable Postgres/Electric (or the DIY
   queue pointing at flint-forge). PoC v1 could run sync against a local docker compose,
   or defer live sync to a stub with the seam proven by tests. Decide at plan.
4. **PEM decision (G-3)** shapes the React surface's entity layer — needs a plan-time call.
5. Model download size (~1GB Qwen-1.5B Q4) — pre-download in demo prep, don't stream live.

## 6. Recommendation

Name the PoC `apps/knowme-poc`. Plan should sequence: toolchain alignment (G-1) →
scaffold + first codegen (G-2/G-5, the highest-information step) → M1 chat → M2 memory →
M4 local model (desktop) → M3 sync → S1 whisper → S2 MCP → S3 agent → C3 settings →
CI (G-7) throughout. Fix issues in the *scaffold scripts* as they're found (the PoC is
the verification vehicle for the skill package — improvements flow back).
