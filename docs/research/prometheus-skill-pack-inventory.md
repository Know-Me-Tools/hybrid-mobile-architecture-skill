# Prometheus Skill Pack — Capability Inventory (Research Brief)

**Brief slug:** `prometheus-skill-pack-inventory`
**Researcher:** KNOWME_RESEARCHER (deep-research swarm)
**Date:** 2026-07-18
**Repo surveyed:** `/Users/gqadonis/Projects/prometheus/prometheus-skill-pack` (local clone of `https://github.com/Prometheus-AGS/prometheus-skill-system`, `SKILLS.md` frontmatter version **1.2.0**; last local commit `de80da2`, 2026-07-17 22:32 -0500 — actively developed)
**Lens:** everything touching local-first operation, sync, storage abstraction, agent harness skills, skill authoring/packaging, and how skills are structured/distributed today — feeding the KnowMe master goal (pglite/pglite-oxide ↔ flint-realtime-fabric ↔ flint-forge postgres; WASM component skills; A2UI/AG-UI/HTMX modules; CRDT over WebRTC/lora-rs; decentralized packaging).

---

## 1. What the repo is (facts)

A self-described "self-improving AI skill execution engine": 35 top-level skills / 95+ with sub-skills across 13 categories, a 4-layer orchestration pipeline (ZeeSpec → PMPO → OpenSpec → forge-rs), a Karpathy learning loop, Cedar-governed self-mutation, and — most relevant to the master goal — a **`substrate/` directory of six Rust crates** that implement a local-first, P2P, CRDT-synced runtime beneath the skill layer.

Top-level orientation docs (all read in full):

| File | Content |
|---|---|
| `README.md` | Product tour: 4-layer pipeline, native agent generator, tools, MCP substrate (8 servers, port table `scripts/mcp-port-table.json`), platform matrix (10 harnesses), repository structure. Claims "Production readiness: 92%". |
| `SKILLS.md` | Skill-pack manifest (name `prometheus-skill-pack`, version 1.2.0, `type: collection`, MIT); full skills index by category; memory architecture (surreal-memory + graceful degradation); validation commands. |
| `CLAUDE.md` (1075 lines) | Repo rules + module reference; lines 674–760 document the **Learn Domain four-layer architecture** and all six substrate crates with exact ports/versions; lines 287–299 document the repo tree including `substrate/`. |
| `AGENTS.md` | Behavioral rules: mandatory progress signaling, mandatory memory protocol (surreal-memory MCP → Cortex MCP → file fallback), subagent dispatch rules, Rust/clap conventions, skill authoring rules (`argument-hint`, `npm run validate:strict`, executable scripts), surreal-memory tool reference. |
| `AGENT_BASE_RULES.md` | 40 Prometheus Base Rules (also copied into scaffolded projects by the hybrid-mobile-architecture repo). |
| `docs/deployment-modes.md` | **Four progressive capability tiers**: Mode 0 CLI → Mode 1 MCP (surreal-memory + sycophancy) → Mode 2 Full (+surface-bridge, +learner-model) → Mode 3 P2P (+sovereign-sync CRDT replication, iroh QUIC transport, AG-UI SSE). This is the pack's own local-first maturity ladder. |
| `docs/SOVEREIGN_SYNC_TESTING.md` | Two-node P2P validation guide (Docker Compose or two hosts) for `sovereign-sync`. |

---

## 2. Substrate crates (the crown jewels for local-first sync)

All under `/Users/gqadonis/Projects/prometheus/prometheus-skill-pack/substrate/`. CLAUDE.md describes these as "Layer A — Substrate" of the learn domain, but they are generic local-first infrastructure.

### 2.1 `storage-provider` — storage + CRDT abstraction layer

Path: `substrate/storage-provider/` (`Cargo.toml`: `loro = "1.13"`, `iroh = "1.0"`, `iroh-blobs = "0.103"`, `iroh-docs = "0.101"`, `iroh-gossip = "0.101"`, `blake3`, `async-trait`, `tokio`).

Two core traits in `src/traits.rs`:

```rust
#[async_trait]
pub trait StorageProvider: Send + Sync {
    async fn read(&self, key: &str) -> Result<Option<Vec<u8>>>;
    async fn write(&self, key: &str, value: Vec<u8>) -> Result<()>;
    async fn delete(&self, key: &str) -> Result<()>;
    async fn list_keys(&self, prefix: &str) -> Result<Vec<String>>;
    fn backend_name(&self) -> &'static str;
}

pub trait CrdtEngine: Send + Sync {
    fn new_doc(&self) -> Vec<u8>;
    fn merge(&self, local: &[u8], remote_delta: &[u8]) -> Result<Vec<u8>>;
    fn apply_json(&self, doc: &[u8], patch: serde_json::Value) -> Result<(Vec<u8>, Vec<u8>)>;
    fn to_json(&self, doc: &[u8]) -> Result<serde_json::Value>;
    fn engine_name(&self) -> &'static str;
}
```

Implementations (`src/lib.rs` re-exports):

- **`LocalDirAdapter`** (`src/local_dir.rs`) — default filesystem backend.
- **`LoroAdapter`** (`src/loro_adapter.rs`) — real Loro 1.13 CRDT engine. `merge()` imports deltas via `LoroDoc::import`; `apply_json()` writes JSON into the `root` LoroMap (nested objects→LoroMap, arrays→LoroList) and exports `ExportMode::Updates { from: vv_before }` deltas; `to_json()` reads `root.get_deep_value()`. Engine name `"loro-1.13"`.
- **`IrohDocsAdapter`** (`src/iroh_docs.rs`, 637 lines, fully implemented + tested) — iroh-docs 0.101 backend: owns an iroh `Endpoint` (`presets::Minimal`), `MemStore`/`FsStore` blob store, `Gossip`, `Docs` protocol, default `AuthorId`, one namespace. Storage ops map to `Doc::set_bytes/del/get_many` with `Query::single_latest_per_key`. **Multi-node sync via native iroh-docs ticket flow**: `share_read_ticket()`/`share_write_ticket()` (with `AddrInfoOptions::RelayAndAddresses`), import via `memory_from_ticket`/`persistent_from_ticket`, plus `start_sync(peers)`, `leave_sync()`, `namespace_id()`, `endpoint_addr()`. Tests prove live two-node bidirectional sync through write tickets (10 s retry window).
- **`SyncManifest` + `SyncDomain` + `DomainConfig` + `PrivacyClass`** (`src/sync_manifest.rs`) — **the privacy-gated sync registry**. `PrivacyClass::{Public, Trusted, Local}` — `Local` is "never leaves the local device — structurally excluded from P2P sync". `DomainConfig::new()` *requires* a privacy decision (no default). `SyncManifest::is_syncable()` returns true only for `Public`/`Trusted`. Doc comment: "A sync transport is expected to consult this manifest before gossiping any CRDT delta… enforcing it at the transport layer is the caller's responsibility."

**How it works:** bytes-typed KV storage is abstracted from backends; CRDT documents are opaque byte blobs to storage; Loro handles merge semantics; iroh-docs provides signed replica logs + blob storage + gossip-based live sync; the manifest decides what may be replicated.

### 2.2 `sovereign-sync` — P2P CRDT sync daemon / MCP server / REST API

Path: `substrate/sovereign-sync/` (bin + lib). Description in Cargo.toml: "P2P CRDT sync daemon, MCP server, and REST API for prometheus-skill-pack".

Dependencies (`Cargo.toml`): `loro = "1.13"`, `iroh = "1.0"` (comment: *"iroh 1.0.0 stable — released June 15, 2026"*), `iroh-gossip = "0.101"`, `rmcp = "1.8"` (official `modelcontextprotocol/rust-sdk`, features `server, client, transport-io, transport-child-process, macros`), `redb = "2"`, `axum = "0.8"`, `tower-http cors`, `clap 4`, `storage-provider` (path dep), `dirs-next`, `tracing`.

CLI (`src/main.rs`): `sovereign-sync --mode mcp|daemon|server|status`, `--port` (default **7892**), `--config` (default `~/.config/sovereign-sync/config.toml`), `--prefix-tools` (prefixes MCP tools with `sovereign:` to avoid UAR/BossFang collisions). Detects `UAR_SKILL_SERVICE_URL` for passthrough mode.

Modules:

- **`p2p.rs`** — `P2PNode` with a 5-state FSM (`Disconnected → Bootstrapping → Connected → Syncing → Idle`). iroh `Endpoint::builder(presets::N0)` (pkarr DNS discovery + relay mode). Gossip topic derived deterministically: `blake3(operator_id ‖ "sovereign-sync-v1")` → `TopicId` — all nodes sharing an `operator_id` form one sync group. `start(bootstrap_peers)` subscribes/joins; `broadcast(payload)` gossips CRDT deltas; `add_peers()` for out-of-band discovery. Comment notes the **privacy gate is enforced upstream in `crdt.rs`** before bytes reach gossip.
- **`crdt.rs`** — per-domain `HashMap<SyncDomain, LoroDoc>`; `apply_incoming_delta()` and `export_outgoing_delta()` both call `manifest.is_syncable()` first and return `SyncError::PrivacyViolation` for non-syncable domains (the "KB content invariant"); export uses `ExportMode::Updates{from: vv}` when a version vector is supplied, else full snapshot; `current_version()` serializes `doc.oplog_vv()` to JSON.
- **`store.rs`** — `redb` persistence with three tables: `peers` (endpoint_id→JSON), `versions` (domain→version-vector JSON), `sessions`; default path `<data_local_dir>/sovereign-sync/state.redb`.
- **`mcp_server.rs`** — rmcp 1.8 stdio server `SovereignMcpServer` with 4 tools: `search-skills`, `sync-status`, `sync-push`, `sync-peers`. `SkillIndex` = keyword-only (no embeddings, no external calls, privacy-safe) loader that scans a skills dir for `SKILL.md` frontmatter (`name:`, `description:`), builds keyword tokens, ranks by token-hit count. **Only `search-skills` is fully implemented; the three sync tools return stub strings** referencing "change-sync-010/014/015".
- **`rest_api.rs`** — Axum router: `GET /health`, `GET /api/v1/skills/search?q=`, `GET /api/v1/sync/status`, `GET /api/v1/sync/peers`, `POST /api/v1/sync/push {domain}`, `POST /api/v1/stream` (AG-UI SSE), `GET /api/v1/stream/ping`. **Sync endpoints are hardcoded stubs** ("Full CRDT push wired in change-sync-015"); status shows domains `kbd-orchestrator`, `open-spec`, `surreal-memory` (marked `local_only`), `learner-model`.
- **`ag_ui.rs`** — AG-UI/A2UI SSE endpoint. A2UI task enum `SyncTaskKind::{SyncPush, PeerStatus, SkillSearch, NodeRelay}`; `A2uiTask{task_id, kind, payload}`; `AgUiEvent` tagged enum (`task_accepted`, `progress`, …).
- **`config.rs`** — TOML config: `NodeConfig{skills_dir (default ~/.claude/skills), operator_id}`, `PeersConfig{bootstrap: []}`, `ServerConfig{port 7892}`.
- Service install: `com.prometheusags.sovereign-sync.plist` launchd template; integration tests in `tests/integration_tests.rs`.

### 2.3 `sovereign-client` — Rust SDK for the sync node

Path: `substrate/sovereign-client/`. Deps: `reqwest 0.12 (json, stream)`, `eventsource-stream 0.2`, `tokio-stream`. `SovereignClient::new(base_url)` → typed methods `health()`, `search_skills(q, limit)`, `sync_status()`, `sync_push(domain)`, and `stream_task(task) -> Stream<Item = Result<AgUiEvent>>` for the AG-UI SSE stream. This is the intended embed point for Tauri/web clients (CLAUDE.md: "AG-UI SSE endpoint for Tauri/web clients").

### 2.4 `surface-bridge` — Tier-2 MCP App server (A2UI HTML shell)

Path: `substrate/surface-bridge/` (`README.md` + `src/{main,handlers,types}.rs`). Axum on **127.0.0.1:7890**. Endpoints: `GET /health`, `POST /mcp/detect-surface-tier` (returns `SURFACE_TIER` + `CLAUDE_HARNESS` env), `POST /mcp/render-ui-intent` (queues a `UiIntent` for the HTML shell), `POST /mcp/collect-response` (polls operator input). **Explicitly a Tier-2 stub** — the iframe/AG-UI display layer is "deferred to a future phase". Installed as launchd/systemd-user service (`shared/launchagents/ai.prometheus.surface-bridge.plist`, `shared/systemd/ai.prometheus.surface-bridge.service`).

The tier contract it implements (CLAUDE.md §"Surface Tier Degradation Contract"): Tier 0 plain text → Tier 1 `AskUserQuestion` or file-pair (`__ui_intent__.json`/`__ui_response__.json`) → Tier 2 MCP App iframe via surface-bridge. Skills never render directly; they emit a `UiIntent` to `skills/learn/ui-surface`, which resolves the tier via `detect-surface-tier.sh`.

### 2.5 `learner-model` — CRDT learner state runtime (reference consumer of the substrate)

Path: `substrate/learner-model/`. Depends on `storage-provider` (path). Modules: `types.rs` (domain types mirroring `docs/learn/schemas/learner-model.schema.json`: `LearnerModel`, `ConceptState`, `FSRSCard`, `CardState`, `GapRecord`, `MasteryPrior`, `ObservationRecord`…), `store.rs` (`LearnerModelStore` — typed CRDT-backed store over `StorageProvider`), `survey.rs` (cold-start `seed_from_survey`), `fsrs.rs` (FSRS-6 scheduler stub, `next_review`, `Rating`). PFA mastery update rule: `mastery_new = mastery_old + 0.3 × (score − mastery_old)` at ≥5 observations. JSON-RPC stdin/stdout interface. **This is the proof-of-pattern for domain-state-as-CRDT-document over the StorageProvider abstraction** — the same shape the master goal wants for settings schemas and synced client/server storage.

### 2.6 `prometheus-research` — background research daemon with A2UI component registry

Path: `substrate/prometheus-research/` (v1.6.0 per CLAUDE.md). Axum HTTP on **127.0.0.1:7891**; rmcp 1.8 MCP server with 5 tools (`research_start/status/cancel/export`, `render_component`); `pulldown-cmark` markdown rendering; `reqwest` client to emit to surface-bridge; launchd `com.prometheus.research.plist`.

- `src/a2ui/registry.rs` — **`ComponentRegistry`: HashMap<&'static str, fn(Value) -> String>** rendering 8 server-side HTMX components: `graph_view`, `source_list`, `contradiction_panel`, `progress_ring`, `media_card`, `stage_timeline`, `markdown_viewer`, `citation_list` (`src/a2ui/components/*.rs`). Unknown components render an `hx-swap-oob` fallback div.
- `src/agui/emit.rs` — maps `AguiEvent::{AgentStatus, AgentMessage, AgentError, A2uiComponent…}` → `UiIntent{intent_type, title, body, options, multiselect, request_id}` posted to surface-bridge.
- `src/http_server/{rest,sse,health}.rs`, `src/job/{spawn,cancel,checkpoint}.rs` (job lifecycle + checkpointing), `src/static/` vendors **htmx.min.js, htmx-ext-sse.js, htmx-ext-loading-states.js, alpine.min.js (3.14.8), hls.min.js** + brand assets.
- Tests: `tests/{job_lifecycle,mcp_tools,sse_stream}.rs`.

**This is the pack's working prototype of the "A2UI/AG-UI/HTMX UI modules" pillar of the master goal** — server-rendered HTML fragments streamed over SSE into an HTMX shell.

---

## 3. Skills inventory by category (with deep-dives)

Skill structure today (uniform): `skills/<category>/<skill-name>/` containing `SKILL.md` (YAML frontmatter: `name`, `description`, `version`, `license`, `allowed-tools`, `model_routing` (phases→model class via liter-llm-bridge), `triggers.keywords/semantic`, `metadata.tags`), `skill.toml` (declares Tera templates for forge-rs), `templates/*.tera`, `scripts/`, `references/`, optional nested `skills/<child>/`. Validation: `scripts/validate-skills.js` (`npm run validate`, `validate:strict`). Distribution: flat **copies** into per-harness dirs (`~/.claude/skills`, `~/.codex/skills`, `~/.kimi-code/skills`, `.opencode/skills`, …) via `scripts/install-skills-flat.sh` / `scripts/install-platforms.ts`; slash commands registered for *every* skill via `scripts/register-slash-commands.sh`.

### 3.1 `skills/flint/` — Flint Realtime Fabric SDK skills (6 languages)

Six skills: `flint-sdk-ts`, `flint-sdk-dart`, `flint-sdk-go`, `flint-sdk-kotlin`, `flint-sdk-swift`, `flint-sdk-csharp`.

- **`flint-sdk-ts`**: npm package **`@prometheusags/frf-sdk`**; exports `SpineClient`, `SpineService`, `EventKind` (`DATA/SYSTEM/HEARTBEAT`), `EventEnvelope`, `SubscribeRequest`, `PublishRequest/Response`, `AckRequest/Response`, `Channel`, `Cursor`, `Offset`. Transport: Connect-RPC (`@connectrpc/connect` + `@connectrpc/connect-web`). Pattern: `client.subscribe({channel})` → async-iterable stream → `client.ack({cursor})` per event; `client.publish({channel, payload})`.
- **`flint-sdk-dart`**: package **`frf_dart`**, generated from the Rust core via **flutter_rust_bridge 2.11.1** (`bash sdks/dart/build_dart.sh` in flint-realtime-fabric); requires Dart ≥3.3 <4.0, Flutter 3.19+; same `SpineClient` subscribe/publish/ack surface. Source path: `/Users/gqadonis/Projects/prometheus/flint-realtime-fabric/sdks/dart/`.

This is the client-side on-ramp to the central realtime fabric in the master goal — the pack already teaches agents how to wire FRF into TS and Flutter apps.

### 3.2 `skills/react/` — entity management incl. local-first sync

- **`react-vite-stack`**: React 19 + Vite 8 + TanStack + Zustand 5 + shadcn/ui; Tera templates `page_component.tsx`, `feature_hook.ts`, `store.ts`, `api_client.ts`, `entity_hook.ts`. Enforces Component → Hook → Store → API.
- **`prometheus-entity-skills`**: 6 top sub-skills + nested children around **`@prometheus-ags/prometheus-entity-management`** (also present as a git submodule at `skills/imported/prometheus-entity-management`). Sub-skills: `entity-graph-setup`, `entity-graph-crud`, `entity-graph-graphql`, `entity-graph-prisma`, `entity-graph-realtime`, `entity-graph-optimize`, plus **`entity-realtime-surreal-live`**.
  - **`entity-graph-realtime/skills/entity-realtime-local-first/SKILL.md`** — **the most master-goal-relevant skill in the pack.** Wires **ElectricSQL shape streams + PGlite** via `createElectricAdapter({pglite, tables, onSynced?}) → SyncAdapter`; `ElectricTableConfig{type, table, where, idColumn, normalize, shapeStream}`; `ShapeStream.subscribe(msgs, onErr)`, `isUpToDate`, `lastOffset`; adapter maps `ShapeMessage → EntityChange (insert/upsert/delete)`; `SyncAdapter` extras `query/execute/isSynced()/onSyncComplete(cb)`; React helpers `useLocalFirst`, `usePGliteQuery`. Tested API surface: `@electric-sql/pglite ^0.2`, `@electric-sql/client ^0.6`. Architecture note in the skill: "Server authority remains Postgres; Electric replicates allowed shapes into local PGlite" — exactly the pglite↔central-postgres pattern.
  - **`entity-realtime-surreal-live/SKILL.md`** — SurrealDB `LIVE SELECT` subscriptions via `createSurrealLiveAdapter`; select-then-live seeding vs live-only; CREATE/UPDATE/DELETE→`EntityChange` mapping; reconnect with exponential backoff; optional `checkpointResume` replay. A second adapter pattern for live sync into the same entity graph.

### 3.3 `skills/rust/` (10 skills)

`axum-patterns` (Axum 0.8, 5 Tera templates), `error-handling`, `async-patterns`, `workspace-structure`, **`mcp-server`** (canonical Prometheus MCP pattern: JSON-RPC 2.0 over `POST /mcp` + SSE `GET /events`, or stdio; structure `server.rs/tools.rs/events.rs/stdio.rs`), `actor-model`, `performance`, `karpathy-tokenizer`, **`librefang-wasm-skill`** (see §5.3), `prometheus-rust-auditor` (audit pipeline orchestrated by `agents/rust-auditor.md`).

### 3.4 `skills/flutter/` — `flutter-rust-ffi`

flutter_rust_bridge v2 + Riverpod 2.6/3.x + GoRouter; shared `gen_ui_core` crate layout (`inference.rs`, `mcp.rs`, `memory.rs`, `agent.rs` — SurrealDB/surreal-memory client, MCP over reqwest/SSE, UAR job streaming); templates `riverpod_notifier.dart`, `feature_repository.dart`, `go_router_config.dart`. Matches TJ-ARCH-MOB-001 layering (Widget → Riverpod → Repository → Rust FFI).

### 3.5 `skills/tauri/` — `tauri-react-vite`

Tauri 2 + React 19 + Vite 8; `#[tauri::command]` modules (`commands/inference.rs`, `commands/storage.rs`), typed `invoke()` wrappers, `tauri::State` DI; documents **gen_ui_core sharing between Tauri backend and flutter_rust_bridge**, Flutter WebView embedding in Tauri.

### 3.6 `skills/htmx/` — `htmx-alpine-lit`

HTMX 2.0.8 + Alpine.js 3.x + Lit 3.x + Tailwind 4. "Server-driven: the server returns HTML fragments, not JSON"; Alpine for local state; Lit for encapsulated widgets; `HtmxIsland` pattern embeds HTMX islands inside React 19 hosts. Templates: `page.html.tera`, `lit_component.ts.tera`, `react_island.tsx.tera`, `axum_fragment_handler.rs.tera`. Pairs directly with `prometheus-research`'s A2UI ComponentRegistry.

### 3.7 `skills/architecture/` — `clean-architecture`

Four-layer CLEAN model (Domain → Application → Infrastructure → Interface) mapped to Rust crates, Flutter features, React slices, Go packages. Same doctrine as the hybrid repo's feature-based clean architecture.

### 3.8 `skills/research/` — `deep-research`

10-stage pipeline (Planner → Search → Retrieve → Collect → Verify → Resolve → Graph → Cite → Report → Export) producing persistent **`.research` packages (OKF-aligned knowledge assets)** with citations, confidence scores, knowledge graphs, contradiction tracking. Frontmatter declares `allowed-tools: file_system web_search code_interpreter sequential_thinking memory browser tavily firecrawl` and per-phase `model_routing` via liter-llm-bridge. Integrations: surreal-memory (graph persistence), sycophancy-correction, learn-grade (Feynman gate), pmpo-elicit. Contains its own `agents/`, `hooks/`, `references/`, `scripts/`, `templates/`, sub-skills. Runtime counterpart: `substrate/prometheus-research`.

### 3.9 `skills/learn/` (16 skills)

Feynman-Spine learning arc: `learn-goal`, `learn-survey`, `learn-plan`, `feynman-loop`, `learn-grade` (external sycophancy-corrected grader), `learn-retain` (FSRS), `learn-practice`, `learn-certify` (**OB 3.0 / W3C VC credential issuance**), `learn-kb` (KB adapters `dify:` / `palace:` / `local:` / `web:` — with the rule that KB content never goes to external APIs), `learn-about-system`, `learn-harness`, `ui-surface` (tier resolver), and the sync trio:

- **`sync-status`**, **`sync-peers`**, **`sync-push`** — thin skill wrappers over the sovereign-sync REST API (`curl http://127.0.0.1:7892/api/v1/sync/...`). `sync-push/SKILL.md` documents the domain table: `skill-index` (Shareable), `learner-model` (Shareable), **`surreal-memory` = LocalOnly, never synced, "enforced structurally in SyncManifest via PrivacyClass::LocalOnly"**. Push uses "Loro 1.13 CRDT snapshot + delta export so only changed operations are transmitted."

### 3.10 `skills/process/` (14 skills)

PMPO/KBD orchestration: `zeespec-interrogator` (Layer 1), `iterative-evolver`, `pmpo-evolver` (Layer 2), `kbd-process-orchestrator` (16–18 child skills), `pmpo-outer-loop`, `pmpo-elicit` (human escalation primitive with provenance, async pause/resume), **`pmpo-skill-creator`** (creates/clones/extends/validates skills; human-gated `--update`), `kbd-goal`/`kbd-goal-check`, `kbd-evolve`, `ideation-mindmap`, `liter-llm-bridge`, `cowork-management`, and **`native-agent`** (see §5.1).

### 3.11 Other categories

`devops/` (GitOps: `argocd-multicloud`, `gitops-bootstrap`, `gitops-transform`, `kustomize-overlay`, `disk-space-guardian`), `testing/` (BDD: `bdd-testing`, `bdd-cucumber-js/rs`, `bdd-lifecycle-loop`, `bdd-video-proof`), `documentation/` (`llm-wiki`), `document-extraction/` (`kreuzberg`), `typescript/`, `go/`, `python/` (`pyo3-bridge`), `imported/` (submodules: `artifact-refiner`, `sycophancy-correction`, `prometheus-entity-management`).

---

## 4. agents/, hooks/, config/, policies/

### 4.1 `agents/` (6 definitions, markdown with frontmatter)

- `gitops-architect.md` — orchestrates the 4 GitOps skills; enforces TJ-CICD-001; plan-then-approve-then-delegate.
- `kbd-goal-evaluator.md` — read-only PASS/FAIL goal evaluator (`model: claude-haiku-4-5-20251001`; tools restricted to `Read`, `Bash(cat|jq|grep|ls)`). Separation-of-grading pattern: "the builder agent that wrote the code never grades whether the goal is met".
- `kbd-idea-critic.md` — adversarial ideation critic, 4-dimension rubric (`model: claude-sonnet-4-6`).
- `kbd-spec-reviewer.md` — adversarial SPEC.md reviewer; every acceptance criterion must be machine-verifiable.
- `kbd-task-verifier.md` — read-only task verifier (haiku).
- `rust-auditor.md` — orchestrates the `prometheus-rust-auditor` pipeline (Clippy, fmt, deps, inventory, partition, CI gen).

Pattern worth reusing: **verifier/critic agents are separate, cheaper or stronger models with read-only tool allowlists** — bias control by construction.

### 4.2 `hooks/hooks.json`

Six lifecycle events wired: `SessionStart` (`kbd-open` context priming; `detect-project-context.sh`; `memory-outbox-flush.sh`; `pk-health.sh`), `UserPromptSubmit` (`pk-focus-on-prompt.sh`, `position-on-prompt.sh`), `PreToolUse` (Bash: `guard-direct-deploy.sh`, `pipeline-enforce.sh`; Write|Edit: **`cedar-skill-gate.sh`**, `protect-tests.sh`, `scope-guard.sh`, `check-child-scope.sh`), `PostToolUse` (state validation, gitops-write validation, scope-record, sycophancy-check-artifact, `memory-writeback.sh`), `SubagentStop` (per-phase matchers: assessor/analyst/planner/executor/reflector → state-checkpoint + workflow-dispatch; reflector also runs `sycophancy-check-reflection.sh`), `Stop` (session summary, `forge-reflect-on-stop.sh`, **`propose-skill-update.sh`** — the self-learning write path), `PreCompact` (`kbd-close`).

### 4.3 `config/`

Only `codex-catalog.txt` — Codex skill-catalog budget management: Codex renders all discoverable skills into a fixed-size "## Skills" section (~130 skills→166-char descriptions; ~360→10 chars, "useless"). The catalog selects which skills get auto-trigger descriptions; excluded skills remain invocable via registered slash commands. Directly relevant to **skill distribution at scale** — flat-name auto-discovery does not scale past ~200 skills on constrained harnesses.

### 4.4 `policies/`

`skill-mutation.cedar` — Cedar policy set governing the self-learning pipeline's writes: default-deny; dev permits all; staging requires `validation_passed` for `skill.mutate`, `human_approved && test_pass_rate ≥ 95` for `skill.promote`, `AgentGroup::"generators"` for `skill.generate`; production forbids all mutations; **vertical overlays**: healthcare requires `audit_trail_id`, financial requires `dual_approval`. Plus `entities.json`, `README.md`. Enforcement point: `shared/scripts/cedar-skill-gate.sh` (PreToolUse) + `tools/prometheus-cli`.

---

## 5. Capability analysis against the master goal pillars

### 5.1 Agent harness skills

**`skills/process/native-agent/`** generates complete Rust agent workspaces (`/create-native-agent`): workspace crates `agent-core` (pure domain), `agent-skills` (**TF-IDF skill discovery + hot-reload from configured skill dirs**), `agent-mcp` (JSON-RPC 2.0 MCP client), Axum server with **A2A** (`GET /.well-known/agent.json`, `POST /a2a/tasks`), **AG-UI** (SSE `/agui/events/:run_id`, `agui.*` events, CopilotKit-compatible), **A2UI** (`/a2ui/session`, "Prometheus combined protocol"), OpenAI-compatible `/api/chat`, React 19 `assistant-ui` frontend, liter-llm provider routing, `agent.toml` config, hot-reloadable `system_prompt.md`, Docker packaging, Supabase-style management CLI (`start/stop/status/logs/mcp add/skills list/providers`). Protocol spec: `skills/process/native-agent/references/protocols.md`. Generated agents network via mutual A2A endpoints. Per-phase model routing declared in frontmatter (`agent-specify: frontier`, `agent-generate: tiered`, …).

Plus the PMPO/KBD process skills, the 8-server MCP substrate (surreal-memory :23001, prometheus-knowledge :8942, forge-rs :8943, sycophancy-correction, liter-llm, sequential-thinking, tavily, firecrawl), and lifecycle hooks — a complete "harness skill" stack.

### 5.2 Skill authoring & packaging today

- Authoring: `SKILL.md` + `skill.toml` + Tera templates; `forge template new skill <lang> <name>` scaffolds; `pmpo-skill-creator` generates skills via PMPO with human gate; validation `npm run validate:strict`; `docs/SKILL_TEMPLATE.md`, `examples/example-skill/`.
- Distribution: **git repo + git submodules + flat-file copy installers** (`install-skills-flat.sh`, `install-platforms.ts`), npm wrapper scripts, `.claude-plugin/plugin.json` + `scripts/build-marketplace.js` (Claude marketplace), `scripts/register-slash-commands.sh` for non-catalog harnesses. Self-mutation flows through Cedar-gated `propose-skill-update.sh`.
- **No decentralized/content-addressed packaging exists.** The closest building blocks in-repo: `iroh-blobs` content-addressed store inside `IrohDocsAdapter`, and blake3 hashing in sovereign-sync. IPFS appears nowhere in this repo.

### 5.3 WASM component skills

**`skills/rust/librefang-wasm-skill/`** — generates a `cdylib` crate targeting `wasm32-unknown-unknown` implementing the **LibreFang WASM Guest ABI** (from `librefang-runtime-wasm/src/sandbox.rs`): required exports `memory`, `alloc`, `execute`; a `host_call` bridge wrapping capability-checked host functions `fs_*`, `net_fetch`, `kv_*`, `agent_*`, `time_now`, `env_read`, `shell_exec`; plus a `skill.toml` matching the `SkillManifest` schema (`runtime.type = "wasm"`, declared capabilities + tool surface). Packaging path: `forge package-librefang` + `/upload-to-bossfang`. **This is a raw non-WIT ABI** — flint-forge's WIT component model is a different, newer contract; convergence is an open design decision.

### 5.4 Sync & local-first stack summary (how it works today)

```
skills/learn/sync-*  ──curl──▶  sovereign-sync REST :7892 ──┐
                                     │                       │
   MCP stdio tools (rmcp 1.8) ◀──────┤                       │
                                     ▼                       ▼
                          crdt.rs (Loro 1.13 per-domain docs,
                          SyncManifest privacy gate)     p2p.rs (iroh 1.0 N0
                                     │                       preset, iroh-gossip
                          store.rs (redb: peers/versions/    topic = blake3(operator_id
                          sessions)                                ‖ "sovereign-sync-v1"))
                                     │
   learner-model ──▶ storage-provider traits (StorageProvider/CrdtEngine)
                     ├─ LocalDirAdapter (default)
                     ├─ LoroAdapter (real CRDT merges)
                     └─ IrohDocsAdapter (iroh-docs 0.101 ticket-based live sync — fully working, tested)
```

---

## 6. Implications for the master goal

1. **A working CRDT+privacy substrate already exists and should be reused, not redesigned.** `storage-provider`'s `StorageProvider`/`CrdtEngine` traits and `SyncManifest` privacy classes are exactly the abstraction the master goal needs for "settings schemas with synced client/server storage" — register a domain per settings schema (`settings:<name>`), class it, sync it. The learner-model crate is the reference consumer proving the pattern end-to-end.
2. **Two sync transports exist in-pack and answer different halves of the goal.** (a) `IrohDocsAdapter` (iroh-docs tickets) = mature device-to-device P2P replication; (b) `sovereign-sync` gossip = operator-scoped sync groups. Neither is the flint-realtime-fabric↔postgres path — FRF integration comes via the `flint-sdk-*` skills (`SpineClient`, channels, cursor/ack). The architecture must decide whether flint-realtime-fabric becomes a third `StorageProvider` backend (likely yes: `FlintAdapter` implementing `StorageProvider` over FRF channels) or replaces sovereign-sync wholesale.
3. **PGlite local-first is already the sanctioned React pattern.** `entity-realtime-local-first` (ElectricSQL shapes → PGlite → entity graph) aligns with the master goal's "pglite (web) clients sync to central postgres". pglite-oxide (Tauri side) has no skill here — it lives in the hybrid repo's docs (`docs/pglite-oxide-tauri-hybrid.md`). A symmetric Tauri skill is a gap to author.
4. **A2UI/AG-UI/HTMX modules have a working prototype** (`prometheus-research` ComponentRegistry + agui emit + surface-bridge UiIntent queue + native-agent `/a2ui/session`). The ComponentRegistry-as-a-service pattern (server-rendered HTMX fragments by name+props) maps naturally onto a WASM-component UI module registry; flint-forge's A2UI registry should adopt or replace `ComponentRegistry`.
5. **Skill packaging must evolve past git+copy.** Today's distribution (submodules, flat copies, marketplace JSON) cannot express signed, content-addressed, decentralized artifacts. The repo already depends on iroh-blobs (content-addressed) and blake3 — an IPFS/iroh-blobs-based skill artifact store is a natural extension; the `SkillManifest`/`skill.toml` schema from librefang-wasm-skill is the seed of a package manifest. Cedar policies (`skill.mutate/promote/generate`, healthcare/financial overlays) are the governance layer such a store needs.
6. **The verifier-agent + hooks + Cedar governance pattern is directly reusable** for cloud-hosted agents cooperating with client agents: separated grading agents, lifecycle hooks as policy enforcement points, Cedar as the cross-cutting authorization DSL.
7. **Codex-catalog lesson**: flat skill auto-discovery degrades beyond ~200 skills — a registry with namespacing/search (like `SkillIndex` keyword search in sovereign-sync, or surreal-memory semantic search) is mandatory at KnowMe scale.

## 7. Gaps / risks

| # | Gap / risk | Evidence |
|---|---|---|
| G1 | **sovereign-sync sync path is partially stubbed.** MCP tools `sync-status/sync-push/sync-peers` return placeholder strings ("wired in change-sync-010/014/015"); REST `/api/v1/sync/status|peers|push` hardcoded. The p2p/crdt/store modules are real, but the daemon does not yet wire gossip broadcast ↔ Loro delta exchange ↔ redb version tracking end-to-end. | `substrate/sovereign-sync/src/mcp_server.rs:223-255`, `rest_api.rs:92-125` |
| G2 | **Privacy-class naming drift**: code has `PrivacyClass::{Public,Trusted,Local}`; skills/comments say `LocalOnly`; REST stub uses `sync_encrypted_only`/`local_only`. Reconcile before building on it. | `storage-provider/src/sync_manifest.rs:11-18` vs `sync-push/SKILL.md`, `rest_api.rs:97-102` |
| G3 | **No WebRTC transport.** iroh 1.0 is QUIC + relays + hole-punching (native). Browser/web pglite clients cannot join iroh gossip; a WebRTC data-channel transport (or FRF as the web bridge) is required for the master goal's "CRDT sync over WebRTC". lora-rs appears nowhere in this repo. | `substrate/sovereign-sync/src/p2p.rs` (N0 preset) |
| G4 | **Two WASM skill ABIs will collide**: librefang Guest ABI (raw exports, non-WIT) vs flint-forge WIT component model. Pick WIT/components for new work; treat librefang ABI as legacy. | `skills/rust/librefang-wasm-skill/SKILL.md` |
| G5 | **No decentralized packaging/distribution**: git submodules + flat copies only; no signing, no content addressing of skill artifacts, no IPFS/OCI store (flint-forge's extension registry has IPFS/OCI/S3 — fill from there). | `.gitmodules`, `scripts/install-skills-flat.sh` |
| G6 | **iroh-docs adapter is single-namespace, single-author-default**; multi-domain sharding across namespaces (per SyncDomain) not yet modeled; tombstones/deletes semantics via `Doc::del` only. | `storage-provider/src/iroh_docs.rs` |
| G7 | **Storage layer is bytes-only KV** — no query/index layer; any postgres/pglite bridging (CDC → CRDT or shape → CRDT) is unbuilt. FRF's postgres CDC (in flint-realtime-fabric) has no counterpart adapter here. | `storage-provider/src/traits.rs` |
| G8 | **surface-bridge Tier-2 UI is a stub** (acknowledges intents; no iframe/AG-UI renderer); the HTML shell that displays A2UI output is "deferred to a future phase". | `substrate/surface-bridge/README.md` |
| G9 | ElectricSQL/PGlite adapter versions pinned to `@electric-sql/pglite ^0.2`, `client ^0.6` — Electric's shape API is pre-1.0 and has shifted; reverify before committing. | `entity-realtime-local-first/SKILL.md` |
| G10 | Single-maintainer bus factor + no external production deployments (self-reported 92% readiness); surreal-memory runs in Docker only — a mobile/edge deployment would need an embedded alternative. | `README.md:16` |

---

## 8. Quick reference — key paths

| What | Path |
|---|---|
| Storage/CRDT traits | `substrate/storage-provider/src/traits.rs` |
| Privacy manifest | `substrate/storage-provider/src/sync_manifest.rs` |
| iroh-docs P2P storage | `substrate/storage-provider/src/iroh_docs.rs` |
| Loro CRDT engine | `substrate/storage-provider/src/loro_adapter.rs` |
| Sync daemon | `substrate/sovereign-sync/src/{main,p2p,crdt,store,mcp_server,rest_api,ag_ui}.rs` |
| Client SDK | `substrate/sovereign-client/src/client.rs` |
| A2UI component registry | `substrate/prometheus-research/src/a2ui/registry.rs` |
| UI intent bridge | `substrate/surface-bridge/src/handlers.rs`, `skills/learn/ui-surface/` |
| FRF SDK skills | `skills/flint/flint-sdk-{ts,dart,go,kotlin,swift,csharp}/SKILL.md` |
| PGlite local-first skill | `skills/react/prometheus-entity-skills/entity-graph-realtime/skills/entity-realtime-local-first/SKILL.md` |
| Agent generator | `skills/process/native-agent/` (+ `references/protocols.md`) |
| WASM skill ABI | `skills/rust/librefang-wasm-skill/SKILL.md` |
| Cedar governance | `policies/skill-mutation.cedar`, `shared/scripts/cedar-skill-gate.sh` |
| Lifecycle hooks | `hooks/hooks.json` |
| Deployment tiers | `docs/deployment-modes.md` |
| Sync validation guide | `docs/SOVEREIGN_SYNC_TESTING.md` |
