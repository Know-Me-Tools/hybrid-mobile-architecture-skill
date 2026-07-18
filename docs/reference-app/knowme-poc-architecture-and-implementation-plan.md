# KnowMe PoC — Architecture, Functional Specification & Implementation Plan

> The post-consolidation web hosting, world-class chat, Flint deployment, BYOK, and
> continuous-learning work is governed by
> [KnowMe Reference App and Agentic Deployment Plan](knowme-agentic-deployment-plan.md).

> Status: living document · Last revised 2026-07-18 (zero-config inference revision: pinned llama.cpp/Qwen on desktop + mobile, WebLLM web lane, mistral.rs optional)
> Companion documents: [knowme-functional-specification-architecture.html](knowme-functional-specification-architecture.html) (product spec), [knowme-moodboard-user-journeys.html](knowme-moodboard-user-journeys.html) (brand + journeys)
> Authority: [AGENT_BASE_RULES.md](../../AGENT_BASE_RULES.md) (all 40 rules) · [TJ-ARCH-MOB-001](../tj-arch-mob-001.html)
> KBD phase: `phase-codegen-and-ci-verification` · Plan of record: `.kbd-orchestrator/phases/phase-codegen-and-ci-verification/plan.md`

---

## 1. Purpose

`apps/knowme-poc/` is a proof-of-concept application built **from** this repository's
scaffolds and skills, **for** the KnowMe product defined in the two HTML reference
documents beside this file. It has a dual mandate:

1. **Prove the skill package works end-to-end.** Every scaffold script, codegen
   pipeline, and architectural seam in this repo is exercised for real — and every
   defect found flows back into the scaffold scripts, not just the app.
2. **Showcase the broadest practical capability range** of the TJ-ARCH-MOB-001
   architecture: streaming ContentBlock chat, PEM entity management, SurrealDB
   graph-RAG memory, local-first sync, on-device inference, and cross-platform
   Flutter/Tauri/web delivery from one shared Rust core.

The PoC is deliberately **a story, not a tile grid** (per web research into showcase
apps: deprecated Flutter Gallery vs. praised Wonderous; Linearlite's
one-workflow-at-scale; Jan/LM Studio's download→load→chat loop). The demo narrative:

> *Record a voice note → on-device transcription → auto-ingest into the memory graph →
> ask chat about it → streamed, cited answer → airplane mode still works → open the
> desktop app, it synced.*

---

## 2. Functional specification (MoSCoW)

### MUST

| ID | Feature | What it proves |
|----|---------|----------------|
| M1 | **Chat** with streamed responses from **any of 142+ providers** via liter-llm — text/thinking/code/citation blocks rendered live; provider/model selected from the config DB | The ContentBlock spine: liter-llm gateway → gen_ui_client → ProtocolPipeline → frb stream / Tauri events → exhaustive UI switch |
| M2 | **Memory**: ingest → hybrid search → cited answer + related-graph panel, with a pre-baked seed corpus | SurrealDB HNSW + BM25 + graph traversal, fastembed 384-dim — the architecture's biggest differentiator |
| M3 | **Local-first sync** of one entity type (memories/notes): offline edit on mobile → appears on desktop | PEM + **our own write-path sync engine** (first-class custom code) with Electric as the read cache; the airplane-mode demo moment |
| M4 | **Local model, minimal**: download the pinned/checksummed Qwen2.5-0.5B-Instruct Q4_K_M via llama.cpp, cloud↔local switch, native chat on desktop/mobile + **in-browser via WebLLM (WebGPU)**, tok/s display | One verified native engine path works without configuration; WebLLM proves the same UX on web; blocking inference never occupies async workers |
| M5 | **Provider/settings config DB**: pglite-oxide (Tauri/mobile Rust layer) + PGlite (web) storing provider credentials, model prefs, and app settings, administered from a Settings surface | The prometheus-db backend-selection pattern (real Postgres semantics on every target) carrying real app state |

### SHOULD

| ID | Feature | Notes |
|----|---------|-------|
| S1 | **Audio Scribe**: record → whisper-tiny on-device transcription → one-tap save-to-memory | The only AI feature that works on all 3 platforms; feeds M2's narrative |
| S2 | **One preconfigured MCP skill** (SSE) → toolUse/toolResult blocks in chat | gen_ui_mcp exercised for real |
| S3 | **Hands as one manual-trigger agent** ("summarize this week's memories") with live step-stream | PMPO loop, thinking/toolUse/artifact blocks; honest about mobile limits |
| S4 | **Tiny local model on mobile CPU** (Qwen-0.5B Q4, labeled "sovereign mode") | Proves FFI + inference on device, honest tok/s |

### COULD

- C1 Scheduled Hands on **desktop only** (tokio interval — trivial there, honest labeling).
- C2 Prompt Lab as a thin second PEM entity (first to cut).
- C3 Minimal Settings: UarMode switch, sync toggle, delete-local-data.

### WON'T (explicit, with reasons)

- **Ask Image / vision** — candle Metal is broken on iOS (candle#1841); sub-1B VLMs are
  captioning-grade. The PoC's biggest potential money pit, deliberately excluded.
- **Real cron Hands on mobile** — iOS BGTaskScheduler is discretionary; demoing
  scheduled mobile agents would be dishonest or flaky.
- **Skills registry UI, full Models management, full Prompt Lab** — product chrome,
  zero new crate coverage.

Coverage check: MUST+SHOULD exercises every headline crate except vision — all 11
ContentBlock variants reachable, streamed inference from any of 142+ providers
(liter-llm), protocol pipeline, PEM graph, SurrealDB graph-RAG, config DB
(pglite-oxide/PGlite), Electric sync, Flint, llama.cpp (desktop/mobile via
`llama-cpp-2`), WebLLM (WebGPU web), optional mistral.rs, whisper, MCP, PMPO.

---

## 3. Architecture

### 3.1 System shape

```
┌────────────────────────────────────────────────────────────────────┐
│  SURFACES (thin, presentation-only)                                │
│                                                                    │
│  Flutter mobile (iOS/Android)      Tauri desktop + web (React 19)  │
│  Riverpod 3.3.2 · gen_ui_widgets   Zustand 5 · PEM 3.x · Vite 8   │
│  Widget → @riverpod → Repo → FFI   Component → Hook → Store →      │
│                                    invoke()/listen() (stores ONLY) │
└───────────────┬────────────────────────────────┬───────────────────┘
                │ flutter_rust_bridge 2.12        │ Tauri 2 IPC
                │ (SSE codec, StreamSink)         │ (commands + events)
┌───────────────┴────────────────────────────────┴───────────────────┐
│  SHARED RUST CORE — 13-crate layered workspace (apps/knowme-poc/rust)│
│                                                                    │
│  gen_ui_types (frozen seams)                                       │
│    → gen_ui_runtime · gen_ui_protocol (A2UI/AG-UI) · gen_ui_client │
│      (liter-llm gateway: 142+ providers) · gen_ui_mcp · gen_ui_db  │
│      (+ config DB: pglite-oxide native / PGlite web) ·             │
│      gen_ui_db_graph (SurrealDB 3.2: HNSW/BM25/graph) ·            │
│      gen_ui_inference (llama.cpp default; mistral.rs optional)     │
│        → gen_ui_agent (PMPO)                                       │
│          → LEAVES: gen_ui_ffi (frb) · tauri-plugin-gen-ui ·        │
│                    gen_ui_wasm · workspace-hack                    │
└────────────────────────────────────────────────────────────────────┘
```

**The invariant (Rule 9 / TJ-ARCH-MOB-001):** all networking, LLM interaction,
inference, MCP, agent logic, and persistence live in the shared Rust core.
Never re-implemented in Dart or TypeScript.

### 3.2 The ContentBlock contract

Every A2UI event maps to exactly one of 11 `ContentBlock` variants (`text`,
`thinking`, `code`, `citation`, `memory`, `toolUse`, `toolResult`, `skill`,
`artifact`, `image`, `divider`). Dart sealed classes and TypeScript discriminated
unions enforce exhaustiveness at the switch site — a missing case is a compile
error on both surfaces.

### 3.3 The intent-level FFI surface

Dart/TS never see raw SurrealQL or SQL. The bridge exposes intent functions only
(`chat_send`, `memory_search`, `graph_expand`, `entity_list/get/create/update/delete`,
`run_migrations`, `load_seeds`, `attach_sync_shapes`, …). Wave-1 changes fill in the
implementations behind these frozen signatures; the frontends never change when the
backend lights up.

### 3.4 Startup boot-order invariant

`migrations → seeds → shapes → ready`, made visible by a StartupGate on both surfaces.
Sync shapes fail on unknown columns, so ordering is enforced, not hoped for.

### 3.5 Inference architecture (three lanes)

> Revised 2026-07-18: generic Anthropic SSE uses the liter-llm gateway; pinned
> llama.cpp/Qwen is the reproducible native default; WebLLM is the web lane;
> mistral.rs remains available only as an optional desktop experiment.

| Lane | Engine | Targets | Notes |
|------|--------|---------|-------|
| **Cloud (any provider)** | [liter-llm](https://github.com/GQAdonis/liter-llm) (GQAdonis fork) wrapped by `gen_ui_client` | desktop, mobile, web | Universal LLM client — **142+ providers**, streaming, tool calling. `native-http` feature (reqwest/rustls) on native; **`liter-llm-wasm`** (fetch-based, no tokio multithread) on web — one Rust dependency serves all three targets. Provider choice, credentials, and model prefs come from the config DB, not env vars; graceful degrade to local-only when no provider is configured. |
| **Local — desktop** | llama.cpp via [`llama-cpp-2`](https://crates.io/crates/llama-cpp-2), via `gen_ui_inference` | desktop | The same revision-pinned, SHA-256-gated Qwen2.5-0.5B Q4_K_M catalog model as mobile. First chat downloads atomically into app data; later runs reuse it. This is the reference default because it built with Tauri and completed the real mobile UI-to-model path; mistral.rs remains optional behind `InferenceProvider`. |
| **Local — mobile** | llama.cpp via [`llama-cpp-2`](https://crates.io/crates/llama-cpp-2), via `gen_ui_inference` | mobile (iOS/Android CPU) | Qwen2.5-0.5B Q4_K_M “sovereign mode.” The iOS integration test verified download, checksum, GGUF load, streamed A2UI output, and an assistant bubble through Flutter → Riverpod → FRB → Rust. |
| **Local — web** | [WebLLM](https://webllm.mlc.ai/) (MLC), WebGPU | web only | Researched 2026-07 (firecrawl): WebLLM is the consensus in-browser chat engine — WebGPU-accelerated, OpenAI-compatible streaming API, curated quantized models including **Qwen2.5-1.5B-Instruct-q4f16_1-MLC** (same family as the native lane), models cached in browser storage. Feature-gated on WebGPU availability; degrade to the liter-llm cloud lane when absent (wllama/WASM rejected as primary: CPU-only speeds don't demo well; transformers.js reserved as the web option for embeddings/whisper-class tasks, not chat). |

**Documented exception to the Rust-core invariant:** WebLLM is a TypeScript
library living in the web surface layer — wasm-compiled mistral.rs is not viable
(Metal/CUDA/CPU-native design). The seam stays honest: the surface-level intent API
(`chat_send` with a local-model selection) is identical on all targets; only the web
adapter fulfils it in TS. Everything else (cloud lane included) remains in Rust.

### 3.6 Configuration database (new)

Provider credentials, model preferences, and app settings live in a real
PostgreSQL-semantics store on every target, per the prometheus-db selection pattern:

- **Tauri desktop / mobile:** [pglite-oxide](../pglite-oxide-tauri-hybrid.md) —
  PostgreSQL 17.5 as a Rust crate, standard connection string, accessed only from
  the Rust core (`gen_ui_db`); settings never transit the FFI as raw SQL.
- **Web:** ElectricSQL **PGlite** (WASM, IndexedDB-backed) — already a scaffold
  dependency for the entity runtime; the config schema rides the same instance.
- Schema v1: `providers` (id, kind, base_url, api_key_ref, enabled),
  `model_prefs` (surface, lane, model_id, params), `app_settings` (key, value).
  Administered from the Settings surface (C-109); read at startup after
  migrations (the boot-order invariant §3.4 already covers it).
- Secrets discipline (Rule: no plaintext keys): API keys stored via the platform
  keychain where available (tauri-plugin-store/keychain on desktop,
  flutter_secure_storage on mobile); the DB row keeps a reference, web falls back
  to session-scoped entry with a visible warning.

### 3.7 Data & sync

- **On-device graph:** SurrealDB 3.2 embedded (memory/entity graph, HNSW vector +
  BM25 + recursive RELATE traversal, RRF-fused hybrid search in Rust).
- **Relational/sync path:** PGlite (web, IndexedDB) / Postgres semantics. **The
  write path is first-class custom software we own** — ElectricSQL deliberately
  dropped write-path sync in its `electric-next` rewrite and is a read-path
  engine only; our `gen_ui_db::sync` write queue IS the sync engine, with
  Electric as the read cache. Staff, test, and estimate it as owned product
  code, not integration glue. For M3 it runs from `infra/docker-compose.yml`
  (Postgres + Electric) so the whole demo works on one machine.
- **PEM (prometheus-entity-management):** families-as-normalization entity layer on
  both surfaces (Dart port + npm packages).

### 3.8 Desktop app shell (adjusted after execution — see §5)

- **Custom branded titlebar** (`decorations: false`): KnowMe K-monogram + wordmark,
  platform-aware window controls (traffic-light left on macOS, controls right on
  Windows), drag via `data-tauri-drag-region` + explicit `startDragging()`.
- **Native menu:** File (Exit) · View (Fullscreen, —, Toggle Developer Tools **last**)
  · Help (About). Devtools reachable in packaged builds (`devtools` cargo feature).
- **Tauri v2 capabilities:** explicit `capabilities/default.json` (core defaults +
  window controls + os plugin) — the ACL denies everything otherwise.

### 3.9 Branding (single source of truth)

Tokens extracted from the two reference HTML docs into `desktop/src/index.css`
(`@theme` + `body.light` override) — to be mirrored into the Flutter ThemeData by a
later change (one token source feeds both surfaces, per the `hybrid-design-tokens`
project skill):

- **Dark (default):** bg `#0B0F14`, surface `#161D29`, card `#1C2535`, border
  `#1F2D40`, fg `#E8EDF3`, **ember `#FF6A3D`** (brand accent), cyan `#00C2DC`
  (AI/annotation voice), green/amber/red status.
- **Light:** bg `#F7F7F8`, ember deepens to `#E04E28`, cyan to `#0891B2`.
- **Type:** Space Grotesk (display, tight tracking) · Inter (UI/body) · Roboto
  (long-form, light lead paragraphs) · JetBrains Mono (uppercase tracked eyebrows,
  code, metadata).
- **Logo:** rounded-bar "K" monogram with ember node at the joint; wordmark
  `Know` + ember `Me`. App icon = monogram on dark rounded square
  (`desktop/branding/app-icon-source.svg` → `tauri icon`).

---

## 4. Implementation plan

Ten changes in three waves (OpenSpec-backed, IDs under `openspec/changes/`).
Binding: AGENT_BASE_RULES.md for every change. Harness assignment per the
prior-phase scorecard (claude 8/8, codex 2/2, opencode 0/2 → no opencode lanes).

```
WAVE 0 (serial):   C-101 bootstrap ──► C-102 PoC scaffold + FIRST CODEGEN   ✅ DONE
WAVE 1 (app):      C-103 chat ─► C-104 memory ─► C-105 local-model ─► C-106 sync
                   C-107 whisper ∥ (after C-103)    C-110 CI ∥ (after C-102)
WAVE 2 (finish):   C-108 mcp+agent ─► C-109 settings + mobile model → reflect
```

| ID | Scope | Status |
|----|-------|--------|
| C-101 | Four-pillar bootstrap (`check-env.sh` rewrite): Rust 1.95+/wasm32 + Prometheus Skill System, OpenSpec ≥1.6 (`@fission-ai/openspec`), Flutter **beta** + Dart MCP server, Node 24+/bun/pnpm/TS 7.x; ran live on this box | ✅ **merged** |
| C-102 | Scaffold `apps/knowme-poc`, run the full codegen pipeline for the first time ever, fix everything in the **scaffold scripts**, verify build+run on desktop (Tauri) and web | ✅ **merged** (see §5 for the ~25 defects fixed) |
| C-103 | M1+M5 foundation — chat live e2e through the **liter-llm gateway** (142+ providers; native-http on desktop/mobile, liter-llm-wasm on web) + **config DB v1** (pglite-oxide native / PGlite web: providers, model_prefs, app_settings schemas + migrations); graceful degrade when no provider configured; ProtocolPipeline → ContentBlock stream over frb + Tauri events; first iOS-simulator run | 🟨 in progress — shared stream/config foundation and desktop + hosted BYOK are implemented; final live-provider/mobile proof remains |
| C-104 | M2 memory graph-RAG: intent APIs wired to gen_ui_db_graph + fastembed, seeded corpus, cited answers, related-graph panel | ⬜ pending |
| C-105 | M4 local model: pinned/checksummed **llama.cpp** Qwen on desktop/mobile; **WebLLM (WebGPU)** on web behind the same intent seam; cloud↔local switch, first-run download, streaming, tok/s | ✅ native engine and web lane implemented; iOS UI-to-model runtime proof passed; Tauri release link passed |
| C-106 | M3 sync local-first: our write-path sync engine (gen_ui_db::sync) + Electric read cache via docker-compose Postgres+Electric, one entity synced desktop↔mobile-sim, airplane-mode demo | ⬜ pending |
| C-107 | S1 whisper scribe (whisper-rs, feature-gated), all 3 native platforms; evaluate fork's mistralrs-audio as alternative; web scribe (transformers.js whisper) as stretch | ⬜ pending (parallel lane) |
| C-108 | S2+S3: one MCP SSE server + one canned Hands agent with live step-stream | ⬜ pending |
| C-109 | C3+S4: Settings provider/model admin over the config DB, keychain/session-only BYOK, plus Qwen-0.5B sovereign mode through **llama.cpp (`llama-cpp-2`)** behind `InferenceProvider` | ✅ provider UI/keychain/session-only web BYOK wired; iOS build/download/generation proof passed; desktop uses the same native engine |
| C-110 | CI: clippy -D warnings, audit.sh all, boundary tests, Vitest, dart analyze, macOS PoC build job | ⬜ pending (parallel lane) |

### Benchmark gates (added 2026-07-16 per independent assessment)

The plan previously verified *that things build*; these gates verify *that the
architecture's claims are true on hardware*. Each gate is a blocking plan item
with a pre-named fallback — a gate failure triggers the fallback, not a debate.

| Gate | When | Measures | Pass condition | Named fallback |
|------|------|----------|----------------|----------------|
| G1 frb streaming | **C-103**, first iOS-simulator/on-device run | flutter_rust_bridge StreamSink throughput + latency under sustained A2UI token streaming (the full-matrix frb claim was *refuted* in adversarial verification — this is the program's highest-information action) | Smooth streaming render at realistic token rates on device | Tauri-events-style polling bridge on mobile chat, or scope mobile to non-streaming views for the PoC |
| G2 SurrealDB embedded | **before C-104 implementation starts** | Graph-RAG workload (HNSW + BM25 + RELATE traversal, RRF fusion) latency + memory on a mobile-class RAM budget, seeded corpus | Interactive-grade hybrid search (sub-second on the demo corpus) without abnormal memory | sqlite-vec + FTS5 + recursive CTEs covering the demo's search/graph subset |
| G3 mobile llama.cpp | **C-109** (S4 sovereign mode) | Qwen-0.5B Q4 CPU tok/s on a real device via `llama-cpp-2` | Demo-usable generation speed | Cut S4 from the PoC demo; local inference stays desktop(M4)+web |

### Decision log (2026-07-16 assessment remediation)

- **Config DB stays on pglite-oxide for the PoC** (user decision). The
  assessment's rec #6 — collapse the DB matrix, SQLite for the config DB,
  pglite-oxide as a post-PoC desktop upgrade — is recorded as the **post-PoC
  simplification option**, to be revisited at phase reflection. The pglite lane
  now has bundled runtime assets, a coalesced singleton open, and a concurrent
  regression test; the remaining risk it carries is currency (pre-1.0 crate on
  a moving PGlite core).
- **Sync reclassified** as first-class custom code (§3.7) — Electric is a read
  cache; the write path is ours.
- **Mobile inference lane switched** to llama.cpp (`llama-cpp-2`) behind the
  new `InferenceProvider` trait seam (gen_ui_types) — see §3.5.
- **Open question, no evidence either way:** paying demand for the $200/mo
  sovereign tier. No market comps survived adversarial verification. Validate
  with a landing page and buyer conversations **before** building tier
  machinery; do not treat the tier as a settled requirement.

### Success criteria (phase completes when)

- Bootstrap passes all four pillars on this box ✅
- `apps/knowme-poc` builds and runs the MUST set live on macOS Tauri + iOS simulator
  + Chrome/web (desktop ✅, web ✅, iOS sim ⬜ — lands with C-103)
- The demo narrative executes end-to-end (voice→transcribe→ingest→ask→cited
  answer→offline→sync) ⬜
- CI is green on main ⬜
- Scaffold fixes discovered en route are committed back ✅ (ongoing discipline)

---

## 5. Adjustments from execution (what C-102 actually taught us)

The first-ever full codegen run surfaced ~25 real defects — every one fixed in the
scaffold scripts *and* the generated app. The plan above stands, but with these
recorded corrections:

### 5.1 Pipeline & scaffold defects (fixed at source)

- **`scaffold-hybrid.sh` path bugs:** `$(dirname "$0")` resolved wrong after `cd`
  (fixed via absolute `SCRIPT_DIR` from `BASH_SOURCE`); full project path passed
  where the app *name* was expected broke `sed` (fixed via `basename`).
- **`set -euo pipefail` traps:** unguarded command substitutions
  (`cargo-ndk --version`, grep-no-match, `ls nomatch* | head -1`) silently killed
  scripts — all guarded with `|| VAR=""`.
- **Stale/invented dependency pins** (verified against live registries, Rule 22/23):
  riverpod_sqflite ^0.2→^0.4.3, shadcn_flutter ^0.1.6 (nonexistent)→^0.0.53,
  freezed ^2.x→^3.2.5, json_annotation →^4.12, Dart SDK floor →3.8;
  `custom_lint`/`riverpod_lint` **removed entirely** (unresolvable analyzer
  conflict as of 2026-07).
- **frb config format:** `rust_input` takes Rust module syntax (`crate::api`),
  not a filesystem path.
- **Riverpod 3.3.2 realities:** `Mutation` exists internally but is NOT publicly
  exported → replaced with local bool pending-state; generator names
  `ChatNotifier → chatProvider` (drops "Notifier"); `.valueOrNull` → `.value`.
- **TS 7 removed `baseUrl`** — tsconfig template fixed; `src/vite-env.d.ts` was
  missing entirely (`.css`/`?raw` imports failed).
- **`@flint/react` git+path dependency:** pnpm's fetch of the subdirectory tarball
  delivered only `package.json`+`SKILL.md` (no src) — built from a full clone of
  the pinned commit and vendored the dist (user-approved). Upstream fix belongs in
  flint-forge's packaging.
- **PEM tarball pre-resolve:** the plan's option (a) is implemented in
  scaffold-tauri.sh, but at execution time `pnpm pack` failed in PEM_HOME
  (corepack pin mismatch) — the **fallback path** (strip PEM, use local
  gen-ui-react) is what actually ran. Re-enabling the tarball path needs the PEM
  checkout's corepack state fixed.

### 5.2 Tauri desktop shell defects (fixed at source)

- Missing `build.rs` + `tauri-build` dependency (generate_context! needs OUT_DIR).
- `main.rs` hardcoded `app_lib::run()` vs. actual crate name (now derived).
- **No icons generated** — scaffold now emits a placeholder via stdlib-Python PNG +
  `tauri icon`; the PoC uses the real brand monogram.
- **No capabilities file** — Tauri v2 denies all IPC by default; frontend
  `event.listen()` threw at runtime. Scaffold now emits `capabilities/default.json`.
- **`invoke_handler` was commented out** while the frontend called
  `run_migrations` unconditionally at startup → every launch failed. Scaffold now
  registers stub commands (`Ok(())` bodies) so apps boot before backends land —
  frozen signatures, Wave-1 fills them in.
- frb codegen auto-injects `mod frb_generated;` at line 1, above inner doc
  comments → E0753; `pub use` (not `use`) required in api modules for the
  generated glob re-export to see bridged types.

### 5.3 Web-target lesson (the isTauri() rule)

The same Vite bundle serves the native webview **and** plain web. Any Tauri API
called unconditionally at module/init scope (`getCurrentWindow()`, `listen()`)
throws in a plain browser (no `__TAURI_INTERNALS__`) and can blank the entire app
with no console error. **Rule adopted:** every Tauri call is gated behind
`isTauri()` and degrades to a no-op; three violations found and fixed
(Titlebar, chatStore.initListeners, flintSurfaceStore.start).

### 5.4 Dev-mode icon caveat (not a bug)

`tauri dev` runs a bare Mach-O executable with no Info.plist — macOS shows a
generic/cached Dock icon regardless of the icon set. Only `tauri build`
(or `--debug --bundles app`) produces the `.app` bundle whose Dock icon is real.
Verified: the debug bundle shows the correct KnowMe monogram.

### 5.5 Verification status (as of this revision)

| Check | Result |
|---|---|
| `cargo check --workspace` (13 crates) | ✅ clean |
| `flutter analyze` (mobile) | ✅ 0 errors / 0 warnings (info-level style lints remain) |
| `tsc --noEmit` (desktop) | ✅ clean |
| `tauri dev` native window | ✅ runs, renders, zero console errors |
| Same bundle in plain browser (web) | ✅ renders, zero console errors |
| `tauri build --debug` .app bundle | ✅ builds, correct Dock icon |
| iOS simulator run | ⬜ scheduled with C-103 |
| `audit.sh all` on the PoC | ⬜ to run at C-110 |

---

## 6. Open items & risks carried forward

1. **First on-target iOS run** still pending (C-103) — frb type-compat on device is
   the next highest-information step.
2. **Provider config at demo time** — chat degrades gracefully to local-only when
   the config DB has no enabled provider (design requirement, not yet implemented);
   keys entered through Settings, never env vars.
3. **Sync overrun fallback** stands: if C-106 integration overruns, ship the
   write-path engine (ours, proven by boundary tests) with a SyncStatus stub and
   defer only the Electric read-cache wiring — the custom write path is the
   load-bearing deliverable, not the Electric integration.
4. **PEM corepack fix** needed in the PEM monorepo to re-enable the tarball
   pre-resolve path (currently on the strip-PEM fallback).
5. **Model download size** (~1GB Qwen-1.5B Q4 native; ~900MB q4f16 MLC on web) —
   pre-download / pre-cache in demo prep.
6. **Flutter mobile branding parity** — the KnowMe tokens live only in the desktop
   CSS today; the token→ThemeData mirror lands with the first mobile-facing change.
7. **Fork dependency hygiene** — liter-llm and mistral.rs enter the workspace as
   git dependencies pinned to a SHA on the GQAdonis forks; note the pnpm git+path
   lesson (§5.1) does not apply to cargo git deps, but pin SHAs and record them in
   the decision log (Rule 22/23). liter-llm is also vendored inside
   universal-agent-runtime as a submodule — the PoC consumes it directly from the
   fork instead, keeping one source of truth.
8. **WebGPU availability** — the web local lane requires WebGPU (Chrome/Edge
   stable, Safari 26+); the feature gate + cloud degrade must be visible UI, not a
   silent failure.
