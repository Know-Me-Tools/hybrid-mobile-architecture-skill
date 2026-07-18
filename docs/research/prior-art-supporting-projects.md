# Prior Art & Supporting Projects — Research Brief

> **Slug:** `prior-art-supporting-projects`
> **Researcher:** KNOWME_RESEARCHER (deep-research swarm)
> **Date:** 2026-07-18
> **Scope:** Owner's prior art in `/Users/gqadonis/Projects/prometheus/` — the PGlite local-first knowledge base, the four prototype/vendor projects (`electric-tauri-postgres`, `powersync-service`, `juit-pgproxy`, `universal-agent-runtime`), Flint auth specs, plus the two directly reusable sibling projects (`prometheus-entity-management`, `prometheus-entity-sync`).
> **Lens:** Everything is analyzed against the master goal — pglite (web) + pglite-oxide (Tauri) clients syncing through flint-realtime-fabric (FRF) to central Postgres (flint-forge), cooperating client/cloud agents, WASM component-model skills + A2UI/AG-UI/HTMX UI modules, CRDT sync over WebRTC (and potentially lora-rs), and decentralized component distribution.

---

## 1. `PGLITE-LOCAL-FIRST-ARCHITECTURE.md` — the field guide (952 lines, dated 2026-07-13)

**Path:** `/Users/gqadonis/Projects/prometheus/PGLITE-LOCAL-FIRST-ARCHITECTURE.md`
(A Word twin exists: `pglite-local-first-architecture.docx`.)

### What exists

A curated, decision-oriented map of every recognized PGlite deployment pattern, explicitly addressed to "engineers building the Prometheus Fabric" and to the `@prometheus-ags/prometheus-entity-management` (PEM) framework. It is the *distilled* version of the much larger `pglite.agent.final.md` (§2 below), framed as "the 7 decisions that decide everything":

| # | Decision | Recommended default |
|---|----------|---------------------|
| 1 | Persistence layer | IndexedDB FS (`idb://`); OPFS AHP on Chrome/Firefox only; Node FS for Tauri |
| 2 | Sync engine | ElectricSQL (read path) + PGlite as local DB |
| 3 | RLS/tenancy | Shape predicates ⊆ RLS, enforced at the **shape factory**, not in PGlite |
| 4 | Schema design | Server tables = client tables + `_local*` columns for write tracking |
| 5 | Migrations | Additive-only, versioned, single `migrations/` folder |
| 6 | Reactivity | PGlite `live` extension → entity graph `useLiveQuery` (16 ms coalesced frames) |
| 7 | Boot | Four-phase boot: `idle → hydrating → syncing → ready` |

### How it works (key technical content)

- **Five recognized architectures** (§2): A local-only; B Electric read-path; C Electric + active-active writes (TCC+ CRDT); D TanStack DB on PGlite; E manual HTTP sync. Prometheus mapping is given for each (e.g., `createElectricAdapter`, `createTenantScopedElectricAdapter` in `entity-graph-core/src/adapters/`).
- **Schema-mismatch fix** (§3): the "augmented local table" pattern — synced columns byte-identical to server, client-only columns prefixed `_` (`_local_dirty`, `_local_deleted`, `_tx_id`, `_synced_at`, `_conflict_marker`), maintained by a `BEFORE INSERT OR UPDATE` trigger gated on `current_setting('app.server_sync_active')`. The trigger distinguishes Electric-replayed server rows from user writes so `_local_dirty` is never clobbered by sync.
- **Lookup-bundle bootstrap** (§3.5, §5.3): server-managed, client-read-only tables are NOT synced via Electric; they are fetched as versioned JSON bundles (`GET /v1/lookups/{name}`, 304/ETag revalidation) into `*_lookup` tables with a `_bundle_version` row.
- **RLS** (§4): PGlite is single-user Postgres — no `current_user`, no `SET ROLE`. RLS lives entirely in the shape-factory/auth-proxy layer. Four approaches tabulated; recommended is "Shape predicate ⊆ RLS" with a short-lived JWT carrying `company_id`. PEM's `electricsql-tenant.ts` is the enforcement seam: it refuses to attach a shape without a `tenantColumn`. *"PGlite has no RLS. The only way a client cannot see cross-tenant data is if the shape factory refuses to attach a shape that lacks a tenant predicate."*
- **Tauri patterns** (§7): T1 PGlite-in-webview with NodeFS (`dataDir = appDataDir + '/pgdata'`); T2 `pglite-oxide` in the Rust backend (Wasmtime-embedded PGlite exposing a Postgres wire socket to `sqlx`/`tokio-postgres`); T3 `tauri-plugin-sql`. Recommendation: *T1 for v1, graduate to T2 when native code needs the same data*. Mobile gotchas: iOS IDB quota, no OPFS in WKWebView, resync-on-resume.
- **Migrations** (§8): additive-only invariant (rename to `_deprecated_*`, never drop synced columns), server-side `pgroll` zero-downtime, client-side `drizzle-orm-browser` or hand-rolled `__migrations` table / `PRAGMA user_version`, and the "schema fingerprint" recovery pattern (§9.7) for drift.
- **App-category stacks** (§10): Agentic = PGlite + `pgvector` (HNSW) + `live` + Electric read-path + entity graph; the durable agent loop uses the graph's pending-actions queue so a crash mid-agent resumes on next launch. Generative UI: *"the conversation is the entity graph"* — messages are entities, tool calls are patches, tool results are entities; LLM token streaming buffers into a `messages` row that `live` queries re-render.
- **PEM v1.0 gap list** (§11.2, explicitly "the next PRs to write"):
  1. `@electric-sql/pglite-sync` as hard dep; use `pg.electric.syncShapeToTable` instead of hand-rolled `ShapeStream`.
  2. `LocalOnlyColumns` option on `ElectricTableConfig<T>` (strip `_local_*` before graph write; seam is `toChange` at `electricsql.ts:48`).
  3. `LookupBundle` registry.
  4. `PglitePersistenceAdapter` implementing `GraphPersistenceAdapter`.
  5. CI assertion that every shape factory includes a tenant predicate.
  6. `pgroll` integration script (`scripts/migrate-server.ts`).
- **File layout** (§11.3) proposes new files: `adapters/electricsql-pglite.ts`, `adapters/lookup-bundle.ts`, `migrations/{runner,tracker}.ts`, `persistence/pglite-idb.ts`, `entity-graph-react/src/usePglite{Entity,EntityList,Mutation}.ts`, `entity-graph-tauri/src/pglite-main.ts`.

### Implications for the master goal

- The owner's thinking has already moved *past* Electric as the end-state: the field guide is Electric-centric because it documents what PEM ships today, but the master goal replaces Electric's HTTP shape-stream with **FRF as the sync spine** (and `prometheus-entity-sync` is the PowerSync-model answer — see §7). The field guide's invariants (augmented-table pattern, tenant-predicate enforcement, additive migrations, four-phase boot, lookup bundles) are transport-agnostic and carry over directly to an FRF/CRDT world.
- The `_local_*` column + trigger pattern is the write-tracking substrate an upload queue (to FRF/flint-forge) needs on both pglite (web) and pglite-oxide (Tauri).
- The "conversation is the entity graph" model is the client-side agent memory design; combined with pgvector-in-PGlite it is the local RAG corpus for client agents.
- Settings schemas with synced client/server storage map cleanly onto the lookup-bundle pattern (versioned bundles, 304 revalidation) — that pattern should be generalized into a "synced schema/settings bundle" spec.

### Gaps/risks

- Electric-shaped assumptions (`syncShapeToTable`, shape URLs, 409 must-refetch) are baked into PEM's adapter layer; swapping transports means new adapters, though the graph store, `patches` layer, `FilterSpec` compiler, and boot state machine survive.
- TanStack DB vs entity-graph overlap is acknowledged but unresolved (§6.3, §14 open question 2) — a decision the master spec must make explicitly.
- Multi-tab PGlite worker (SharedWorker + leader election) is required for SaaS; not yet productized in PEM.

---

## 2. `pglite.agent.final.md` — the 3,000-line evidence report

**Path:** `/Users/gqadonis/Projects/prometheus/pglite.agent.final.md` (sections: `pglite_sec01.md` … `pglite_sec11.md`; outline: `pglite.agent.outline.md`)

### What exists

The full research corpus behind the field guide: 11 chapters covering PGlite internals, Electric protocol mechanics, the client/server schema-divergence problem, security, PEM integration, CMS/collaboration patterns, ecosystem comparisons, case studies, and a final recommendations chapter. Notably it does **not** cite `electric-tauri-postgres`, `powersync-service` (as a local repo), or `juit-pgproxy` — those prototypes sit outside the report.

### Key facts and decisions

- **Electric is read-path-only by deliberate design.** The July 2024 "electric-next" clean rebuild *abandoned* bidirectional CRDT sync (legacy Electric had HLC-based, column-level LWW CRDTs with causal history, hidden in internal tables). The Dart client maintainer deprecated the package: *"if your project needs offline CRUD operations, the new Electric won't be your best option."* (§1.2.3, line 57)
- **PowerSync is "the only mature offline-write option"** for PGlite-class stacks (§2.3.1) — bidirectional, persistent upload queue, but SQLite-dialect on the client. Choose PowerSync when: offline writes mandatory, mobile-first (Flutter/RN/Swift/Kotlin SDKs), multi-backend (Postgres GA, MongoDB GA, MySQL beta, SQL Server alpha). (§11.1.3)
- **Decision matrix** (§11.1.1): PGlite standalone / +Electric / +PowerSync / +custom sync, graded by sync direction, offline-write support, complexity.
- **Security architecture** (§11.2.2): Dual-JWT model — Auth Token (identity) exchanged for short-lived (15–60 min) Shape Tokens scoped to exact table + parameterized WHERE; auth proxy sets `table`/`where` server-side; **parameterized WHERE exclusively**; RLS is a backstop, *not* the primary gate, because **RLS is not evaluated during WAL replication** — Electric reads raw WAL and sees all rows. **CVE-2026-40906** (CVSS 9.9, Electric 1.1.12–1.4.x): SQL injection via unvalidated `order_by` concatenation — sync-gateway APIs are an under-tested injection surface.
- **Operational failure modes** (§11.2.3): HTTP 409 `must-refetch` handling (client `onError` must return `{}` or the stream dies permanently); replication-slot health monitoring (`wal_status`: reserved/extended/unreserved/lost; `max_slot_wal_keep_size` ≥ 10 GB); offline write queue state machine `PENDING → IN_FLIGHT → SYNCED / RETRYABLE_ERROR / FATAL_ERROR → DEAD_LETTER` with idempotent ops (client UUIDs + `ON CONFLICT`).
- **Performance** (§11.2.4): OPFS ~2 ms reads vs IDB ~5 ms; Safari's 252-handle OPFS limit blocks PGlite OPFS; granular shapes; CDN-cacheable immutable shape logs (`etag = handle:start:end`); PGlite costs ~100–200 ms WASM init, ~3.5 MB gzipped; 4 GB WASM heap ceiling; 180 MB for a 100k-vector HNSW index.
- **CRDT/text-collaboration pattern** (§8.3.3, §8.5.1): three parallel transports — Electric (or relational sync) for structured data, Yjs/Automerge/Loro for text, WebSocket/WebRTC for presence. CRDT documents stored as JSONB/text columns inside PGlite; relational metadata wins conflicts (LWW/server-authoritative), text merges via CRDT. Automerge 2.0 columnar storage = 10–100× memory/merge improvement; Loro has a Rust/WASM core with TLA+ proofs.
- **Cautionary tales**: **LobeChat** (55k★) adopted PGlite as Client DB (Dec 2024, v1.37.0) with an explicit CRDT-sync vision, then *removed it entirely* — resource consumption and low usage; retrenched to server-only (§9.x, line 2295). **GBrain** hit platform-specific WASM crashes. Smashing Magazine author: a dropped column caused silent sync failure for ~200 users. Conclusion line: *"this is still alpha-grade technology that rewards careful implementation and punishes assumptions."* (line 2934)
- **FOSDEM 2026** had a dedicated "Local-First, sync engine & CRDTs" devroom (NextGraph, Automerge, Yjs, Electric, PowerSync) — ecosystem maturity signal.
- **Trigger.dev production evidence**: Electric at 20k updates/sec, sub-100 ms latency — maps to fabric telemetry/status sync.

### Implications for the master goal

- The report already concluded Electric cannot be the *write* path; the master goal's FRF + CRDT (Loro) + pes-server design is the owner's chosen answer to that gap. The offline write queue + DLQ state machine (§11.2.3) is specified well enough to implement against FRF directly.
- The dual-JWT (auth-token → data-token) pattern is directly reusable: flint-gate mints; FRF sync gateway validates shape/bucket tokens. CVE-2026-40906 is the cautionary precedent for the PSyncV1/bucket-rule surface: parameterized only, allowlisted identifiers.
- The 3-transport collaboration pattern validates the master goal's separation: relational sync through FRF to flint-forge; CRDT text/document sync over WebRTC; presence over lightweight sockets.
- LobeChat's reversal is the top product risk for "PGlite everywhere": resource footprint and operational complexity must be budgeted and measured, and the spec should define when a client falls back to thin/server-only mode.

---

## 3. `electric-tauri-postgres/` — the embedded-Postgres-in-Tauri experiment

**Path:** `/Users/gqadonis/Projects/prometheus/electric-tauri-postgres/` (`README.md`, `WARP.md`, `src-tauri/`)

### What exists

An early (Tauri 1.4-era, React 18, Vite 4) experiment: *"embed as much of postgres as possible and as less of postgres as necessary."* Despite the repo name, it contains **no ElectricSQL code** — "electric" here refers to the Electric project's early native-Postgres direction.

### How it works

- Local-path crate `src-tauri/crates/pg-embed` (the `pg_embed` crate, PostgreSQL 15) downloads and manages full Postgres binaries at runtime, starts a real `postgres` server on port 5432, socket at `/tmp/`, default creds `postgres`/`password` (MD5), hardcoded data path `/home/iib/data_test/db`.
- Rust backend (`src-tauri/src/tauri_postgres.rs`) uses `sqlx` 0.7 + tokio; Tauri commands `send_recv_postgres` / `send_recv_postgres_terminal`; dual windows (app + xterm.js debug PTY console via `portable-pty`).
- Ubuntu-only; Selenium/`tauri-driver` e2e tests.

### Implications for the master goal

- **Lesson: full embedded Postgres binaries are the wrong embedding depth for clients.** This prototype is the "before" picture that justifies the master's pglite-oxide choice (WASM PGlite in-process, no binary download, no port, no daemon lifecycle) — the same conclusion the field guide reaches (pattern T2).
- The dual-window debug-console idea (direct SQL against the local DB) is worth keeping as a dev-tool concept for pglite-oxide apps.
- Dead ends to avoid repeating: hardcoded paths/ports/credentials, runtime binary download (no offline guarantee), daemon lifecycle management in-app, MD5 auth.

### Gaps/risks

Stale (Tauri 1.4, no migrations tooling, no sync, no security posture); treat as historical evidence only.

---

## 4. `powersync-service/` — vendored PowerSync monorepo (the offline-write reference)

**Path:** `/Users/gqadonis/Projects/prometheus/powersync-service/` (`README.md`, `docs/`, `packages/`, `modules/`, `service/`)

### What exists

The full PowerSync backend monorepo (TypeScript) — the most mature open bidirectional sync implementation the owner has on disk. Not a prototype; a vendor codebase kept as the architectural reference.

### How it works

- **`packages/sync-rules`** — the core IP. Sync config defines two declarative SQL operations: *data queries* (`row → list of buckets`) and *parameter queries* (`authenticated user → list of buckets`). Queries are **never executed against a database**; they are evaluated per-row at replication time to pre-bucket data (`SqlDataQuery`, compiled WHERE → `ParameterMatchClause`; heavy operator restrictions on bucket parameters so bucket IDs are always computable).
- **`packages/service-core`** — backend server core; **`packages/jpgwire`** — customized `pgwire` client; **`packages/rsocket-router`** — RSocket reactive-streams routing; **`packages/jsonbig`** — JSON/BigInt parser.
- **`modules/`** — pluggable source replication: `module-postgres`, `module-mongodb` (+ `-storage`), `module-mysql`, `module-convex`.
- **`docs/`** — implementation-grade specs: `docs/specs/sync-protocol.md` (client-facing sync stream messages), `docs/replication/` (source replication, storage writer, checkpoints), `docs/storage/` (bucket storage data structures, invariants, compaction, parameter lookups).
- **`test-client/`** — minimal direct HTTP-stream-sync client for automated testing.

### Implications for the master goal

- **The bucket model is proven and already ported to Rust by the owner**: `prometheus-entity-sync`'s `pes-rules` TOML DSL (`[buckets.*].parameter_queries` + `.data` with `{bucket_parameters.*}` substitution rendered as single-quoted literals) is a direct descendant of PowerSync sync-rules (see §7). The master spec should treat bucket partitioning as *settled design*, and should reuse PowerSync's documented invariants (bucket storage compaction, checkpoint semantics) when hardening pes-server.
- PowerSync's "transform row per bucket" capability is a feature pes-rules should note as a deliberate omission or future work.
- The sync-protocol spec + test-client pattern is the template for conformance-testing PSyncV1 clients (TS/PGlite, Dart/SQLite, Tauri/pglite-oxide).

### Gaps/risks

PowerSync is FSL-licensed business code — read for design, do not copy code (entity-sync README explicitly notes it was "built independently of PowerSync (FSL-1.1-ALv2)"). Client dialect is SQLite, not PGlite/Postgres — the master goal's "same dialect everywhere" is a deliberate differentiator.

---

## 5. `juit-pgproxy/` — Postgres-over-HTTP/WebSocket proxy

**Path:** `/Users/gqadonis/Projects/prometheus/juit-pgproxy/` (`README.md`, `TOKEN.md`, `DOCKER.md`, `workspaces/`)

### What exists

A third-party (Juit) vendored reference: a tiny pooled-Postgres proxy speaking a trivial JSON protocol over HTTP POST (single queries) and WebSocket (multi-statement transactions), designed for **serverless clients** (CloudFlare Workers, Lambda) where connection pools don't work.

### How it works

- Server exposes one interface to one database on any path; LB (NGINX/ALB) provides TLS and path→connection mapping.
- Wire protocol: `{id, query, params}` → `{id, statusCode, command, rowCount, fields[[name,OID]...], rows[[...]]}`; all values are libpq-format strings, converted client-side.
- **Auth (`TOKEN.md`)**: 48-byte one-time tokens — 8 B little-endian timestamp + 8 B random + 32 B HMAC-SHA-256 over (header ‖ db name), base64 → exactly 64 chars; ±10 s clock-drift window; server caches token headers and rejects reuse (replay-proof without a ticket server). Passed as `?auth=` query param because WebSocket UPGRADE can't set headers.
- Components: `@juit/pgproxy-{server,cli,pool,types,persister}` (persister adds CRUD abstraction), clients for Node, WHATWG+WebCrypto (workerd-tested), and libpq.
- Benchmarks (their numbers, AWS, ~25 ms away): `pg` multi-connect ~202 ms/query; `pg` single-conn ~45 ms; pgproxy HTTP ~70 ms; **pgproxy shared WebSocket ~30 ms/query** — faster than `pg` itself.

### Implications for the master goal

- Role in the fleet: the **thin-client/serverless escape hatch** — when a client can't (or shouldn't) run PGlite at all (edge workers, tiny embeds, the LobeChat-lesson fallback mode), a pooled Postgres-over-WS proxy keeps the Postgres-everywhere story without a local engine.
- The HMAC one-time-token design is a proven, simple pattern for authenticating WebSocket upgrades — relevant to FRF gateway and pes-gateway auth handshakes (both face the same "no custom headers on WS upgrade" constraint).
- Not a sync technology: no caching, no offline, no conflict handling — it is raw remote SQL. The master spec should position it as the complement, not a competitor, to local-first sync.

---

## 6. `universal-agent-runtime/` (UAR v1.0.0) — the governed agent runtime

**Path:** `/Users/gqadonis/Projects/prometheus/universal-agent-runtime/` (`README.md`, `CLAUDE.md`, `docs/`)

### What exists — agent runtime capabilities

A single Rust/Axum process (port 1906) owning inference routing, agent execution, governance, retrieval, and event distribution, with a strictly-layered React 19 + TS frontend. Status: v1.0.0; `server-full` bundle is the product; licensing AGPL-3.0-only (SDKs MIT).

- **Model routing**: all LLM access via `liter-llm` (GQAdonis/liter-llm) — unified `provider/model` addressing, 142+ providers, catalog of 269 providers compiled at build time from models.dev; `POST /api/uar/route` with capability requirements (`needs_tools`, `needs_vision`, `min_context`). OpenAI-compatible `/v1` API is Tier 1; Anthropic path Tier 1; local FastEmbed embeddings Tier 1. Adaptive learned routing = Experimental.
- **Governance**: Cedar policy engine, hot-reloaded PolicySet; **Deny is final and cannot be overridden by user approval**; MCP-discovered and native tools share schema validation, Cedar policy, approval, hard-deny, audit controls.
- **Tools/skills — three execution models** (`docs/skill-authoring.md`, `docs/NATIVE_SKILLS.md`):
  1. `Manifest` — `SKILL.md` (YAML frontmatter: name/version/triggers/allowed-tools) scanned from `crates/prometheus-skill-system/skills` (built-in, DELETE → `409 system_skill_immutable`) or user dirs.
  2. `Wasm` — **WebAssembly Component Model** skills targeting WIT world `uar:skill@0.1.0` (`world skill { export run: func(input: string) -> result<string, string>; }`); authored in Rust (`cargo component`), JS/TS (`jco`), Python (`componentize-py`), TinyGo; `.wasm` or AOT `.cwasm` (via `wasmtime compile`) dropped into `~/.uar/skills/wasm-builtin/` or `~/.uar/skills/user/`; dispatch currently an untyped stub with wit-bindgen end-to-end invocation as follow-up (WIT contract stable).
  3. `Native` — in-process Rust via the `NativeSkill` trait + `NativeSkillRegistry` (`src/uar/runtime/native_skill.rs`), priority over MCP tools, bypasses MCP serialization for hot paths.
- **WASM sandbox** (`docs/WASM_RUNTIME.md`, feature-gated `wasm-runtime`): Wasmtime + WASI P1, deny-by-default capabilities, fuel metering (`max_fuel`), per-run `Store` isolation, host functions `uar_log`/`uar_emit_event`. Native WASM tools = Preview/opt-in; **browser-side arbitrary WASM execution is unsupported**.
- **Protocols**: AG-UI is the event-transport vocabulary (SSE normalized run events: TextDelta/ToolStart/ToolEnd/Citation; A2UI surface changes as StatePatch events; late joiners catch up via `GET .../a2ui/surface-replay`); **A2UI is the validated declarative rendering contract** — certified catalog `urn:uar:a2ui:catalog:1` (9 protocol components) + `urn:uar:a2ui:catalog:1+entities` (7 entity extensions); unknown component types **fail closed**; three renderers (React first-party, Lit, Svelte) on vendored `@a2ui/web_core` with cross-renderer semantic-conformance fixtures. Also A2A endpoint, MCP client + governed tool bridge, `/v1` OpenAI-compat.
- **Agent definition standard**: `docs/agents/AGENTS_SPEC_RFC.md` — RFC-0001 UAR-AGENT-MD: Markdown agent artifacts with 15 REQUIRED sections (Metadata, Identity, UI (A2UI), Capabilities, Skills, Tools, MCP Servers, Knowledge Base, Memory Model, A2A Contracts, Governance, Budgets & Constraints, Execution Model, Observability, Deployment Profiles), deterministically compiled to signed JSON Descriptors.
- **Persistence**: SurrealDB is authoritative in the Stable bundle; **Postgres (+pgvector) is a supported remote persistence provider** (`config.remote.postgres.yaml`, `UAR_PERSISTENCE__DATABASE_URL`, configurable `vector_dimension`); **PGlite is the local browser/desktop cache for threads and messages**; versioned server events reconcile the client entity graph — *server entity versions win conflicts; unsent drafts remain client-owned*.
- **Realtime** (`docs/realtime.md`): SurrealDB live queries (`db.select(table).live()` per topic: knowledge_bases, knowledge_documents, agents, providers, models, skills, settings) → `tokio::sync::broadcast` → `GET /api/live/{topic}` SSE (JWT-auth) → a single `EventSource`-backed entity-graph adapter on the client.
- **Plugin architecture** (`docs/plugins/`): plugins are first-class participants — listen to any `uar-realtime` channel (`agent:run:{id}`, `session:{id}`, `plugin:{name}:{scope}`), spawn code-runner sandboxes (microVMs), call LLM via UAR routing, emit events, expose MCP tools.
- **Tauri strategy** (`docs/TAURI_STRATEGY.md`, historical/Preview): **Localhost-server decision** — Rust spawns Axum on an ephemeral port (`TAURI_LOCALHOST_PORT` override), WebView points at `http://127.0.0.1:{port}` (never `tauri://` as primary origin) for 100% SSE/EventSource compatibility; `/healthz` + `/readyz` gating before WebView load; SSE `id:` fields + `Last-Event-ID` replay; MCP servers shipped as pre-packaged sidecar binaries (no runtime `npx`), resolved via `resource_dir()` with `MCP_CONFIG_PATH`/`MCP_SERVER_DIR`.
- **Platform support** (`docs/product-support-matrix.{md,json}`): Web Stable; Desktop/Tauri Preview; Mobile Experimental; browser WASM unsupported.
- **Deployment ownership boundary** (README): Flint Gate owns edge auth, FRF owns durable realtime distribution, Flint Forge owns RLS-backed data APIs + edge execution, Flint Platform Agent owns administration — **UAR retains inference, routing, agent execution, governance**. Quality gates: 60% coverage floor, RAGAS/DeepEval eval, A2UI render budgets (16 ms initial / 8 ms streaming), axe a11y, SLSA L2 supply-chain (Sigstore/in-toto), reproducible builds.

### Implications for the master goal

- **UAR is the cloud/hosted agent half of the client↔cloud agent cooperation story.** Its AG-UI event stream + A2UI declarative surfaces + Cedar governance are exactly the server-side vocabulary the master goal names. The client-side agent (in `gen_ui_core` per TJ-ARCH-MOB-001) should speak AG-UI/A2UI and reuse UAR-AGENT-MD as the agent artifact format so agents are portable between client and cloud.
- **The three-tier skill model (Manifest/WASM-component/Native) is the proven template** for "WASM component model adds native skills for agent harnesses" — the master spec can adopt `uar:skill@0.1.0`-style WIT worlds rather than inventing new ones, and flint-forge's Kiln (signed WASM edge functions) is the server-side counterpart.
- The "SurrealDB authoritative + PGlite client cache + versioned events, server wins conflicts, drafts client-owned" reconciliation rule is a working precedent for settings/state sync semantics between client and server stores.
- The Tauri localhost-server strategy is a **contested point**: TJ-ARCH-MOB-001 scaffolds Tauri with `invoke()` commands and the hybrid standard expects in-process Rust. UAR's localhost pattern exists because SSE/EventSource doesn't work over `tauri://`. The master spec must decide per-surface: in-process FFI vs localhost sidecar — UAR's documented rationale (SSE compatibility, CORS origins, health handshake) is the evidence base.
- UAR's Postgres persistence provider means a flint-forge-hosted Postgres can serve as UAR's authoritative store — the integration seam for "cloud-hosted agents" sharing the central Postgres with sync clients.
- Licensing constraint: UAR runtime is AGPL-3.0-only (SDKs MIT; Rust SDK `embedded` feature links AGPL). Client-side reuse of UAR code inside commercial/hybrid apps must go through the MIT SDKs or process boundaries.

---

## 7. Bonus: directly reusable sibling projects

### 7.1 `prometheus-entity-sync` — the owner's own PowerSync-model engine (Rust, MIT)

**Path:** `/Users/gqadonis/Projects/prometheus/prometheus-entity-sync/README.md`, `docs/sync-rules-reference.md`

- **What it is:** "A Rust-native, MIT-licensed sync engine for bidirectional Postgres → PGlite → SQLite replication. Built independently of PowerSync (FSL-1.1-ALv2) on top of flint-realtime-fabric (FRF), reusing its WAL CDC, CRDT (Loro), and op-log machinery."
- **`pes-server`** — standalone sync gateway: reads Postgres WAL via `frf-postgres-cdc`, buckets changes per user via TOML sync-rule DSL, streams over WebSocket + MessagePack (**PSyncV1** protocol).
- **Crates:** `pes-core` (domain types), `pes-rules` (TOML DSL + `BucketAssigner` — *the security boundary*: JWT claims → authorized buckets, parameterized SQL only, no string interpolation), `pes-oplog` (per-bucket append-only op log on `frf-store-redb`), `pes-snapshot` (keyset-paginated initial snapshot), `pes-protocol` (PSyncV1 codec), `pes-gateway` (WS lifecycle + auth), `pes-server`, `pes-sdk-rust`.
- **Client SDKs:** `@prometheus-ags/entity-sync-core` (TS/PGlite: protocol client, reconnect, JWT mgmt), `@prometheus-ags/entity-sync-pglite` (PGlite extension applying delta ops), `@prometheus-ags/entity-sync-react` (hooks), `@prometheus-ags/entity-sync-tauri` (Tauri IPC, via **pglite-oxide**), `prometheus_entity_sync` (Dart/Flutter, SQLite via `drift`).
- **Sync-rules TOML** (`docs/sync-rules-reference.md`): `[buckets.<id>]`, `parameters`, `parameter_queries` (receive JWT `sub` as `$1`), `data` queries with `{bucket_parameters.<name>}` substitution always rendered as single-quoted SQL literals; parsed by `pes_rules::parse_sync_rules`, validated before gateway load.

**Implication:** This is *the* prior art for the master goal's sync plane — it already implements "pglite (web) and pglite-oxide (Tauri) sync to central Postgres through FRF" in the PowerSync bucket model, with CRDT (Loro) available from FRF. The master spec should adopt pes-server as the sync gateway baseline and specify what flint-forge adds (RLS-backed APIs, Kiln WASM functions) around it.

### 7.2 `prometheus-entity-management` (PEM 3.x) — the client entity graph

**Path:** `/Users/gqadonis/Projects/prometheus/prometheus-entity-management/packages/`

- Packages include: `entity-graph-core` (Zustand graph store, `patches` vs `entities` layers, `local-first-runtime.ts`/`local-graph-runtime.ts` with `ReplayRetryPolicy` 5 attempts 500 ms→30 s equal-jitter, `schema-from-sql.ts` `parseCreateTable`/`registerEntityFromSql`, `view/evaluator.ts` filter/sort engine), `entity-graph-react` (`useLiveQuery`, suspense hooks), `entity-graph-sync`, `entity-graph-tauri`, `entity_graph_flutter`, and binding/render packages directly on-goal: **`a2ui-react`, `entity-graph-htmx`, `entity-graph-alpine`, `entity-graph-svelte`, `entity-graph-solid`, `entity-graph-web-components`, `entity-graph-mcp`, `entity-graph-a2a`, `entity-graph-sdl`, `entity-graph-cli`**.
- Adapters (per the reports): `createElectricAdapter`, `createTenantScopedElectricAdapter` (`electricsql-tenant.ts` — refuses shapes without `tenantColumn`), `createWebSocketAdapter`, `createConvexAdapter`, `createSurrealLiveAdapter`, **`createFlintAdapter` (Flint Realtime Fabric)**, `createPGlitePersistenceAdapter` (full-graph snapshot into a PGlite `_graph_snapshot` table; `hydrateGraphFromStorage`), `startLocalFirstGraph` (hydration + persistence + sync status + offline detection + replay with `retryPolicy` + `poisonHandler`), `useGraphSyncStatus` (hydrating/syncing/online/offline/ready), `FilterSpec`/`SortSpec` compiling to `toSQLClauses`/`toRestParams`/`toGraphQLVariables`/`toPrismaWhere`, `useEntityView` with `completeness: 'hybrid'`.
- Design rule (CONTRIBUTING, quoted in the report): *"The RealtimeManager handles coalescing, batching, and writing to the entity graph. Your adapter should not touch the graph directly."*

**Implication:** PEM is the client-side state substrate for web (and the pattern source for Flutter/Tauri stores); it already has an FRF adapter and A2UI/HTMX render packages — the "A2UI/AG-UI/HTMX UI modules" leg of the master goal lands here, not in new code. The settings-schema sync story should be a PEM adapter + bundle spec.

---

## 8. Flint auth prior art (quick reads)

### 8.1 `FLINT_ANON_SERVICE_ROLE_KEYS_SPEC.md` (1000 lines, v1.0 Draft, 2026-07-15)

- Specifies Supabase-style dual-key architecture for the fabric: `anon` (public, RLS-gated) and `service_role` (privileged, RLS-bypass, never on clients), plus `authenticated` and a **new 4th `agent` role** (RLS-governed, agent-specific claims like `workflow_id` scoping, delegatable tokens).
- Key decisions: concept lives in **flint-forge** (`ext-flint-auth` creates Postgres roles `anon`/`authenticated`/`service_role`); **signing authority stays in flint-gate** (`forge-cli` is a thin wrapper over flint-gate's admin API — prevents key proliferation); default **Ed25519** for new keys (HS256 legacy); structured key prefixes `flint_pk_...` / `flint_sk_...` for secret-scanning; zero-downtime independent rotation of API keys and JWT signing keys; browser detection + IP allowlisting + Cedar gating as service_role leak defenses.

### 8.2 `flint-architecture-module-ownership-report.md` (644 lines)

- Module ownership matrix: **flint-gate = identity plane** (JWT verify/mint, anonymous auth, API keys, Kratos, OAuth, Cedar NHI principals Agent/Service/User); **flint-forge = data-access plane** (Postgres roles, RLS, PostgREST-like REST/GraphQL, WASM edge functions, pgrx); **flint-platform-agent = Cedar policy lifecycle** for non-human identities; **flint-realtime-fabric = event-stream auth enforcement** consuming gate identity context; **UAR = agentic streaming, NOT core auth infra**.
- The "decoupled enforcement" model (Supabase analog: GoTrue owns token lifecycle, PostgREST owns role switch, Postgres owns row enforcement). CDC events filtered by role/tenant in FRF; WS connections gated by identity; gRPC propagates identity metadata.
- Also notes (from flint-forge README): Forge's GraphQL subscription default source is Postgres LISTEN/NOTIFY; the FRF gRPC change source "currently fails closed — FRF does not yet expose the `WatchEntityType` RPC it depends on" — an active integration gap between Forge and FRF.

**Implication:** The master goal's auth story is already decided: gate mints (incl. `agent` role tokens for client/cloud agents), forge enforces via RLS + roles, FRF enforces on the event plane, and sync gateways (pes-server) consume JWT claims for bucket assignment. The anon/service_role spec gives the client key model (`flint_pk_` publishable key on pglite clients; `service_role` never ships).

---

## 9. Consolidated implications for the master goal

1. **Sync plane:** Use `prometheus-entity-sync` (pes-server, PSyncV1, bucket rules) as the gateway baseline on FRF — it is the owner's MIT, Rust-native answer to the exact problem PowerSync solves, already wired to FRF's WAL CDC and Loro CRDT, with TS/PGlite, Dart/SQLite, Rust, and Tauri/pglite-oxide SDKs. The Electric-era PEM adapters remain useful for Electric deployments but are not the strategic path; the *invariants* (tenant-predicate enforcement, augmented `_local_*` tables, additive-only migrations, four-phase boot, write-queue + DLQ state machine) must be re-expressed on the pes/FRF transport.
2. **Schema/migrations:** additive-only + expand-contract, `schema_version` table with compatibility-window checks, CI drift detection (table/column/index parity between server and client schemas), pgroll server-side. Non-negotiable per both reports.
3. **Security:** dual-JWT (flint-gate auth token → short-lived shape/bucket token), parameterized-only sync rules (pes-rules already enforces), RLS as backstop (never evaluated in WAL), CVE-2026-40906 as the injection-surface lesson, `agent` role tokens for agent workloads, `flint_pk_`/`flint_sk_` key hygiene.
4. **Agents:** UAR is the cloud agent runtime (keep at process boundary due to AGPL); client agents live in `gen_ui_core` (TJ-ARCH-MOB-001 invariant) using PEM's graph as memory ("conversation = entity graph", patches = pending intent, pending-actions queue = durable agent loop). Shared vocabularies: AG-UI (events), A2UI (declarative UI, fail-closed catalogs, PEM's `a2ui-react`/`entity-graph-htmx` renderers), UAR-AGENT-MD (agent artifacts), `uar:skill@0.1.0`-style WIT worlds for WASM component skills (Rust/jco/componentize-py/TinyGo), flint-forge Kiln for signed server-side components.
5. **CRDT:** relational data via pes/FRF buckets; document/text CRDT (Loro — already in FRF) over WebRTC (str0m signaling spike already proven in FRF phase 18); presence over lightweight WS. CRDT docs stored as JSONB/text columns in PGlite; relational metadata wins conflicts. lora-rs would be a new transport behind the same CRDT sync service abstraction — no prior art in the fleet.
6. **Thin-client fallback:** juit-pgproxy-style pooled Postgres-over-WS (with its HMAC one-time-token WS auth) as the complement for clients that shouldn't run PGlite — also the answer to the LobeChat lesson (offer a server-only mode).
7. **Settings/schemas sync:** generalize the lookup-bundle pattern (versioned JSON bundles, ETag/304) into a settings-schema spec with client (PGlite) and server (Postgres) storage — no existing artifact covers this yet.
8. **Tauri strategy fork:** decide in-process pglite-oxide + `invoke()` (TJ-ARCH-MOB-001 default, pattern T2) vs UAR's localhost-sidecar pattern (only where SSE/EventSource in the webview is required). The field guide's T1→T2 graduation path is the default.

## 10. Gaps and risks (fleet-wide)

- **No prior art for decentralized packaging** (IPFS/OCI/git-like versioning of skills/components) in the surveyed set — flint-forge's extension registry (IPFS/OCI/S3 stores, signing) is the only candidate and was out of this assignment's scope; needs its own deep read.
- **Forge↔FRF integration gap**: `WatchEntityType` RPC missing in FRF (Forge fabric change-source fails closed).
- **pes-server maturity unknown** beyond README/docs — no conformance suite located; PowerSync's `docs/specs` + test-client is the model to copy.
- **UAR WASM skill dispatch is stub-level** (untyped; wit-bindgen end-to-end pending) and browser-side arbitrary WASM is explicitly unsupported — client-side component execution must be specced fresh (gen_ui_core wasm target per TJ-ARCH-MOB-001).
- **Electric-shaped PEM adapters vs pes transport** — PEM v1.0 gap list (§1, items 1–6) was written for Electric; each item needs re-triage for the pes/FRF world.
- **Resource/complexity risk** (LobeChat, GBrain): PGlite footprint (~3.5 MB bundle, 100–200 ms init, 4 GB heap ceiling, HNSW index memory) must be budgeted per platform; define thin-client fallback from day one.
- **Auth token on WS upgrade** (query-param tokens) is solved by pgproxy's HMAC pattern but must be unified with flint-gate JWT minting so pes-gateway/FRF don't invent a third scheme.
- **Licensing**: powersync-service is FSL (read-only reference); UAR is AGPL (process boundary / MIT SDKs only); prometheus-entity-sync is MIT (safe to build on).

---

## Appendix: source inventory

| Source | Path | Size/lines | Role |
|---|---|---|---|
| PGlite field guide | `prometheus/PGLITE-LOCAL-FIRST-ARCHITECTURE.md` | 952 | Decision framework (Electric-era) |
| PGlite evidence report | `prometheus/pglite.agent.final.md` (+ `pglite_sec01..11.md`, `pglite.agent.outline.md`) | 3000 | Full research corpus |
| Embedded-PG Tauri experiment | `prometheus/electric-tauri-postgres/` (`README.md`, `WARP.md`, `src-tauri/crates/pg-embed`) | small | Negative/lesson prior art |
| PowerSync monorepo | `prometheus/powersync-service/` (`packages/sync-rules`, `docs/specs/sync-protocol.md`, `docs/storage/`, `docs/replication/`, `modules/`) | vendor | Offline-write/bucket-model reference (FSL) |
| PG proxy | `prometheus/juit-pgproxy/` (`README.md`, `TOKEN.md`) | small | Thin-client + WS-auth reference |
| UAR | `prometheus/universal-agent-runtime/` (`README.md`, `CLAUDE.md`, `docs/{NATIVE_SKILLS,WASM_RUNTIME,TAURI_STRATEGY,realtime,skill-authoring}.md`, `docs/plugins/`, `docs/agents/AGENTS_SPEC_RFC.md`, `docs/protocols/{ag-ui,a2ui}-profile.md`, `config.remote.postgres.yaml`) | large | Cloud agent runtime, skills, A2UI/AG-UI |
| Auth specs | `prometheus/FLINT_ANON_SERVICE_ROLE_KEYS_SPEC.md`, `prometheus/flint-architecture-module-ownership-report.md` | 1000 + 644 | Key model, module ownership |
| Entity sync | `prometheus/prometheus-entity-sync/` (`README.md`, `docs/sync-rules-reference.md`) | medium | Owner's Rust sync engine (MIT) — primary reuse |
| Entity management | `prometheus/prometheus-entity-management/packages/` | large | Client entity graph + adapters + A2UI/HTMX packages |
