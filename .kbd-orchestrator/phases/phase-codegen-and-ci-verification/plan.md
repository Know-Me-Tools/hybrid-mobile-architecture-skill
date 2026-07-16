# Plan — phase-codegen-and-ci-verification

> Generated 2026-07-15 · Inputs: assessment.md (PoC MoSCoW + gaps G-1..G-8),
> analysis.md (bootstrap pillars + 7-item delta + base-rules propagation, TS 7.0.2),
> library-candidates.json · Backend: OpenSpec · 10 changes in 3 waves
> Binding: AGENT_BASE_RULES.md (all 40 rules) for every change.

## Plan-time decisions (resolved)

1. **PEM install blocker → option (a), local tarball pre-resolve.** The PEM monorepo
   exists at `~/Projects/prometheus/prometheus-entity-management` with `entity-graph-core`
   and `entity-graph-react` **prebuilt** (verified). `scaffold-packages.sh` gains a
   pre-resolve step: `pnpm pack` the needed PEM workspace packages into
   `packages/vendor/*.tgz` and rewrite the app's PEM deps to `file:` tarballs.
   Env `PEM_HOME` (default above); **fallback** when absent: strip PEM deps and use the
   local `@prometheus-ags/gen-ui-react` + our entity providers (PoC still builds).
2. **Sync infrastructure → local docker compose.** The PoC ships
   `apps/knowme-poc/infra/docker-compose.yml` (Postgres + Electric) so M3's
   cross-surface sync demo runs entirely on one machine (desktop + iOS sim).
   Fallback if Electric integration overruns: SyncStatus stub with the write queue
   proven by boundary tests (seam already exists).
3. **Bootstrap remediation defaults** (analysis rec adopted): check-only by default;
   `--install` remediates normal items; `--full` additionally runs long operations
   (flutter upgrade, full skill-system install). Staleness = warn tier.

## Wave structure

```
WAVE 0 (serial):    C-101 bootstrap ──► C-102 PoC scaffold + FIRST CODEGEN (highest-information)
WAVE 1 (app):       C-103 chat ─► C-104 memory ─► C-105 local-model ─► C-106 sync
                    C-107 whisper ∥ (after C-103)     C-110 CI ∥ (any time after C-102)
WAVE 2 (finish):    C-108 mcp+agent ─► C-109 settings + mobile model → phase reflect
```

All Wave-1+ changes edit the same app — sequential within the app by default;
C-107 (new audio crate + separate feature) and C-110 (CI) run in parallel worktrees.

## Changes (ordered)

**C-101 `2026-07-15-c101-bootstrap-pillars`** — check-env.sh → four-pillar bootstrap
(the 7-item delta): Node floor 24 + `fnm install 24`; add bun; add TypeScript ≥7.0.2
(`typescript@latest`); add OpenSpec ≥1.6.0 (scoped `@fission-ai/openspec`, channel-aware,
never bare name); add Prometheus Skill System pillar (binaries + `pk doctor --json` +
mcp-health as operational gates, documented install flow when missing, wasm32 target +
Docker prereqs); Flutter beta enforcement + releases-JSON currency + `dart mcp-server`
gate; rewrite install-flutter.sh (`-b beta`, non-shallow). Align frb codegen 2.11→2.12
(G-1). **Then run it on this box** (`--install --full`): flutter 3.45→3.47, openspec
1.4.1→1.6.0, tsc 6.0.3→7.0.2 — the first live test. Update CLAUDE/AGENTS version tables.
*Deps: none. Size: L. Harness: claude/sonnet-5.*

**C-102 `2026-07-15-c102-poc-scaffold-first-codegen`** — Scaffold `apps/knowme-poc` via
scaffold-hybrid.sh; PEM tarball pre-resolve step in scaffold-packages.sh (decision 1);
run the FULL codegen pipeline for the first time ever: `flutter_rust_bridge_codegen
generate` → `dart run build_runner build` → `flutter pub get` → `pnpm install` →
`npx tsc --noEmit` (TS 7!). Fix everything that falls out **in the scaffold scripts**
(the PoC is the verification vehicle — fixes flow back). Verify: pre-codegen warnings
clear (G-2); AGENT_BASE_RULES.md + CLAUDE/AGENTS + skills landed in the app; audit.sh
all passes; `cargo check` the app's workspace. Expect FFI-surface iteration.
*Deps: C-101. Size: L-XL. Harness: claude/opus-4.8.*

**C-103 `2026-07-15-c103-chat-live-e2e`** — M1+M5 foundation (REVISED 2026-07-15,
user-directed): wire the real chat path end-to-end through the **liter-llm gateway**
(GQAdonis/liter-llm fork, pinned SHA — 142+ providers; `native-http` on desktop/mobile,
`liter-llm-wasm` on web) instead of a bespoke Anthropic SSE client, plus **config DB
v1** (pglite-oxide in the Rust core for Tauri/mobile, PGlite on web: `providers`,
`model_prefs`, `app_settings` schemas + migrations; keys via platform keychain,
DB keeps refs). Provider/model selection reads the config DB, never env vars;
graceful degrade to local-only when no provider enabled. ProtocolPipeline →
ContentBlock stream over frb + Tauri events; run live on macOS Tauri AND iOS
simulator (first on-target run, G-6). text/thinking/code blocks render streamed.
*Deps: C-102. Size: L (grew: +config DB). Harness: claude/sonnet-5.*

**C-104 `2026-07-15-c104-memory-graph-rag`** — M2: gen_ui_db_graph wired through the
intent APIs (memory_ingest/search/graph_expand + fastembed 384-dim); seeded corpus
(few hundred curated notes); Memory tile: ingest → hybrid search → chat answers with
tappable citation/memory blocks + related-graph panel; hybrid-vs-vector dev toggle.
*Deps: C-103. Size: L. Harness: claude/sonnet-5.*

**C-105 `2026-07-15-c105-local-model-desktop`** — M4 (REVISED 2026-07-15,
user-directed): local model on desktop AND web. Native: **mistral.rs** library
(GQAdonis/mistral.rs fork, pinned SHA; `mistralrs` crate wraps download-from-HF +
GGUF/ISQ load + streaming generation) behind gen_ui_inference — Qwen2.5-1.5B-Instruct
Q4_K_M on Metal, spawn_blocking discipline, graceful VRAM/size errors; same crate
serves C-109's mobile CPU lane. Web: **WebLLM (WebGPU)** adapter in the web surface
(researched 2026-07 via firecrawl — consensus in-browser chat engine, OpenAI-compatible
streaming, Qwen2.5-1.5B-Instruct-q4f16_1-MLC same-family model, browser-cached),
feature-gated on WebGPU with visible degrade to the liter-llm cloud lane; documented
exception to the Rust-core invariant (TS adapter fulfils the same intent seam).
Cloud↔local switch in chat, tok/s display on both.
*Deps: C-103. Size: L (grew: +web lane). Harness: claude/opus-4.8.*

**C-106 `2026-07-15-c106-sync-local-first`** — M3: infra/docker-compose.yml (Postgres +
Electric); notes/memories entity syncs desktop↔mobile-sim via Electric read-path +
DIY write queue; airplane-mode demo moment (offline edit → replay); SyncChip live.
Fallback per decision 2 if Electric overruns.
*Deps: C-104. Size: L. Harness: claude/opus-4.8.*

**C-107 `2026-07-15-c107-whisper-scribe`** — S1: whisper-rs (feature-gated crate or
gen_ui_audio), whisper-tiny model; Scribe feature: record → transcribe on-device →
one-tap save-to-memory (feeds C-104's ingest). All three platforms.
*Deps: C-103 (parallel with C-105/C-106 — own crate + feature). Size: M-L.
Harness: codex/gpt-5.6-sol.*

**C-108 `2026-07-15-c108-mcp-skill-and-agent`** — S2+S3: one preconfigured MCP SSE
server registered via gen_ui_mcp (toolUse/toolResult blocks in chat); one canned Hands
agent ("summarize this week's memories") with Run-now + live step-stream
(thinking/toolUse/artifact) through the PMPO loop; result saved to memory. Desktop-only
scheduling (tokio interval) as C1 stretch, honestly labeled.
*Deps: C-104 (+C-103 plumbing). Size: L. Harness: claude/sonnet-5.*

**C-109 `2026-07-15-c109-settings-mobile-model`** — C3+S4 (REVISED 2026-07-15):
Settings surface grows the **provider/model administration UI over the config DB**
(add/edit/disable providers across the 142+ liter-llm catalog, per-lane model prefs,
keychain-backed key entry) + UarMode switch, sync toggle, delete-local-data +
Qwen-0.5B Q4 CPU "sovereign mode" on iOS sim/Android via mistral.rs, honest tok/s
labeling.
*Deps: C-105, C-106. Size: M-L (grew: +admin UI). Harness: codex/gpt-5.6-sol.*

**C-110 `2026-07-15-c110-ci`** — G-7: GitHub Actions — `cargo clippy --workspace
-D warnings`, `audit.sh all` on a scaffolded scratch app, Rust boundary tests,
Vitest suite, `dart analyze` post-codegen; PoC build job (macOS runner: tauri build +
flutter build ios --simulator). Caches per compile-speed.md.
*Deps: C-102 (parallel with Wave 1). Size: M. Harness: codex/gpt-5.6-sol.*

## Harness notes

Prior-phase scorecard applied: claude 8/8, codex 2/2, opencode 0/2 → **no opencode
lanes**. Dispatch via `.kbd-orchestrator/dispatch/dispatch.sh` (preamble now carries
AGENT_BASE_RULES as authority #0). Sequential app-changes run in the main checkout or
serialized worktrees off latest main; parallel lanes (C-107, C-110) get worktrees.

## Success criteria (Rule 4)

Phase completes when: bootstrap passes all four pillars on this box; `apps/knowme-poc`
builds and runs the MUST feature set live on macOS Tauri + iOS simulator + Chrome/web;
the demo narrative executes end-to-end (voice→transcribe→ingest→ask→cited answer→offline
→sync); CI is green on main; scaffold fixes discovered en route are committed back.

## First change

**C-101** (bootstrap). C-110 may not start until C-102 exists.
