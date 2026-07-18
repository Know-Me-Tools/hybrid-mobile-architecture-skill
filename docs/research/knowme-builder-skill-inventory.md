# KnowMe Builder Skill Package — Complete Capability Inventory & Extension-Point Map

> Research brief: `knowme-builder-skill-inventory` · Author: KNOWME_RESEARCHER · Date: 2026-07-18
> Repo mapped: `/Users/gqadonis/Projects/hybrid-mobile-architecture-src` (agentskills.io skill package, standard **TJ-ARCH-MOB-001**, v1.0.0)
> Lens: local-first + realtime architecture — pglite/pglite-oxide clients syncing through flint-realtime-fabric to central postgres (flint-forge); cooperating client/cloud agents; WASM component model for skills/UI/settings; CRDT sync over WebRTC (+ lora-rs); decentralized packaging (IPFS / git-like Rust versioning).

---

## PART 1 — WHAT EXISTS (FACTS)

### 1.1 Repo identity and packaging surfaces

The repo is a **skill package, not an application** (AGENTS.md, CLAUDE.md §"What this repository is"). Its outputs are scaffolding scripts, reference docs, and templates. It ships itself through multiple distribution/metadata surfaces:

- `SKILL.md` — agentskills.io frontmatter (`name: hybrid-mobile-architecture`, v1.0.0, author Travis James / Prometheus AGS / KnowMe, LLC); trigger terms include gen_ui, hybrid app, flutter rust, tauri react, riverpod, zustand, prometheus entity management, universal agent runtime, A2UI, AG-UI, MCP mobile, on-device inference.
- `plugin.json` + `marketplace.json` — legacy catalog metadata.
- `.claude-plugin/` (plugin.json + marketplace.json) — Claude Code plugin/marketplace listing.
- `.agents/plugins/` — Codex plugin marketplace listing.
- `site/` + `dist/` + `docs/global-harness-installation.md` — a Docusaurus documentation site (public docs at `https://know-me-tools.github.io/hybrid-mobile-architecture-skill/` per README).
- `versions.toml` — **single source of truth for all version pins**, enforced by `scripts/audit.sh doc-consistency` in CI. Key pins: rust 1.96+, node 24+, flutter beta, typescript 7.x, tauri_cli 2.10+, flutter_rust_bridge 2.12+, riverpod 3.3, vite 8, react 19, zustand 5, surrealdb 3.2, pglite_oxide 0.5.1; inference lanes: llama-cpp-2 desktop+mobile, WebLLM web, mistral.rs optional.
- Project-level MCP config for four harnesses: `.mcp.json` (Claude Code), `.codex/config.toml`, `opencode.json`, `.kimi-code/mcp.json` — Dart/Flutter MCP server + shadcn MCP server at project scope.

### 1.2 Scaffolding scripts (`scripts/`, 19 files)

| Script | Capability |
|---|---|
| `check-env.sh` | Four-pillar bootstrap (`--install`, `--full`): (1) Rust 1.96+ + wasm32 target + full Prometheus Skill System (`pk doctor --json` verify); (2) OpenSpec (`@fission-ai/openspec` 1.6.0+, never the squatted bare package); (3) Flutter/Dart **beta channel** (ships Dart MCP server); (4) Node 24 LTS + bun + pnpm + TypeScript 7. Also installs tauri-cli, flutter_rust_bridge_codegen 2.12, cargo-ndk. |
| `scaffold-hybrid.sh` | Full project: `rust/` (layered workspace via scaffold-rust-core.sh) + `mobile/` (Flutter) + `desktop/` (Tauri) + publishable packages + project-local skills + copies `AGENT_BASE_RULES.md` + generated CLAUDE.md declaring the 40 rules binding + `docs/tj-arch-mob-001.html`. Flags: `--org`, `--uar embedded\|external`. |
| `scaffold-rust-core.sh` | Emits the **13-crate layered workspace** (see §2.1), workspace Cargo.toml with compile-speed profiles (deps opt-level 2, build-override opt-level 3, `debug = "line-tables-only"`, `split-debuginfo = "unpacked"`, wasm-release profile, **panic=unwind for FFI** — never `panic = "abort"` except wasm), `.cargo`/bacon config, `rust-toolchain.toml` (1.96). Declares **commented-out, SHA-pinned FRF git deps** (`frf-sdk-rust`, `frf-crdt`, `frf-store-redb` at rev `9ba04ae6ce41be796ae149609414b17a0d0d376b`) behind `frf`/`peer-crdt` feature flags so the default scaffold stays wasm-safe and offline-resolvable. |
| `scaffold-flutter.sh` | Flutter app: Riverpod 3.3 codegen, freezed, GoRouter, shadcn_flutter, frb wiring. |
| `scaffold-tauri.sh` | Tauri 2 + React 19 + Vite 8 + Zustand 5 + PEM 3.x + TanStack Router/Table + Tailwind 4 + shadcn/ui init + Assistant UI. |
| `scaffold-packages.sh` | Publishable package skeletons (C-007): `packages/gen-ui-react` (`@prometheus-ags/gen-ui-react`, npm), `packages/gen-ui-wasm` (`@prometheus-ags/gen-ui-wasm`), `rust/crates/tauri-plugin-gen-ui/guest-js` (`@prometheus-ags/tauri-plugin-gen-ui`), `flutter_packages/gen_ui_flutter` (FFI plugin, pub.dev), `flutter_packages/gen_ui_widgets` (ContentBlock widgets, pub.dev), `flutter_packages/prometheus_entity_management` (Rust-backed Dart PEM port, C-010). ContentBlock contract frozen at 11 variants with **exhaustive** React switch + Flutter switch (adding a variant = compile error by design). |
| `new-feature.sh` | Feature module generator, both platforms: Flutter `features/<name>/{data/{repositories,datasources,models},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}` (freezed entity, abstract repository, DTO, @riverpod provider); Tauri `features/<name>/{api,stores,entities,hooks,components,types.ts}`. All output carries `// TJ-ARCH-MOB-001 compliant`. |
| `add-auth.sh` | Adds Ory Kratos or Supabase auth to an existing scaffold, flutter or tauri. |
| `add-project-skills.sh` | Emits `templates/project-skills/` into all six harness skill dirs + hooks (`skill-activation.py` UserPromptSubmit, `a11y-reminder.py` PostToolUse) and merges `settings.hooks.json` into `.claude/settings.json`. |
| `audit.sh` | Modes: `flutter`, `tauri`, `rust`, `doc-consistency` (versions.toml vs authority docs), `all` (auto-detects mobile/desktop/rust surfaces, verifies layer contracts). |
| `install-flutter.sh`, `install-global-harnesses.sh` | Flutter beta install; global install of skills/MCP for Claude Code, OpenCode, Codex, Kimi Code CLI, Zed. |
| `verify-tauri-boot.sh`, `patch-cargokit-ios.sh` | Runtime boot verification; iOS cargokit patch. |
| `consolidate-prometheus-wikis.py`, `worktree-consolidation-inventory.py`, `merge-zed-context-servers.mjs` | Knowledge-base/worktree/harness maintenance utilities. |

### 1.3 Reference documents (`references/`, 14 files, ~3,400 lines)

| File | Content |
|---|---|
| `arch-standard.md` | Decision authority. Platform matrix (Flutter+Rust FFI **mandatory** iOS/Android; Tauri+React 19 desktop; hybrid default). gen_ui_core invariant. UAR modes (`UarMode::Embedded` / `External{url,api_key}`). ContentBlock↔A2UI↔widget mapping table. Decision matrix. **Maintenance-ownership clause** (2026-07-16 assessment rec #10): bridge-layer ownership (frb + Tauri-plugin surfaces, embedded-engine lifecycle contracts, versions.toml currency) is a permanent engineering function, citing 1Password's one-Rust-core precedent. |
| `flutter/patterns.md` | Riverpod 3.3 (unified Ref, Notifier fusion, **FFI providers MUST set `retry: (_, __) => null`** — automatic retry is on by default and silently re-invokes FFI), Mutations API for send flows, autoDispose streaming, `ChatNotifier.streamBlock()` as the only ContentBlock mutation path, shadcn_flutter, GoRouter guards, Kratos/Supabase, C-113 navigation rule (bottom bar at phone width, rail above; branch on width never OS). |
| `flutter/auth.md`, `flutter/testing.md` | Full Kratos/Supabase implementations; Riverpod/widget/golden tests. |
| `tauri/patterns.md` | Strict layer contract `Component → Hook → Store → [Rust invoke()/API]`; Zustand 5 (immer + subscribeWithSelector) for transient state; **PEM 3.x (`@prometheus-ags/prometheus-entity-management`) mandatory for server/entity state, TanStack Query prohibited**; TanStack Router `beforeLoad` auth guards; Assistant UI owns chat; durable conversations = PEM entities over PGlite (web) / pglite-oxide via typed Rust commands (Tauri); Flat 2.0; package.json version set; ContentBlock TS discriminated union + exhaustive `renderBlock` switch; Tauri plugin-store persistence for Zustand; Rust→React state via `emit("rust_state_update")`. |
| `tauri/auth.md`, `tauri/eslint-config.md`, `tauri/testing.md` | React Kratos/Supabase; ESLint 9 flat config + tsconfig strict + Vitest; layer-contract enforcement tests. |
| `rust/patterns.md` | Layered workspace layout; workspace Cargo.toml; FFI surface rules (simple owned types, `StreamSink<FrbA2uiEvent>`); Tauri command pattern (mpsc → ProtocolPipeline → `app.emit("a2ui_event")`); `UarMode` config; local model catalog (7 GGUF models: Qwen2.5 0.5B/1.5B, Phi3.5Mini, Llama3.2 1B/3B, Gemma2 2B, SmolLM2 1.7B); **SurrealDB 3.2 graph-RAG**: 2.x→3.x breaking changes (MTREE→**HNSW**, SEARCH→**FULLTEXT ANALYZER**, `type::thing`→`type::record`, `<|K,EF|>` KNN operator), verified HNSW→RELATE-expansion→BM25→RRF-fusion-in-Rust pattern, DDL schema (384-dim embedding), **intent-level FFI only** (`memory_search`, `graph_expand`, `upsert_entity` — Dart never sees SurrealQL), embedded-engine singleton lifecycle. |
| `rust/new-block-type.md` | Mandatory 7-step full-stack ContentBlock variant addition (StreamEvent → A2uiEvent+ingest → AG-UI translate → frb codegen/Tauri commands → Dart sealed class/TS type → driver case → widget/component). |
| `rust/wasm-targets.md` | C-002 spike findings: SurrealDB 3.2 `kv-indxdb` compiles clean on wasm32 (dep tree: idb 0.6.5, rexie 0.6.2, indxdb 0.12.0, wasmtimer, tokio-tungstenite-wasm); `reqwest`/`reqwest-eventsource` have **no wasm32 backend** — use `web_sys` fetch/EventSource; **PGlite on web is JS-owned** — the only sound Rust boundary is a `#[wasm_bindgen(module = "/js/pglite_shim.js")]` extern over a JS shim (`create_pglite`, `pglite_query`); sqlx/tokio-postgres to PGlite on web is **impossible**; `Query::take` requires `SurrealValue` not `Deserialize`; getrandom needs `js` feature. |
| `rust/compile-speed.md` | Crate-split rationale; SurrealDB isolated because build.rs re-run issue #6954. |
| `rust/testing.md` | tokio::test, wiremock, SurrealDB integration tests. |
| `auth/patterns.md` | Kratos vs Supabase vs combined; Kratos token → Rust exchanges for Supabase JWT; RLS everywhere; service-role key never leaves Rust. |
| `ui-skills.md` | Two-layer UI/UX skill stack: external (frontend-design, shadcn MCP, theme-factory, vercel react-best-practices/web-design-guidelines, ui-ux-pro-max, Dart & Flutter MCP, flutter/skills, VGV goldens, shadcn-ui-flutter, a11y) + project-local emitted skills with activation hooks (~50%→84–100% activation claim). |

### 1.4 Templates (`assets/templates/` and `templates/project-skills/`)

- `assets/templates/`: `cargokit/` (iOS dedup), `content-block/block-template.tmpl`, `flutter-feature/` (entity + provider templates), `rust-core/README.md` (module implementation checklist incl. full Anthropic HTTP/2+SSE client), `rust/gen_ui_inference` + `rust/vendor` (vendored inference lane), `tauri-feature/feature-template.ts.tmpl`.
- `templates/project-skills/` — **15 project-local skills** emitted into every scaffold: `content-block-ui`, `hybrid-design-tokens`, `tauri-ui-review`, `tauri-custom-titlebar`, `mobile-navigation`, `flutter-golden-ui`, `a11y-gate`, `reference-ui-fidelity`, `build-branded-docusaurus`, `deploy-hybrid-agentic-stack`, `hybrid-runtime-verification`, `karpathy-progress-memory`, `orchestrate-prometheus-application`, plus `hooks/` (skill-activation.py, a11y-reminder.py) and `settings.hooks.json`. Notable for the master goal:
  - **`deploy-hybrid-agentic-stack`** — profiles `local`/`web`/`realtime`/`authenticated`/`full-agentic`; mandates host-neutral Rust service layer; `--mobile flutter|tauri|both|none` (flutter default).
  - **`orchestrate-prometheus-application`** — control loop `Feynman learn → KBD assess → research → decision-complete plan → bounded implementation → public-boundary verification → adversarial critic → Karpathy retention`; classifies product types; uses skill-creator / native-agent creator on proven gaps.

### 1.5 Docs (`docs/`)

- `tj-arch-mob-001.html`, `gen_ui_spec.html` — full standard + gen_ui spec (SVG diagrams).
- **`docs/pglite-oxide-tauri-hybrid.md`** — corrected (2026-07-15) authoritative embedded-Postgres design (detailed in §2.2 below).
- **`docs/reference-app/knowme-agentic-deployment-plan.md`** — the authoritative KnowMe web/Axum/Flint/BYOK/deployment/continuous-learning plan (detailed in §2.3).
- `docs/reference-app/`: also `knowme-poc-architecture-and-implementation-plan.md` (MoSCoW spec; §3.6 config database; §3.7 data & sync; boot-order invariant §3.4), `flint-supabase-deployment-research.md` (Flint↔Supabase mental model mapping + security conclusions + v2 watch contract), `knowme-ui-failure-analysis.md`, `KnowMe Standalone.html`, `knowme-functional-specification-architecture.html`, `knowme-moodboard-user-journeys.html`.
- `docs/knowme-ui-ux-standard.md` — binding Flat 2.0 product-design standard (borderless; 4-level surface ladder; Ember `#FF6A3D` brand + Cyan `#00C2DC` AI-annotation palette; experience qualities: Personal, **Local-first**, Inspectable, Calm, Fast, Honest, Continuous).
- `docs/assessment-2026-07-16.md` — independent deep assessment (verdicts: sync layer is custom software you own; DB matrix overbuilt; WASM plugin system precedented by Zed but v0.1 WIT surface should be ⅓ of spec; sovereign-AI market thesis unvalidated).
- `docs/corrections-2026-07-16.md` — **A2UI naming note**: this repo's "A2UI" is gen_ui's *internal* agent-to-UI protocol, NOT Google's A2UI standard (a2ui.org, v1.0 RC, shipped Flutter+React renderers) and not Anthropic's; adopt-vs-rename is an **open decision**.
- `docs/deployment/` — `edge-routing-and-tls.md` (4 supported K8s edge choices: NGINX Ingress/Gateway Fabric, Traefik Ingress/Gateway; ArgoCD reconciles; Terraform/OpenTofu owns prereqs), `implementation-evidence.md`, `intel-amd64-build-handoff.md`.
- `docs/prompting/` — `model-registry.yaml` + `validate-model-registry.mjs`, `prometheus-application-prompting-guide.md`, `scenario-packs.md`.
- `docs/goal-completion-evidence.md`, `docs/competitive-analysis-2026-07-16.md`, `docs/global-harness-installation.md`.

### 1.6 Governance, knowledge, and change-management infrastructure

- `AGENT_BASE_RULES.md` — the 40 Prometheus Base Rules (canonical). Rule 12 (Open Standards First) explicitly prefers **MCP, A2UI/AG-UI, OpenAI-compatible APIs, WASM, PostgreSQL-compatible storage, IPFS-compatible distribution**. Propagation is mandatory: every scaffold copies it and generated CLAUDE.md/AGENTS.md declare it binding.
- `.prometheus/` — committed knowledge base (events.jsonl, wiki, session logs); standing authorization to always commit/push. Wiki includes durable decisions: `frf-versus-electricsql-decision-point-for-knowme-poc-sync`, `pes-v4-server-binary-completion-and-sync-engine-scope`, `prometheus-entity-sync-v4-transport-progress-and-pes-server-blocker`.
- `openspec/changes/` — 17 dated changes (c101 bootstrap pillars, c102 PoC scaffold, c105 local model desktop, **c106 sync-local-first** ("docker compose (Postgres+Electric) + write queue; offline edit → cross-surface sync; SyncChip"), c108 mcp-skill-and-agent, **c109 settings-mobile-model** (Settings UI over config DB, Liter-LLM catalog, keychain-backed keys, UarMode/sync/delete-data, Qwen-0.5B CPU sovereign mobile), c110 CI, c111 memory UI, c113–c119 navigation/theme/mobile retrofit/OpenDesign entry).
- `.kbd-orchestrator/phases/scaffold-full-hybrid-project/analysis.md` — the deep build-vs-adopt analysis (foundation for §3 below).
- `.mcp.json`, `opencode.json`, `.codex/`, `.kimi-code/`, `.claude/`, `.agents/`, `.kimi/` — per-harness config; skills kept in sync as copies across `.claude/skills/`, `.agents/skills/`, `.opencode/skills/`, `.kimi/skills/`, `.kimi-code/skills/`.
- `deploy/` — `compose.yaml`, `compose.dev.yaml`, `docker-bake.hcl`, `docker/`, `postgres/`, `config/keto.yml`, `gitops/` (components + services), lock files (`images.lock.yaml`, `sources.lock.yaml`, `third-party.lock.yaml`), validation scripts.

### 1.7 The proof-of-concept instance (`apps/knowme-poc/`)

A real scaffolded instance exists with `rust/crates/` containing **16 workspace members**: `gen_ui_types`, `gen_ui_runtime`, `gen_ui_protocol`, `gen_ui_client`, `gen_ui_mcp`, `gen_ui_db`, `gen_ui_db_graph`, `gen_ui_inference`, `gen_ui_agent`, `gen_ui_audio` (whisper scribe), `gen_ui_host`, `gen_ui_server_axum`, `knowme-web-server`, `gen_ui_ffi`, `gen_ui_wasm`, `tauri-plugin-gen-ui`, plus `workspace-hack` (cargo-hakari). Plus `mobile/`, `desktop/`, `packages/`, `flutter_packages/`, `infra/`, `deploy/`, Dockerfile + docker-compose.yaml.

---

## PART 2 — HOW IT WORKS

### 2.1 The layered Rust workspace (the core architecture)

`scaffold-rust-core.sh` emits a strictly layered workspace (comments in the script, lines 10–20):

```
L0   gen_ui_types      pure types + ALL cross-crate traits (FROZEN seams, c001). wasm-safe.
L1   gen_ui_runtime    native Tokio / wasm spawn_local abstraction
L1   gen_ui_protocol   A2UI/AG-UI adapters over futures channels. wasm-safe.
L2   gen_ui_client     Flint gate(auth) / forge(Quarry+MCP+AG-UI) / frf(spine, feature-gated)
L2   gen_ui_mcp        MCP client registry (JSON-RPC 2.0 + HTTP/SSE; forge a2ui seam)
L2   gen_ui_db         relational (pg/pglite) + graph + sync
L2   gen_ui_db_graph   SurrealDB 3.2 (ISOLATED for compile caching, issue #6954)
L2   gen_ui_inference  InferenceProvider impls (llama-cpp-2 default, mistral.rs optional)
L3   gen_ui_agent      PMPO loop (UAR embedded mode) over L0–L2
LEAF gen_ui_ffi        flutter_rust_bridge surface (the ONLY file frb processes)
LEAF tauri-plugin-gen-ui  Tauri commands/events/permissions
LEAF gen_ui_wasm       wasm-bindgen/web surface (fetch/EventSource/PGlite-shim)
```

**Frozen trait seams in `gen_ui_types`** (the critical extension surface):
- `content_block.rs` — ContentBlock contract (11 variants, frozen).
- `events.rs` — A2UI event surface (27-variant set in gen_ui_protocol).
- `view.rs` — `ViewDescriptor`/`FilterSpec`/`SortSpec`, transport-agnostic, compiles to SQL in gen_ui_db.
- `transport.rs` — **`EntityTransport` trait**: `list(view)`, `get(type,id)`, `create`, `update`, `delete` — the entity data-access seam implemented by gen_ui_db / gen_ui_client, exposed to Dart via gen_ui_ffi. "UI never implements it."
- `sync.rs` — **`SyncTransport` trait**: `start()` (begin read-path sync for a shape/bucket into local store), `enqueue_write(change_json)`, status (drives the UI "sync chip"). Doc-comment: "The DIY Electric-consumer + write-queue (gen_ui_db::sync) implements this; a future prometheus-entity-sync (PES) client" can too.
- `inference.rs` — `InferenceProvider` (`load(LocalModelSpec)`, `generate`, `unload`).
- `config.rs`, `error.rs`.

**FFI/Tauri/wasm surfaces**: `api.rs` (frb codegen target; simple owned types; `async fn stream_agent_a2ui(..., sink: StreamSink<FrbA2uiEvent>)`); Tauri commands bridge mpsc → `ProtocolPipeline` (dual broadcast channels) → `app.emit("a2ui_event")`; wasm uses `web_sys` fetch/EventSource + the PGlite JS shim.

**State/data flow**: UAR PMPO loop (max_turns guard, tool routing) → MCP registry (SSE + stdio) → Anthropic client (reqwest HTTP/2 + rustls + SSE + prompt caching) OR local inference (spawn_blocking) → StreamEvent → A2uiEvent (27 variants) → AguiEvent → per-shell ContentBlock folding (Flutter `ChatNotifier.streamBlock()`; React Zustand `applyA2uiEvent`).

### 2.2 The pglite-oxide / Tauri hybrid design (current, corrected)

Source: `docs/pglite-oxide-tauri-hybrid.md` (corrected 2026-07-15 — earlier claims that pglite-oxide was a native Postgres binary with iOS/Android support were **wrong**).

**Verified facts**: pglite-oxide 0.5.1 (published 2026-06-04, `github.com/f0rr0/pglite-oxide`) hosts ElectricSQL's PGlite **WASI build** (PostgreSQL 17.5 compiled to WASM) inside a WASM runtime in the Rust process; exposes `PgliteServer` speaking the real PG wire protocol → SQLx/tokio-postgres/Diesel/SeaORM connect unchanged. Runtime assets: **macOS arm64, Windows x64, Linux x64/arm64 only — no iOS/Android** (iOS structurally cannot run stock Postgres: no child processes, no JIT). Successor "Oliphaunt" is pre-release (0.0.0) — do not architect against it.

**Per-target data-layer matrix (authoritative)**:

| Platform | Relational | Vector | Graph RAG | Sync client |
|---|---|---|---|---|
| Web | Electric PGlite 0.5.4 (`idb://` + relaxedDurability, multi-tab worker) | pgvector ext (HNSW in WASM) | SurrealDB `kv-indxdb` / `@surrealdb/wasm` | `@electric-sql/pglite-sync` shapes |
| Desktop (Tauri) | pglite-oxide 0.5.1 (`PgliteServer` → sqlx `PgPool`) | pgvector (same SQL as cloud) | SurrealDB 3.2 `kv-rocksdb` | Rust Electric shape consumer |
| iOS/Android (Flutter) | **SQLite via sqlx-sqlite in gen_ui_core** | **sqlite-vec** | SurrealDB 3.2 `kv-rocksdb` | Rust sync client |
| Cloud | Postgres 18 / Supabase (RLS) | pgvector | SurrealDB server | Electric sync-service 1.7.x |

Embedding dims standardized at **384** (or matryoshka-truncated 768) so vectors replicate across engines; on-device embeddings via fastembed-rs/candle in gen_ui_core. PGlite guest bundles pgvector, pg_trgm, citext, hstore, ltree; mobile equivalents are sqlite-vec, FTS5, JSON1.

**`prometheus-db` abstraction**: repository traits in gen_ui_core select backend per target (Browser→PGlite, Desktop→pglite-oxide, Mobile→SQLite+sqlite-vec, Cloud→Postgres 18/Supabase). Desktop+cloud share **one sqlx query set** swapped by connection string at config time; mobile is a deliberate dialect exception — **the repository trait, not the connection string, is the portability seam**. Recommended capabilities: per-dialect migrations (sqlx `migrate!`/refinery; drizzle-kit JSON for web), Electric shape read-path sync, SurrealDB graph integration, on-device embeddings, full-text search, **snapshots (PGlite `dumpDataDir()`/`loadDataDir()`; IPFS content-addressed seed snapshots per Rule 12)**.

**Embedded-engine lifecycle contract** (applies to PgliteServer, PGlite, SurrealDB, any future engine): exclusive data-dir lock; in-process registry + OS advisory lock (dies with process — **stale locks impossible; never write lock-file cleanup code**); `tauri-plugin-single-instance` first in the builder; **coalesced init via `tokio::sync::OnceCell::get_or_try_init`** (never check-then-act — React StrictMode double-invokes startup); frontend startup idempotency (startupStore dedups in-flight boot); warn on double-init, never silently swallow. The KnowMe PoC hit this exact bug ("PGlite root is already in use").

### 2.3 The KnowMe reference app architecture

Source: `docs/reference-app/knowme-agentic-deployment-plan.md` (execution authority) + PoC plan + `flint-supabase-deployment-research.md`.

**Outcome**: one `main` with React 19/Vite web + Tauri desktop from the same frontend source; Flutter mobile with same behavior/design; **one host-neutral Rust service layer shared by Tauri, Flutter FFI, and Axum**; zero-config local chat + optional hosted **Liter-LLM BYOK**; durable multi-conversation chat, rich AG-UI events, RAG citations, media; browser PGlite / desktop pglite-oxide / mobile SQLite+sqlite-vec / hosted PostgreSQL; optional Flint Forge/Fabric/Gate + Ory Kratos profiles; lossless learning histories.

**Runtime shape**:
```
React web → optional Gate → Axum adapters --+
Tauri commands/events ----------------------+--> gen_ui_host AppServices
Flutter FFI --------------------------------+       ├─ conversation persistence
                                                    ├─ inference / Liter-LLM
                                                    ├─ agent + MCP + memory/RAG
                                                    └─ sync / provider configuration
```
New Rust packages: **`gen_ui_host`** (host-neutral typed application services + ports), **`gen_ui_server_axum`** (reusable Axum router, AG-UI SSE, validation, OpenAPI, probes, metrics, static-site adapter), **`knowme-web-server`** (thin executable composition root). Axum public boundary: typed conversation/message/artifact CRUD, model/provider catalog, **write-only secret-reference create/rotate/delete/validate**, memory search/citations, run/cancel with AG-UI SSE, health/readiness/metrics/OpenAPI. Hosted React never orchestrates Flint or Liter-LLM directly.

**Flint coordinated changes** (from `flint-supabase-deployment-research.md`, inspected revisions 2026-07-17: Forge `4d5f97f`, Fabric `edbb215`, Gate `057d64d`): Supabase mental model (Forge = Postgres+extensions+Quarry data API; Fabric = realtime plane; Gate = optional policy/auth boundary; KnowMe Axum = product API/orchestrator). **Preserve Fabric's frozen v1 `EntityService`; add a tenant-scoped v2 entity-type watch contract** with: authenticated tenant/actor context, entity type + optional resume cursor, stable event id/revision/operation/server timestamp, **per-event authorization re-check before payload release**, explicit lag/cursor-expired/authorization-revoked/dependency-unavailable terminal events, reconnect/resume + cross-tenant denial proofs. Forge keeps LISTEN/NOTIFY baseline; Fabric selection is explicit and **fails closed**, never silently falls back. Four security layers preserved: Kratos auth, Gate/Keto authorization, Postgres RLS, per-event realtime re-check.

**Secret behavior**: local chat works credential-free (WebLLM browser; downloaded Rust model Tauri/mobile; explicit selection never silently falls back). Anonymous hosted BYOK = session-memory-only. Durable BYOK = authenticated identity + **encrypted Flint Vault reference**. Local secrets in platform secure storage; **secret values never enter PEM, PGlite, Zustand, logs, URLs, ordinary Postgres columns, Compose, ConfigMaps, or images**.

**Delivery profiles**: `local` / `web` / `realtime` (web + Forge + Fabric) / `authenticated` (Gate + Kratos) / `full-agentic` (all + Liter-LLM BYOK + observability). Multi-stage non-root Dockerfile, profile-based docker-compose, **Kustomize base/overlays as primary packaging** (Helm charts may be referenced); credentials external.

**Phase status (2026-07-17)**: Phase C (host, Axum SSE run boundary, embedded/external asset server, container image, probes, generated Liter-LLM provider catalog, desktop keychain BYOK, anonymous request-scoped browser BYOK) implemented + live HTTP validation passed; hosted entity/config admin, OpenAPI generation, full public-workflow proof remain. Phase D (realtime, durable BYOK, identity): Compose profiles + initial Gate/Kratos/Keto/Fabric/Forge configs render but **have not passed live launch, authorization, reconnect, or durable-vault verification — phase open**.

**Continuous-learning contract**: three projections (committed `.prometheus`; private `~/.prometheus/knowledge/private/hybrid-mobile-architecture-src`; shared `~/.prometheus/knowledge/shared`); `karpathy-progress-memory` at task/phase boundaries; `prometheus learn --capture-session --compile --lint` at phase gates; no secrets in any projection.

**Config database** (PoC plan §3.6): `providers` (id, kind, base_url, api_key_ref, enabled), `model_prefs` (surface, lane, model_id, params), `app_settings` (key, value) — PostgreSQL-semantics store per target (pglite-oxide desktop/mobile per plan [superseded: mobile = SQLite], PGlite web); settings never transit FFI as raw SQL; API keys in keychain (desktop) / flutter_secure_storage (mobile) with DB row holding only a reference.

**Sync design** (PoC plan §3.7): "The write path is first-class custom software we own — ElectricSQL deliberately dropped write-path sync in electric-next; our `gen_ui_db::sync` write queue IS the sync engine, with Electric as the read cache." M3 runs from `infra/docker-compose.yml` (Postgres + Electric).

---

## PART 3 — IMPLICATIONS FOR THE MASTER GOAL (CONCRETE EXTENSION POINTS)

### 3.1 Local-first sync (pglite/pglite-oxide → FRF → flint-forge postgres)

**What already exists in this repo as seams:**
1. **`gen_ui_types::sync::SyncTransport`** (scaffold-rust-core.sh emits it) — the declared seam for sync engines; doc-comment explicitly reserves it for a future PES client. **This is where an FRF-backed sync engine plugs in.**
2. **`gen_ui_types::transport::EntityTransport`** — entity CRUD seam; PEM 3.x adapters (tenant-scoped ElectricSQL, Tauri SQL, SurrealDB live, **Flint realtime**) already exist in the PEM repo per analysis §1.5.
3. **`gen_ui_db` sub-structure** (analysis C-1 refinement): `db/relational` (features `pg` / `sqlite`), `db/graph`, **`db/sync` (Electric shape consumer + write queue + trait seam for PES)** — C-003 already implemented in scaffold: feature-gated `gen_ui_db::relational` with SQLx Postgres/cloud + pglite-oxide desktop + SQLite/sqlite-vec mobile, per-dialect migrations, **bundled/HTTP/IPFS seed sources**, typestate startup orchestrator enforcing migrations → seeds → sync attach.
4. **FRF feature flags**: `frf` / `peer-crdt` features declared in the scaffolded workspace with SHA-pinned git deps (`frf-sdk-rust`, `frf-crdt`, `frf-store-redb` @ `9ba04ae6`) — currently commented out; C-006 verified `frf.rs` (Spine façade + peer-crdt re-exports) clippy-clean against the real FRF checkout. FRF = tonic gRPC native-only; browser surface via `frf-wasm`/Connect-web.
5. **Boot-order invariant** (PoC §3.4): migrations → seed/lookup bundles → sync shapes attach (shapes fail on unknown columns) — sync attach is already an ordered, orchestrated phase.

**Decisions already made (must be honored or explicitly revisited):**
- Write-path sync is **owned custom software** (`gen_ui_db::sync` write queue); Electric is read-path only (assessment §3.4; Electric dropped write-path in electric-next, July 2024).
- **FRF vs ElectricSQL is an either/or CDC decision, not stackable** (wiki `frf-versus-electricsql-decision-point-for-knowme-poc-sync`): FRF has zero ElectricSQL references; `frf-postgres-cdc` already opens a logical replication slot and decodes pgoutput via tokio-postgres — adding Electric would create competing CDC paths.
- PES (prometheus-entity-sync) v4 design exists: Postgres WAL → `frf-postgres-cdc` → per-bucket ordered op-log → `PSyncV1` WebSocket → PGlite/SQLite/pglite-oxide clients; `BucketAssigner` per-user bucket membership from JWT claims; `frf-crdt`/Loro for CRDT write path; **OpenSpec umbrella (14 changes, waves 1–3 specified) — not built yet**; v4 chose `EntityTransport<T>` over the `SyncProvider` interface (recorded as a tension).
- CRDT lane adopted: FRF `frf-crdt` (Loro) + `frf-store-redb` (on-device op-log) + SyncService (bidi op batches) — the OFP-style peer sync from the KnowMe IPFS spec.
- Realtime contract: v2 tenant-scoped entity-type watch (do NOT mutate Fabric v1 EntityService), per-event authZ re-check, fail-closed.

**To add for the master goal:** a `gen_ui_db::sync` backend (or new `gen_ui_sync` crate) implementing `SyncTransport` over FRF: pglite-oxide (desktop) and PGlite-via-JS-shim (web) as client stores; `frf-postgres-cdc` server-side into flint-forge Postgres 18; Loro CRDT merge for offline writes; the SyncChip UI entity; Dart/TS surfaces via gen_ui_ffi / PEM transports.

### 3.2 WASM component model (native skills for agent harnesses, A2UI/AG-UI/HTMX UI modules)

**Existing seams:**
- The KnowMe IPFS spec (analysis §0) already targets **WASM Component Model plugins distributed via IPFS with Ed25519 signing**, Cedar-governed, with Wasmtime named in the stack.
- Flint Forge (**flint-forge**) already has **Kiln signed-WASM edge functions** and an **A2UI registry exposed as an MCP server** (`/mcp/v1/a2ui` + SSE) — `gen_ui_mcp` registers it directly via the existing SSE transport (analysis §1.7).
- `gen_ui_wasm` leaf crate + `@prometheus-ags/gen-ui-wasm` npm package exist for Rust→wasm32 of the *core*, not yet for *plugins*.
- ContentBlock + `new-block-type.md` 7-step process is the current (compile-time, monolithic) UI-module mechanism; a WASM-component UI module system would complement/replace it for third-party blocks.
- Assessment §3.6: Zed's shipped Wasmtime+WIT extension system is the precedent; **KnowMe's spec'd v1 surface (UAR skill invocation, storage, network-by-proxy, navigation injection, iframe UI, IPFS distribution, Ed25519 signing, Cedar governance) is ~3× too wide — v0.1 WIT surface should be a third of it**.

**To add:** a `gen_ui_plugins` crate (Wasmtime host + WIT world) with trait seams in `gen_ui_types` (e.g., `SkillModule`, `UiModule`, `SettingsModule`); capability-based host functions (storage via repository traits, network-by-proxy via gen_ui_client, UI injection as new ContentBlock variants); Cedar policy evaluation points aligning with Flint Gate's existing Cedar NHI policies; settings-schema distribution (see 3.3).

### 3.3 Settings schema with synced client/server storage

**Existing seams:**
- Config DB schema v1 already defined (PoC §3.6): `providers`, `model_prefs`, `app_settings` tables; keychain-backed secret references; per-target store (pglite-oxide/PGlite/SQLite).
- `gen_ui_types/src/config.rs` seam exists in the scaffold.
- C-109 (settings-mobile-model) grows Settings UI over the config DB: Liter-LLM catalog, keychain keys, UarMode/sync/delete-data admin.
- Zustand settings persistence via `@tauri-apps/plugin-store` (tauri/patterns.md).
- Flint Vault for durable BYOK secret references (write-only secret-reference ops on the Axum boundary).

**Gap:** settings are per-device rows today; there is **no schema-versioned, sync-aware settings model** (no CRDT/LWW merge semantics for `app_settings`, no server-side settings bucket in the v2 watch contract, no WASM-component-declared settings schema). The master goal's "settings schemas with synced client/server storage" would extend: `SyncTransport` shape/bucket definitions for settings entities; the PEM `registerEntityFromSql` JSON-Schema/SQL-DDL entity registration (analysis §1.5) as the schema carrier; WIT-declared settings interfaces for component-contributed settings.

### 3.4 Decentralized packaging (IPFS / git-like Rust versioning)

**Existing seams:**
- Rule 12 (Open Standards First) already names **IPFS-compatible distribution** as preferred.
- Seed-distribution ladder (analysis §1.8) already includes **IPFS content-addressed seed snapshots (CID-verified)** as rung 4 — DIY tooling, no off-the-shelf; C-003 implemented bundled/HTTP/IPFS seed sources in `gen_ui_db::relational`.
- Flint Forge has an **extension registry with IPFS/OCI/S3 stores + signing** (per shared context) and an A2UI registry; flint extensions exist.
- Publishable-packages-from-day-one doctrine: crates.io (`gen_ui_types/protocol/client/mcp/agent`, `tauri-plugin-gen-ui`), pub.dev (`gen_ui_flutter`, `gen_ui_widgets`, `prometheus_entity_management`), npm (`@prometheus-ags/gen-ui-react`, `gen-ui-wasm`, `tauri-plugin-gen-ui`).
- `deploy/` lock files (`images.lock.yaml`, `sources.lock.yaml`, `third-party.lock.yaml`) show digest-pinning discipline.

**Gap:** no IPFS client/pinning code in the scaffold itself (seeds reference it; plugin distribution does not yet exist); no git-like content-versioning crate; Flint SDKs/packages are **unpublished** (path/git refs) — registry cadence is an open dependency.

### 3.5 WebRTC / lora-rs transport

- FRF provides **WebRTC signaling** (sovereign SFU in active dev on `sovereign-sfu-decode-proof` branch; near-term LiveKit path recommended, analysis open question #4; a WebRTC decode investigation was unresolved as of 2026-07-16 wiki).
- `frf-crdt` SyncService bidi op batches are the CRDT-over-WebRTC payload lane.
- **lora-rs appears nowhere in this repo** (grep: zero hits) — it would be a new transport under `SyncTransport`/`EntityTransport` or an FRF bridge concern (FRF has "bridges" per shared context).

### 3.6 Cross-cutting implications

- **The frozen-seam discipline is the enabler**: every master-goal capability (sync, plugins, settings, packaging) has a declared trait or doc'd seam in `gen_ui_types` or the docs; adding them means implementing behind existing seams, not redesigning. The 13-crate layering (L0 traits → L2 impls → leaves) was explicitly designed for parallel worktrees.
- **A2UI naming decision is open** (`docs/corrections-2026-07-16.md`): adopt Google's A2UI (a2ui.org, v1.0 RC, shipped Flutter/React renderers) as wire format vs rename internal protocol — this decision gates any A2UI-component-registry and AG-UI/HTMX module work.
- **UAR embedded/external duality** maps directly onto client/cloud agent cooperation: `UarMode::External{url}` + Gate's `act` delegation JWT claim + Cedar `@require_approval` give the cloud-agent path; embedded PMPO loop is the client path.
- **Bridge ownership is a named risk**: arch-standard.md's maintenance-ownership clause requires a named owner for frb/Tauri-plugin bridge surfaces, embedded-engine lifecycle contracts, and versions.toml currency before a second product commits.

---

## PART 4 — GAPS / RISKS

1. **Sync engine is unbuilt owned software.** `SyncTransport` is a trait with a DIY-write-queue plan; PES waves 1–3 are specified but not built; the FRF-vs-Electric CDC decision is documented but the final pick for KnowMe PoC was still a live decision point (2026-07-16 wiki). Electric's own history (vertically-integrated local-first collapsed, rebuilt read-path-only) is the strongest cautionary precedent (assessment §3.4).
2. **DB matrix breadth.** Five engines (pglite-oxide, PGlite WASM, SQLite+sqlite-vec, SurrealDB embedded, cloud Postgres), two SQL dialects + SurrealQL — "overbuilt for the stage" (assessment §3.5). PGlite is single-connection; SurrealDB embedded has **no verified production-readiness evidence** and known 3.0 embedded/RocksDB regressions (surrealdb#6800, #5541) — yet it is the pinned graph-RAG spine on mobile RAM budgets. Benchmark gate + named fallback (sqlite-vec + FTS5 + recursive CTEs) recommended.
3. **pglite-oxide fragility**: 0.5.1 (June 2026) is an unverified Rust host layer on PGlite's moving target (v0.4 major refactor, March 2026); required an exact `virtual-net = 0.702.0-alpha.3` pin (C-003 log). Desktop-only forever; Oliphaunt pre-release.
4. **WASM plugin surface over-scope**: spec'd v1 surface ~3× the only successful consumer precedent (Zed). No WIT world, host crate, signing, or IPFS distribution implemented yet in this repo.
5. **FRF mid-flight**: WebRTC sovereign SFU on a feature branch with an unresolved decode investigation; all Flint SDKs unpublished (git/path deps pinned by SHA); FRF gRPC is native-only (browser needs frf-wasm/Connect-web).
6. **Flutter PEM port is a build, not an adopt**: `prometheus_entity_management` Dart package is designed (Rust canonical store, Riverpod families as normalization map, LWW/Loro merge in Rust) but is a new pub.dev package to write (C-010); npm PEM is 3.0.0-alpha.0 and had a monorepo-resolution blocker (`@prometheus-ags/entity-graph-core@workspace:*` not resolvable outside the PEM monorepo).
7. **Settings sync has no design**: config DB is local-only; no merge semantics, no synced settings bucket, no component-declared settings schema.
8. **A2UI identity crisis**: internal protocol shares a name with Google's A2UI standard; unresolved adopt-vs-rename decision affects every A2UI-registry/UI-module statement.
9. **Riverpod/FFI retry trap**: FFI providers must explicitly opt out of Riverpod 3's default automatic retry or Rust domain errors silently re-invoke FFI — a scaffold-template-level hazard for any new sync/provider code.
10. **Market thesis unvalidated** (assessment §3.7): no verified demand evidence for premium sovereign-AI pricing; Qwen weights are permissively licensed — affects what "native skills" packaging can charge for.
11. **Doc-drift risk is real and managed**: corrections of 2026-07-15/16 show authority docs previously contained wrong claims (pglite-oxide native/mobile, A2UI attribution); `audit.sh doc-consistency` + versions.toml is the gate — any new capability docs must enter versions.toml or the audit fails.

---

## APPENDIX — Key source files for follow-up

- Extension seams: `scripts/scaffold-rust-core.sh` (gen_ui_types sync.rs/transport.rs/config.rs emission), `.kbd-orchestrator/phases/scaffold-full-hybrid-project/analysis.md` (build-vs-adopt + open questions), `.kbd-orchestrator/dispatch/logs/2026-07-15-c006-flint-integration.done.md` (FRF integration state), `2026-07-15-c003-relational-store.done.md` (gen_ui_db::relational + IPFS seeds).
- Sync decisions: `.prometheus/knowledge/wiki/frf-versus-electricsql-decision-point-for-knowme-poc-sync.md`, `pes-v4-server-binary-completion-and-sync-engine-scope.md`, `prometheus-entity-sync-v4-transport-progress-and-pes-server-blocker.md`.
- OpenSpec: `openspec/changes/2026-07-15-c106-sync-local-first/`, `2026-07-15-c109-settings-mobile-model/`, `2026-07-15-c108-mcp-skill-and-agent/`.
- Flint contract: `docs/reference-app/flint-supabase-deployment-research.md` (v2 watch contract, fail-closed, per-event authZ).
- External anchors: pglite-oxide `github.com/f0rr0/pglite-oxide` (0.5.1, 2026-06-04); Electric PGlite `github.com/electric-sql/pglite`; electric-next announcement (2024-07-17, electric-sql.com/blog); surrealdb#6800, #5541; Zed "Life of an Extension" (zed.dev/blog, 2024); Google A2UI a2ui.org (v1.0 RC); Supabase architecture + Realtime docs (supabase.com/docs, accessed via repo docs 2026-07-17); Ory Kratos (ory.com/kratos); Kubernetes Kustomize docs.
