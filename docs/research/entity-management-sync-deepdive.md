# Entity Management & Sync — Deep-Dive Research Brief

> **Slug:** entity-management-sync-deepdive
> **Researcher:** KNOWME_RESEARCHER (deep-research swarm)
> **Date:** 2026-07-18
> **Scope:** `/Users/gqadonis/Projects/prometheus/prometheus-entity-management` (PEM) and `/Users/gqadonis/Projects/prometheus/prometheus-entity-sync` (PES), plus external verification of third-party dependency status.
> **Lens:** master goal — local-first + realtime architecture where PGlite (web) / pglite-oxide (Tauri) clients sync through flint-realtime-fabric (FRF) to central Postgres (flint-forge), with CRDT sync, WASM components, and cross-platform (React/Tauri/Flutter) reach.

---

## 1. What Exists (Facts)

### 1.1 prometheus-entity-management (PEM) — repo state

- **Version:** monorepo at `3.0.0-alpha.0` (all packages). The pre-v3 monolith was `1.3.2` (see `CHANGELOG.md`). Git HEAD: `dd5d70c` "docs(kbd): sync hooks log … add v4 openspec changes + pglite research" (2026-07-17 era).
- **License:** MIT © Prometheus AGS / KnowMe LLC. Repo: `github.com/Prometheus-AGS/prometheus-entity-management`.
- **Layout:** pnpm workspace + turbo. 15 entries under `packages/`, plus `examples/` (vite-app, nextjs-app, supabase), `prometheus-entity-skills/`, `extension/` (Chrome DevTools), `openspec/changes/`, `.kbd-orchestrator/phases/` (phase-v1 … phase-v4), `docs/`.

**Package inventory (`packages/`, all `3.0.0-alpha.0` unless noted):**

| Package | Name | Kind | Status |
|---|---|---|---|
| `entity-graph-core` | `@prometheus-ags/entity-graph-core` | TS | Real. Framework-agnostic (zero-React) Zustand graph: `graph.ts`, `engine.ts`, `transport/registry.ts`, `local-first-runtime.ts`, `adapters/`, `view/`, `crud/`, `ai-interop.ts`, devtools time-travel. |
| `entity-graph-react` | `@prometheus-ags/prometheus-entity-management` | TS | Real. React hooks (`useEntity`, `useEntityList`, `useEntityView`, `useEntityCRUD`, `useGQLEntity`, …), UI (`EntityTable`, sheets), GraphQL, Suspense, DevTools. This keeps the v1.x package name. |
| `entity-graph-svelte` | `@prometheus-ags/entity-graph-svelte` | TS | Real. Svelte 5 runes bindings. |
| `entity-graph-solid` | `@prometheus-ags/entity-graph-solid` | TS | Real. `createResource` bindings. |
| `entity-graph-alpine` | `@prometheus-ags/entity-graph-alpine` | TS | Real. `$entity(type,id)` / `$entityList(type,query)` magics. |
| `entity-graph-htmx` | `@prometheus-ags/entity-graph-htmx` | TS | Real. Node.js SSE fragment server streaming HTML entity fragments (idiomorph/morph model). |
| `entity-graph-web-components` | `@prometheus-ags/entity-graph-web-components` | TS | Real. Lit 3 `<entity-list>`, `<entity-detail>`, `<entity-form>` custom elements. |
| `entity-graph-sync` | `@prometheus-ags/entity-graph-sync` | TS | Real. Pluggable `SyncProvider` peer sync: `YjsProvider` (WebSocket via `y-websocket`, WebRTC via `y-webrtc`) + `LoroProvider` (`loro-crdt`), `bridge.ts` graph↔CRDT, `registry.ts`. Peers are optional deps. |
| `entity-graph-tauri` | `@prometheus-ags/entity-graph-tauri` | TS + Rust | Real. Tauri v2 plugin; `rust-plugin/` crate (`entity-graph-tauri`), tauri-specta v2 generated TS bindings (`cargo build --features generate-bindings`), typed commands (`graph_upsert_entity`, `graph_persist_snapshot`, …) + events (`entity-changed`, …). **Persistence is SQLite via `@tauri-apps/plugin-sql`, NOT pglite-oxide.** |
| `entity_graph_flutter` | `entity_graph_flutter` (pub) | Dart | Real but partial. See §1.4. |
| `entity-graph-cli` | `entity-graph-cli` | Rust crate | Real. `init` (writes `schema.json`), `generate` → TypeScript types + transport-registration stubs. Tera-style scaffolding. |
| `entity-graph-mcp` | `entity-graph-mcp` | Rust crate | Real. MCP server: stdio + Streamable HTTP (Axum). Resources `entity://{type}[/{id}]`; tools `entity_list_types`, `entity_query`, `entity_upsert`, … |
| `entity-graph-a2a` | `@prometheus-ags/entity-graph-a2a` | TS | Real. A2A v1.0 server: AgentCard, Task routing to graph mutations/queries, Artifact results. |
| `entity-graph-sdl` | `@prometheus-ags/entity-graph-sdl` | TS | Real. JSON/TOML Schema Definition Language + validated IR consumed by Rust CLI, TS generators, and the Dart SDL parser. The cross-language contract. |
| `a2ui-react` | `@prometheus-ags/a2ui-react` | TS | Real (alpha). `EntityChat`, `EntityCopilot`, `EntityStream`, `EntityDiff`, `EntityApproval` — AI-native components over the graph. |

**Core adapters (`packages/entity-graph-core/src/adapters/`):**
- `electricsql.ts` — ElectricSQL/PGlite shape changes → graph (`createElectricAdapter`).
- `electricsql-tenant.ts` — `createTenantScopedElectricAdapter`: refuses shapes without `tenantColumn`; builds `WHERE` from validated `{ companyId }` claim (RLS-widening guard).
- `flint.ts` — **FRF bridge (GAP-1):** consumes `@prometheusags/frf-entity-management`'s `RealtimeAdapter.watchEntities()` AsyncIterable (plain `EntityEvent` facade; no proto types leak, no hard frf-sdk dep). `createFlintAdapter`, `publishFlintMutation`, optional checkpoint store for resume-from-offset (`offset: bigint`).
- `surreal-live.ts` — SurrealDB live-query adapter (same checkpoint pattern).
- `pglite-persistence.ts` — `createPGlitePersistenceAdapter(pglite)`: `GraphPersistenceAdapter` storing graph snapshot in a PGlite table (`_graph_snapshot` default). No hard PGlite dep (minimal-surface client).
- `tauri-sql-persistence.ts` — same contract over `@tauri-apps/plugin-sql` `Database` (SQLite, `?` binds). Pairs with the PGlite one so the same local-first runtime persists across web and desktop.
- `realtime-manager.ts` — shared change shape, 16 ms (one animation frame) coalescing window, delete-wins semantics.
- `types.ts`, `realtime-adapters.ts` (WebSocket, Supabase Realtime, Convex, GraphQL subscriptions).

**Local-first runtime (`entity-graph-core/src/local-first-runtime.ts`):**
`startLocalFirstGraph(opts)` → hydration, persistence, pending-action replay with `ReplayRetryPolicy` (exponential backoff; exhausted actions → opt-in `poisonHandler`), `useGraphSyncStatus` (online/offline/hydrating/syncing/ready), `persistGraphToStorage`, `hydrateGraphFromStorage`, `replayActionWithRetry`. Sync metadata per entity: `$synced`, `$origin` (`server|client|optimistic`), `$updatedAt`.

**Docs:** `README.md` (v1.3.2-era API reference), `ARCHITECTURE.md` (three-layer model, engine, view layer, CRUD, SSR hydration), `STRATEGIC-ROADMAP.md` (796 lines, dated 2026-07-21, "Research-complete → Specification Draft": Phases 0–6 incl. multi-framework, Tauri/Flutter, AI-native AG-UI/A2A/MCP, local-first + Yjs/Automerge/Loro peer sync, Rust CLI codegen, A2UI library — **much of Phases 1–3 and 5 is now implemented as the v3 packages**), `comparative-review.md` (2026-06-22, vs TanStack Query v5 / Apollo v3 / RTK Query), `docs/pglite-local-first-architecture-research.md` (778 lines, captured 2026-07-13 — PGlite internals, Electric shape protocol, schema divergence, security, Tauri options, decision framework), `docs/evolution/` (roadmap + `COMPARATIVE-REIVEW-06222026.md` [sic]), `docs/advanced.md`, `docs/extension-architecture-notes.md`, `docs/tanstack-*.md`.

### 1.2 prometheus-entity-sync (PES) — repo state

- **Version:** Rust workspace `0.1.0`, edition 2024, `rust-version = 1.85`, MIT. Repo: `github.com/prometheusags/prometheus-entity-sync`. Git HEAD: `792a104` "fix(pes-rules,pes-gateway): scope bucket_id per resolved params + pglite two-user integration tests" (2026-07-17).
- **Self-description:** "Rust-native, MIT-licensed sync engine for bidirectional Postgres → PGlite → SQLite replication. Built independently of PowerSync (FSL-1.1-ALv2) on top of flint-realtime-fabric, reusing its WAL CDC, CRDT (Loro), and op-log machinery."
- **Workspace deps on FRF by path** (`Cargo.toml`): `frf-postgres-cdc`, `frf-crdt`, `frf-store-redb`, `frf-ports`, `frf-domain`, `frf-broker-iggy` — all `../flint-realtime-fabric/crates/*`.

**Crates (`crates/`):**

| Crate | Lines/files | Purpose | Status |
|---|---|---|---|
| `pes-core` | 312 (types.rs) | Domain types: `PgLsn`, `SyncRule`, `BucketAssignment`, `BucketId`, `TokenClaims` (sub/tenant_id/exp/custom), `BucketOp`, `Op` (`Upsert(JSON)` / `Delete` / `CrdtPatch(Vec<u8>)`), `BucketChecksum`, `SyncError`. Proptest roundtrips. | Real |
| `pes-rules` | 5 files | TOML sync-rule DSL: `parser.rs` (`parse_sync_rules[_str]` → `SyncRuleSet`), `validator.rs` (4 rejection rules), `template.rs` (`substitute`, `validate_safe_value` allowlist `^[a-zA-Z0-9_-]{1,128}$`), `assigner.rs` (`BucketAssigner`: JWT-claim → parameterized SQL → bucket; cache TTL + `spawn_cache_sweeper`; `find_affected_buckets`). | Real, security-reviewed |
| `pes-snapshot` | — | `SnapshotStream` — keyset-paginated initial snapshot (fixed `sq.id` cast bug). | Real |
| `pes-oplog` | — | Per-bucket append-only op log over `frf-store-redb`, `drain_since` range scans, running checksums. | Real |
| `pes-router` | 3 files (~400) | `WalToBucketRouter` — WAL events (via in-process broker) → affected buckets via `BucketAssigner.find_affected_buckets` → append to oplogs. `RouterMetrics`. | Real |
| `pes-protocol` | 4 files (~180) | PSyncV1 codec: `ServerMessage` (SnapshotBegin/Batch/Complete, Delta, Checkpoint, Keepalive, Error), `ClientMessage` (Subscribe{buckets, token, resume_lsn, protocol_version}, Ack, Write{entity_type, entity_id, op}, Ping), MessagePack (`rmp-serde`), `PROTOCOL_VERSION = 1`. | Real |
| `pes-gateway` | 5 files (~1,330) | WebSocket gateway: `auth.rs` (350 lines, JWT validation), `connection.rs` (553 lines: subscribe handshake, write authorization + apply, 50 ms `poll_deltas` loop), `server.rs`, `error.rs` (client-facing `SyncError` redaction). | Real |
| `pes-server` | 5 files | Deployable binary: `config.toml`, WAL→router→oplog→gateway wiring, `InProcessBroker` (channel `entity/changes`), replication slot `pes_server_slot`, publication `pes_pub`, `/health` `/ready` `/metrics` on separate port, 30 s SIGTERM drain. `Dockerfile` at repo root. | Real |
| `pes-sdk-rust` | **1 line** | `//! Native Rust client SDK for prometheus-entity-sync.` | **STUB** |

**TS packages (`packages/`, all `0.1.0`):**

| Package | Purpose | Status |
|---|---|---|
| `@prometheus-ags/entity-sync-core` | `SyncClient` (connect/Subscribe/snapshot+delta dispatch/reconnect with `ReconnectScheduler` backoff/proactive JWT refresh via `jwt.ts`/resume from last acked LSN), MessagePack codec, messages mirror of pes-protocol. **Writes issued while disconnected throw (dropped, not queued).** | Real, built (`dist/`) |
| `@prometheus-ags/entity-sync-pglite` | (a) `prometheusSync(config)` — PGlite `Extension`: deltas applied as SQL via `applyOps`, `db.sync` namespace (`subscribeBucket`, `getStatus`, `pause`, `resume`). (b) `applyOps(db, ops)` — transactional op application: `Upsert` → `INSERT … (id, payload) ON CONFLICT (id) DO UPDATE SET payload`; `Delete`; `CrdtPatch` → stored as opaque `crdt_state` bytes (no CRDT runtime client-side). Identifier allowlist. (c) **`prometheusSyncTransport`** (`pem-transport.ts`) — PEM `EntityTransport<T>` over SyncClient+PGlite: `authoritative: true`, `staleTime: undefined`, `list()/get()` compile `FilterSpec`/`SortSpec` to parameterized SQL, `subscribe()` maps applied deltas to `ChangeEvent`s (read-back-after-apply), `write()` → `client.write`, Zustand-compatible `statusStore`. Peer-dep on `@prometheus-ags/entity-graph-core ^3.0.0-alpha.0`. Integration tests (vitest, two-user PGlite). | Real |
| `@prometheus-ags/entity-sync-react` | React hooks over entity-sync-core. | Real (small) |
| `@prometheus-ags/entity-sync-tauri` | "TypeScript IPC bindings for the prometheus-entity-sync Tauri plugin". **`src/index.ts` = `export {};`** | **EMPTY STUB** |

**Docs/examples:** `docs/sync-rules-reference.md` (complete DSL reference + security model), `examples/docker-compose/` (Postgres init SQL, `sync-rules.toml`, `config.toml`, compose file — runnable demo).

**README claims vs reality:** the README advertises "Client SDKs — TypeScript (browser, PGlite), Dart (Flutter, SQLite via `drift`), Rust (native), and a Tauri plugin (desktop, via `pglite-oxide`)". **Only the TypeScript SDK exists.** `pes-sdk-rust` is a one-line stub; no Dart code exists anywhere in the repo; the Tauri package is an empty module.

### 1.3 The v4 program (PEM `openspec/changes/`) — plan vs done

Umbrella `2026-07-13-v4-prometheus-entity-sync`: 14 changes, 8 waves. **Waves 1–5 archived (done):** repo-scaffold, pes-core-types, sync-rules-dsl, bucket-assigner (⚠ marked CRITICAL; includes `SyncError` redaction + cache-sweep fixes), pes-snapshot, pes-oplog, wal-to-bucket-router, psync-protocol, pes-gateway, pes-server-binary, entity-sync-ts-sdk. **Wave 5 `v4-pem-sync-transport` done** (the `prometheusSyncTransport`). **Open proposals (NOT implemented):**
- `v4-dart-sdk` (Wave 6) — `prometheus_entity_sync` **pure-Dart** package (no FFI): `drift` (SQLite) + `web_socket_channel`; `SyncClient{connect, subscribeBucket, statusStream, write, disconnect}` + `SyncStatusWidget`.
- `v4-tauri-plugin` (Wave 7) — `tauri-plugin-prometheus-sync`: pglite-oxide embedded via Wasmtime in Rust backend, Rust PSyncV1 client, IPC handlers; **`[patch]` to local pglite-oxide clone with documented `rusqlite-fallback` feature flag**.
- `v4-entity-sync-skill` (Wave 8) — AgentSkills.io skill: references (DSL, TS/Dart API, security model, wire protocol, troubleshooting), recipes (add-entity-type, offline-first, multi-tenant, tauri-setup), validators (sync-rule linter, security checker).

Umbrella success criteria (unchecked): two-browser-tab bidirectional sync with per-user isolation; Flutter offline replay; Tauri pglite-oxide sync; `entity-sync-cli validate-rules`; Docker `/health` <2 s; clippy-clean.

### 1.4 Flutter/Dart/Riverpod presence

- **`packages/entity_graph_flutter/`** (PEM monorepo): Dart mirror of the entity graph. `lib/src/graph.dart` (`EntityGraph` singleton: `_entities`/`_patches`/`_lists`, `EntitySyncMetadata` with `SyncOrigin {server, client, optimistic}`, immutable `copyWith`, `Stream<GraphChange>` + per-entity/list streams), `providers.dart` (`entityGraphProvider`, `EntityListNotifier`/`EntityNotifier` extending `AutoDisposeAsyncNotifier`; widgets never write the graph), `transport.dart` (`EntityTransport<T>` + `EntityTransportRegistry` — same contract as TS), `sdl.dart` (parses `entity-graph-sdl` JSON into validated `EntityGraphIR`), `errors.dart` (`TerminalError`/`TransientError`). Tests for all five modules.
  - **pubspec reality check:** description says "Riverpod 3 AsyncNotifier providers", but deps pin `flutter_riverpod: ^2.6.1`, `riverpod_annotation: ^2.3.5`, `freezed_annotation: ^2.4.4`; SDK `>=3.3.0 <4.0.0`, Flutter `>=3.22.0`. Not published to pub.dev (path dep).
  - **No sync transport, no offline queue, no PSyncV1 client, no drift/SQLite code.** It's an in-memory graph + transport interface only.
- **PES repo:** zero Dart files. The Dart SDK is the `v4-dart-sdk` proposal only.
- Search for `dart|flutter|riverpod` across PES hits only the README. In PEM, hits are the `entity_graph_flutter` package, roadmap/research docs, and skill docs.

### 1.5 AI-harness skills shipped

`prometheus-entity-skills/` — AgentSkills.io-spec bundle (tiered progressive disclosure; `_shared/references/library-exports.json` as API ground truth; Claude Code plugin marketplace layout with `.claude-plugin/plugin.json` per plugin):
- Plugins: `entity-graph-setup` (init/detect/migrate), `entity-graph-crud` (page/form/table/relations), `entity-graph-graphql` (setup/hooks/subscription), `entity-graph-realtime` (setup/channel/local-first), `entity-graph-prisma` (setup/generator/api/migrate), `entity-graph-optimize` (audits/GC), `entity-realtime-surreal-live`.
- Each plugin: `SKILL.md` + nested `skills/*/SKILL.md` + `agents/`, `hooks/`, `prompts/`, `AGENTS.md`/`CLAUDE.md`.
- The planned `v4-entity-sync-skill` (for PES) is not yet written.
- Separately: `entity-graph-mcp` (Rust MCP server) and `entity-graph-a2a` give machine access to the graph; `createGraphTool`/`createSchemaGraphTool`/`exportGraphSnapshot(WithSchemas)` in core give AI interop without a bundled runtime.

### 1.6 External verification (accessed 2026-07-18)

- **pglite-oxide is now on crates.io** — `github.com/f0rr0/pglite-oxide` (badges: crates.io, docs.rs, MSRV 1.92). docs.rs page (2026-05-03 snapshot): "Embedded Postgres for Rust tests and local apps", packaged runtime **PostgreSQL 17.5**, API = `Pglite::open(path)` / `Pglite::temporary()` (direct) and `PgliteServer::temporary_tcp()` / `builder().path(...).start()` (SQLx/`tokio-postgres` URL), bundled `pg_dump`, extensions incl. `pgvector`/`pg_trgm`, **dedicated Tauri doc section**, near-native perf (25k 1-tx inserts: 149 ms vs 132 ms native; beats vanilla PGlite). License MIT+Apache-2.0+PostgreSQL. **This supersedes PEM's internal research (2026-07-13) which says "not published to crates.io yet — git dependency" and shows a `PGliteInstance::create_in_memory()` API that no longer matches.** Sources: https://docs.rs/pglite-oxide , https://github.com/f0rr0/pglite-oxide .
- **Loro 1.0 GA** — announced Feb 2026 per community spec citing `loro = "1.0"`; official blog "Loro 1.0" (stable data format; Rust, JS via WASM, Swift; MIT; Fugue text CRDT, movable tree/list, LWW map, shallow snapshots). Benchmarks (crdt-benchmarks B4, 260K edits): Loro fastest (290 ms apply; 68 kB encoded; 15 MB memory). `loro-crdt` npm published 2026-06-21. **PEM roadmap's "Loro … not production-ready" is outdated.** Sources: https://loro.dev/blog/v1.0 , https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026 .
- **ElectricSQL: still read-path only** — official writes guide: "Electric does read-path sync … does not do write-path sync"; patterns = online writes, optimistic state, shared persistent optimistic state, through-the-database (change-log table + `NOTIFY`). `@electric-sql/pglite-sync` remains **alpha**: "We don't yet support local writes being synced out". PGlite `0.4.4` (2026-04-09, Apache-2.0, ~3.7 MB gz). Sources: https://electric.ax/docs/sync/guides/writes , https://pglite.dev/docs/sync , https://npmx.dev/package/@electric-sql/pglite/v/0.4.4 .
- **PowerSync licensing** — server-side service + CLI under **FSL-1.1-ALv2** (Competing Use restriction: no commercial product/service that substitutes or offers substantially similar functionality; converts to Apache-2.0 two years after each release); client SDKs (incl. Dart `powersync.dart`, Rust `powersync-native`) Apache-2.0/MIT. Validates PES's reason to exist as an MIT alternative. Sources: https://powersync.com/legal/fsl , https://powersync.com/open-source , https://powersync.com/blog/powersync-supports-fair-source .
- **CVE-2026-40906** (Electric `ORDER BY` SQLi, patched in Electric 1.6.2, 2026-03-15) — per PEM's internal research doc; treated as a design lesson (PES uses parameterized queries + identifier allowlists throughout).

---

## 2. How It Works

### 2.1 PEM entity/state model and Zustand integration

Three layers, one direction: **Components → Hooks → Stores → APIs/Realtime**; data flows *up* into the graph, UI reads *down*.

- **Layer 1 (graph, vanilla Zustand):** `entities[type][id]` (canonical, server-shaped), `patches[type][id]` (session-only UI overlays, shallow-merged at read: `read = {...entity, ...patch}`, never sent to server), `lists[queryKey]` (ordered `ids[]` + pagination/flags — **never row payloads**), `syncMetadata` (`$synced`/`$origin`/`$updatedAt`). Writes only via `upsertEntity` (partial merge), `replaceEntity` (post-confirm full replace), `removeEntity`, `patchEntity`.
- **Engine:** process-global in-flight `dedupe`, subscriber ref-counting via `Symbol` tokens, stale-while-revalidate (default 30 s), focus/reconnect invalidation, optional GC of unsubscribed stale entities.
- **Layer 2 (hooks/transports):** `useEntity`, `useEntityList`, `useEntityView` (local/hybrid/remote completeness), CRUD (`useEntityCRUD` with React-state edit buffer isolation + `applyOptimistic`), GraphQL hooks, `registerEntityTransport(type, transport)` registry — the seam every backend plugs into. `FilterSpec`/`SortSpec` AST compiles to REST params, GraphQL variables, SQL clauses, Prisma where/orderBy, or local JS predicates.
- **Realtime:** adapters (WebSocket/Supabase/Convex/GQL-subscriptions/Electric/Flint/Surreal) emit a shared change shape; `RealtimeManager` coalesces per 16 ms frame; delete wins.
- **Non-hook runtime:** `queryOnce`/`selectGraph`, `createGraphTransaction`/`createGraphAction` (optimistic + rollback), `createGraphEffect` (enter/update/exit), `exportGraphSnapshot`, schema-driven entities (`registerEntityJsonSchema`, `registerEntityFromSql` — JSON Schema straight from `CREATE TABLE`), `startLocalFirstGraph`.

### 2.2 PGlite usage patterns in browsers (as encoded by PEM + its research doc)

- **As sync target:** Electric `syncShapeToTable` into PGlite; PEM's Electric adapters map shape changes into the graph; `createTenantScopedElectricAdapter` enforces a `tenantColumn` so shape predicates can't widen past RLS.
- **As graph snapshot store:** `createPGlitePersistenceAdapter` keeps `_graph_snapshot` beside synced data ("one storage surface to back up, clear, and reason about").
- **As query surface:** `usePGliteQuery` (react) runs SQL against PGlite in sync with the graph; PGlite `live` extension provides reactive queries.
- **As PES delta target:** `entity-sync-pglite`'s `applyOps` applies `BucketOp`s transactionally (idempotent upsert/delete; CRDT bytes stored opaquely).
- **Operational constraints (research doc):** OPFS AHP preferred (10–50× IdbFs) but **Safari blocked** (252-handle WebKit bug) → detect + fall back to `IdbFs`; SharedWorker hosts single instance for multi-tab (OPFS exclusive lock); ~3.5 MB gz bundle; 3–5× slower than SQLite WASM; cold start 200–800 ms; iOS Safari has no SharedWorker/background sync; additive-only migrations + `_migrations` table + reset-and-resync flow; pgvector enables offline semantic search.

### 2.3 PES sync engine design

**Topology:** `Postgres WAL → frf-postgres-cdc → InProcessBroker (entity/changes) → WalToBucketRouter → per-bucket BucketOpLog (redb via frf-store-redb) → pes-gateway → PSyncV1 (WebSocket + MessagePack) → clients`.

**Protocol (PSyncV1):** client `Subscribe{buckets, token, resume_lsn?, protocol_version}` → per bucket `SnapshotBegin → SnapshotBatch*{rows as JSON} → SnapshotComplete{checksum}` → live `Delta{ops, lsn}` (client `Ack{lsn}`; resume from last acked LSN on reconnect) → periodic `Checkpoint{bucket_checksums}` + `Keepalive{server_time_ms}`. Version mismatch → error 4000.

**Sync rules (security boundary):** TOML `[buckets.x]` with `parameters`, `parameter_queries` (parameterized SQL, `$1` = JWT `sub` only), `data` queries referencing `{bucket_parameters.X}`; template substitution renders validated values (`^[a-zA-Z0-9_-]{1,128}$`) as single-quoted literals; 4 validation rules reject bad DSL at load. `BucketAssigner` resolves + caches assignments (TTL + sweeper) and finds buckets affected by a WAL row.

**Write path & conflict handling:**
- Client `Write{entity_type, entity_id, op}` → gateway authorizes **twice**: (1) entity_type ∈ some authorized bucket's `data_queries` keys (server-controlled set from `sync-rules.toml`); (2) row-level ownership via `SELECT 1 FROM (<resolved data_query>) WHERE id = $1`. Then `apply_write`: `Upsert` → `UPDATE {type} SET payload = $1 WHERE id::text = $2`; `Delete` → DELETE; `CrdtPatch` → read `crdt_state`, **merge server-side via `frf_crdt::apply_delta` (Loro)**, write back. The change re-enters via WAL and is broadcast to all subscribers (including the writer) as ordinary `Delta`s.
- **No create semantics:** inserting a brand-new id fails the ownership check (fail-closed, deliberate); new entities must be created through the ordinary application API first. This is a documented protocol limitation.
- **Conflict model:** for `Upsert`/`Delete`, **last-write-wins at Postgres** (WAL order is the total order; payload is whole-row JSON). For `CrdtPatch`, true CRDT merge (Loro) — commutative, so concurrent patches converge. Checksums + LSN-gap detection catch stream corruption (`SyncError::LsnGap`, `ChecksumMismatch`).
- **Server-side delta delivery is polling:** gateway polls each bucket's oplog every 50 ms (`drain_since` from last delivered+1 — an off-by-one redelivery bug was found live and fixed). No broadcast channel in pes-oplog yet ("out of scope" note in `connection.rs`).

**Backend expectations:** Postgres with logical replication (slot `pes_server_slot`, publication `pes_pub`), tables keyed by `id` with `payload` JSONB (+ optional `crdt_state` BYTEA) envelope, JWT issuer config (`JwtValidationConfig`), `config.toml` + `sync-rules.toml`, Docker image with health/metrics ports.

### 2.4 PEM ↔ PES integration (the working bridge)

`prometheusSyncTransport({serverUrl, bucket, getToken, table, primaryKey, entityType, db})` (in `entity-sync-pglite`) is registered per entity type via PEM's `registerEntityTransport`. It reconciles PEM's pull-based `list()/get()/subscribe()` contract with PES's push stream: all deltas are applied to PGlite (`applyOps`), reads run SQL against that local PGlite (`authoritative: true`, never stale), `subscribe()` re-reads applied rows and emits `ChangeEvent`s into PEM's realtime pipeline (16 ms coalescing → graph → all views). `write()` maps PEM mutations to `SyncClient.write`. The Vite example wires this for a `Task` entity (`examples/vite-app/src/lib/entity-sync-transport.ts`).

### 2.5 Tauri / pglite-oxide support status

- **PEM side:** `entity-graph-tauri` plugin is real but persists graph snapshots via **SQLite** (`@tauri-apps/plugin-sql` + `createTauriSqlPersistenceAdapter`). It mirrors the *in-memory graph* over IPC; it is not a database sync layer.
- **PES side:** `entity-sync-tauri` = `export {};`. The actual design lives only in the `v4-tauri-plugin` proposal (pglite-oxide in Rust backend + Rust PSyncV1 client + IPC; rusqlite fallback).
- **pglite-oxide itself** is now viable off-the-shelf (crates.io, PG 17.5, `Pglite`/`PgliteServer`, Tauri docs) — the owner's internal doc is stale on this point.

### 2.6 Skills for AI harnesses

See §1.5. Net: a 7-plugin AgentSkills.io suite for PEM (React-focused), MCP server (Rust) + A2A server (TS) exposing the graph to agents, `createGraphTool` helpers, and a *planned* (not yet written) PES skill covering DSL/SDK/security/troubleshooting.

---

## 3. Implications for the Master Goal

1. **The cross-platform entity contract already exists and is implemented twice (TS + Dart).** `EntityTransport<T>` + the SDL IR (`entity-graph-sdl` → same IR consumed by Rust CLI, TS generators, Dart parser) is exactly the seam a unified web/Tauri/Flutter local-first story needs. The architecture spec should canonize SDL as the single schema source for entities, settings schemas, and codegen across `gen_ui_core`, Tauri, and Flutter.
2. **PES is the credible MIT PowerSync-alternative and is already FRF-native.** It reuses `frf-postgres-cdc`, `frf-crdt`, `frf-store-redb`, `frf-ports`, `frf-domain`. For the master architecture, `pes-server` should be positioned as an FRF edge module (or flint-forge extension) rather than an independent gateway — one WAL CDC pipeline, one CRDT implementation (Loro via `frf-crdt`), one ops backbone. Note there are *two* PEM↔FRF integration points today (the PEM `flint.ts` watchEntities facade vs PES's server-side reuse); the spec must pick one canonical path (recommendation: PES buckets for data sync; keep `flint.ts` for lightweight entity events, or deprecate it).
3. **CRDT story is coherent end-to-end and should be Loro-first.** `Op::CrdtPatch` is server-merged with Loro (`frf_crdt::apply_delta`); PEM's `entity-graph-sync` ships Loro + Yjs providers for peer sync (Yjs WebRTC covers browser P2P). Loro 1.0's stable format (Feb 2026) removes the roadmap's production-readiness concern and gives one CRDT across Rust server, WASM web, and Swift/Rust native. WebRTC data-channel sync exists today only at the Yjs provider level — PSyncV1 has no WebRTC transport (and no lora-rs anywhere); that's greenfield for the spec.
4. **Tauri leg is de-risked externally but unimplemented internally.** pglite-oxide on crates.io (PG 17.5, Tauri docs, near-native perf) means the `v4-tauri-plugin` design can drop the rusqlite fallback anxiety. But today the only Tauri artifacts are PEM's SQLite-snapshot plugin and PES's empty stub — the actual pglite-oxide sync plugin is a full work item.
5. **Flutter leg has a state-management mirror but no sync.** `entity_graph_flutter` proves the Riverpod pattern (graph + AsyncNotifier + transport registry + SDL). The missing piece is the PSyncV1 Dart client — and here the master's TJ-ARCH-MOB-001 invariant ("all networking/LLM/persistence in the shared Rust crate `gen_ui_core`; never re-implement in Dart") collides with the `v4-dart-sdk` proposal's **pure-Dart** (web_socket_channel + drift) design. Decision point for the spec: either (a) complete `pes-sdk-rust` and expose it to Flutter via `flutter_rust_bridge` (invariant-compliant, one protocol implementation), or (b) accept a thin, generated Dart protocol client as a sanctioned exception. Option (a) also covers the Tauri plugin's Rust client — one `pes-sdk-rust` serves both.
6. **Offline writes are the weakest link.** SyncClient drops writes while disconnected (by design, "no silent data loss"); PEM's `startLocalFirstGraph` has a separate retry/poison-pill action replay that is *not* wired to the PES transport; and PSyncV1 can't create rows (fail-closed ownership). A real local-first story needs a client-side persistent op queue (drift/PGlite `_operation_queue` pattern from the research doc) with create semantics added to the protocol (ownership-establishing insert), plus reconciliation between PEM's replay and PES's write path.
7. **Envelope vs schema fidelity needs an explicit decision.** PES upserts whole-row JSON into `(id, payload)` envelopes (both server `apply_write` and client `applyOps`), while PGlite/Electric patterns sync real columnar tables. The master spec should decide: envelope-everywhere (simple, schemaless, loses SQL ergonomics/pgvector indexing) vs columnar sync with per-table schemas (PowerSync-style; requires `sync-rules.toml` to declare column mappings). The SDL + `registerEntityFromSql` machinery already in PEM is the natural vehicle for columnar typing.
8. **AI-native surface is unusually complete** (MCP server, A2A server, `createGraphTool`, schema-driven fields, A2UI components, 7 skill plugins) and aligns with the master's agent-cooperation goal: client-side and cloud agents can share one entity graph as their common memory/tool substrate. The settings-schema sync requirement maps onto `registerEntityJsonSchema` + buckets.
9. **Security model is a strong foundation.** Bucket DSL (parameterized-only), template allowlist, double write authorization, fail-closed creates, client-facing error redaction, tenant-scoped Electric adapter — consistent with the master goal's multi-tenant JWT story (Supabase/Kratos per TJ-ARCH-MOB-001 auth references). The research doc's dual-JWT (auth token + shape token) pattern is the recommended deployment shape.

---

## 4. Gaps / Risks

**Implementation gaps (verified in-repo):**
1. `pes-sdk-rust` is a 1-line stub; `entity-sync-tauri` is `export {}`; no Dart code in PES. Waves 6–8 (Dart SDK, Tauri plugin, sync skill) are proposals only. The PES README overstates reality (advertises Dart/Rust/Tauri SDKs).
2. No offline write queue anywhere in the sync path; writes while disconnected are dropped (SyncClient.send throws). PEM's `replayActionWithRetry` queue is not integrated with `prometheusSyncTransport`.
3. PSyncV1 lacks create/insert semantics (fail-closed by design) — protocol change required for true local-first entity creation.
4. `entity_graph_flutter`: no sync transport, no persistence, no offline queue; "Riverpod 3" claim vs `flutter_riverpod ^2.6.1` pin; unpublished.
5. PEM `entity-graph-tauri` persists snapshots to SQLite, not pglite-oxide; no Rust-side entity graph — the Rust plugin mirrors the TS graph, so the desktop "durable copy in Rust backend" pattern from the research doc (§6.3) is unrealized.
6. Gateway delta delivery polls oplogs every 50 ms (no push/broadcast); fine at small scale, a latency/efficiency ceiling for the realtime fabric ambition. pes-oplog lacks a subscribe API (noted as deferred).
7. Client-side `CrdtPatch` ops are stored as opaque bytes (`applyOps` doesn't merge; no CRDT runtime in `entity-sync-pglite`) — browser CRDT merging currently requires the separate `entity-graph-sync` Loro provider, i.e., two parallel CRDT paths.
8. Everything is pre-release: PEM `3.0.0-alpha.0` (no npm publish evidence in repo), PES `0.1.0`, nothing on pub.dev/crates.io from these repos. `STRATEGIC-ROADMAP.md` is future-dated 2026-07-21 and self-labeled draft; `docs/evolution/COMPARATIVE-REIVEW-06222026.md` filename misspelled.

**Design tensions / risks for the master goal:**
9. **Invariant collision:** pure-Dart PSyncV1 SDK (v4 proposal) vs TJ-ARCH-MOB-001's "all networking in Rust `gen_ui_core`" rule. Must be resolved explicitly (recommend completing `pes-sdk-rust` + flutter_rust_bridge).
10. **Two sync control planes:** Electric-style shapes (PEM adapters) vs PES buckets vs PEM `entity-graph-sync` Yjs/Loro peer providers vs PEM `flint.ts` events. Without an architectural decision record, apps will accrete conflicting sync paths.
11. **Stale internal research:** pglite-oxide "not on crates.io / `PGliteInstance` API" (doc dated 2026-07-13) is superseded — crates.io release with `Pglite`/`PgliteServer` API and Tauri section; Loro "not production-ready" superseded by Loro 1.0 stable format. The spec should re-baseline these.
12. **Platform constraints (from PEM's own research):** Safari OPFS 252-handle bug forces IdbFs fallback (slow); iOS Safari lacks SharedWorker/background sync; PGlite cold start 200–800 ms; 3–5× slower than SQLite WASM; single-connection WASM; LobeChat's PGlite removal is the cautionary tale when offline isn't required. Electric remains read-path-only with alpha pglite-sync — do not design the write path around Electric.
13. **Schema divergence management is documented but not tooled:** additive-only migrations, `_sync_schema_versions`, local-only columns, and reset-and-resync are patterns in the research doc; no automated migration runner ships in either repo.
14. **Envelope vs columnar** (see §3.7): current `(id, payload)` envelope blocks pgvector indexes, per-column SQL, and `registerEntityFromSql` fidelity for synced tables.
15. **JWT/refresh:** client JWT refresh is proactive timer-based; token travels inside every `Subscribe` frame; gateway `auth.rs` is custom JWT validation — needs alignment with the master's Kratos/Supabase auth references (JWKS rotation, tenant claims) before production.

---

## 5. Source Index

**Repos (local, read 2026-07-18):**
- PEM: `README.md`, `ARCHITECTURE.md`, `STRATEGIC-ROADMAP.md`, `comparative-review.md`, `docs/pglite-local-first-architecture-research.md`, `docs/evolution/*`, `packages/*/{package.json,README.md,pubspec.yaml,Cargo.toml}`, `packages/entity-graph-core/src/{graph,engine,local-first-runtime}.ts`, `packages/entity-graph-core/src/adapters/{flint,pglite-persistence,tauri-sql-persistence,electricsql-tenant}.ts`, `packages/entity-graph-sync/{README.md,src/*}`, `packages/entity-graph-tauri/{README.md,rust-plugin/*}`, `packages/entity_graph_flutter/{README.md,pubspec.yaml,lib/src/*}`, `prometheus-entity-skills/{SKILL.md,SKILLS.md}`, `openspec/changes/{2026-07-13-v4-prometheus-entity-sync,v4-dart-sdk,v4-tauri-plugin,v4-pem-sync-transport,v4-entity-sync-skill}/proposal.md`, `openspec/changes/archive/`, `.kbd-orchestrator/phases/phase-v4-prometheus-entity-sync/*`, `examples/vite-app/src/lib/entity-sync-transport.ts`.
- PES: `README.md`, `Cargo.toml`, `crates/pes-core/src/types.rs`, `crates/pes-protocol/src/messages.rs`, `crates/pes-gateway/src/connection.rs`, `crates/pes-server/src/main.rs`, `crates/pes-rules/src/*` (API surface), `crates/pes-sdk-rust/src/lib.rs`, `packages/entity-sync-core/src/client.ts`, `packages/entity-sync-pglite/src/{apply,pem-transport,extension,index}.ts`, `packages/entity-sync-tauri/src/index.ts`, `docs/sync-rules-reference.md`, `examples/docker-compose/*`.

**Web (accessed 2026-07-18):**
- pglite-oxide: https://docs.rs/pglite-oxide (2026-05-03 snapshot); https://github.com/f0rr0/pglite-oxide (2025-09-27+)
- Loro 1.0: https://loro.dev/blog/v1.0 ; https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026 (2026-04-12); https://npmx.dev/package/loro-crdt (2026-06-21)
- Electric write model: https://electric.ax/docs/sync/guides/writes ; https://pglite.dev/docs/sync ; https://npmx.dev/package/@electric-sql/pglite/v/0.4.4 (2026-04-09)
- PowerSync FSL: https://powersync.com/legal/fsl ; https://powersync.com/open-source ; https://powersync.com/blog/powersync-supports-fair-source (2024-08-06); SPDX FSL-1.1-ALv2: https://github.com/spdx/license-list-XML/issues/2459
- Landscape context: https://byteiota.com/local-first-software-why-crdts-are-gaining-ground/ (2026-04-08); https://zairalabs.ai/guide/compare/electricsql-cloud-vs-powersync-cloud/ (verified 2026-06-10)
