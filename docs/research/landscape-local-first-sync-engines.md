# Landscape: Local-First Sync Engines (2025–2026)

- **Slug:** `landscape-local-first-sync-engines`
- **Researcher:** KNOWME_RESEARCHER (deep-research swarm)
- **Date:** 2026-07-18 (all "accessed" dates are 2026-07-18 unless noted)
- **Scope:** Web survey of the 2025–2026 local-first / sync-engine landscape, analyzed through the lens of the KnowMe Builder master goal: **PGlite (web) + pglite-oxide (Tauri) + Flutter mobile (SQLite) syncing through a Rust realtime fabric (flint-realtime-fabric) to central Postgres (flint-forge)**, with CRDT sync over WebRTC, WASM components, and decentralized packaging.
- **Method:** vendor docs/blogs, GitHub API (license/stars/`pushed_at`), crates.io metadata, independent 2025–2026 reviews. Unverifiable claims are explicitly flagged.

---

## 1. Executive summary

The local-first sync space has **consolidated around five architectural archetypes** in 2025–2026:

1. **Postgres read-path sync** (Electric): logical replication → HTTP "shape" streams → client stores. Read-path only; writes via your own API.
2. **Bidirectional central-authority sync with upload queues** (PowerSync): logical replication → bucket storage → WebSocket streams; offline writes queue client-side and upload through your backend.
3. **Query-driven sync with a server-side replica** (Zero/Rocicorp): `zero-cache` holds a SQLite replica of Postgres; clients sync exactly the rows their ZQL queries touch. Explicitly **not** local-first (no offline writes, TS-only).
4. **Event-sourced local DBs** (LiveStore): git-style event log materialized into reactive SQLite; pluggable sync backends (Electric, S2, Cloudflare).
5. **CRDT-native systems** (Automerge, Yjs/Yrs, Loro, Jazz, Evolu, Ditto, cr-sqlite, DXOS, Triplit, TinyBase mergeable stores): multi-writer merge semantics; server optional.

**Three developments matter most for the master goal:**

- **The embedded-Postgres replica story is now real on both web and Tauri.** PGlite (Apache-2.0, 15.6k★) is Electric's ~3 MB WASM Postgres 15/17 for browser/Node/Bun/Deno with a shape-sync extension (`@electric-sql/pglite-sync`), and **`pglite-oxide` (crates.io v0.5.1, 2026-06-04)** embeds the same PGlite WASI runtime (PostgreSQL 17.5) in Rust via Wasmtime 44 — with an explicit **Tauri usage guide**. Web and desktop can run the *same* database engine.
- **Logical-replication-based sync now has a first-class Rust implementation to crib from:** `supabase/etl` (Apache-2.0, launched as Supabase Pipelines 2025-12-02) is a Rust CDC framework on Postgres logical replication (pgoutput decoding, slot management, backfills). This is the strongest reference for building the replication consumer **inside flint-realtime-fabric** rather than operating an external Elixir/Kotlin service.
- **Flutter remains the underserved surface.** Only PowerSync (Flutter SDK is first-class), Supabase, and Ditto ship production Flutter sync clients. Electric's community Dart client is deprecated; Zero/LiveStore/Jazz/Triplit/Evolu/Instant have no official Flutter support. A drift-based client against a Rust fabric's sync protocol is a *build* decision, not a *buy* decision.

**License watch-list:** Triplit is **AGPL-3.0** (and acqui-hired by Supabase Aug 2025, community-maintained); PowerSync Service and DXOS are **FSL-1.1** (convert to Apache-2.0 after 2 years); Ditto is proprietary; cr-sqlite is effectively **dormant** (last push 2024-10-25); Electric, PGlite, Zero (rocicorp/mono), LiveStore, InstantDB, Supabase Realtime/ETL, RxDB are Apache-2.0; Automerge, Yjs, Yrs, Loro, Evolu, TinyBase, WatermelonDB, Jazz are MIT.

---

## 2. The five archetypes — master comparison

| Engine | Data model | Sync protocol | Consistency model | Partial replication | Web | Tauri/desktop | Flutter | License | Status (mid-2026) |
|---|---|---|---|---|---|---|---|---|---|
| **Electric + PGlite** | Postgres rows → any client store (incl. PGlite wasm) | HTTP Shape API (`GET /v1/shape`), offsets, long-poll/SSE-ish live mode; CDN-cacheable | Central authority (Postgres); read-path | **Shapes** (table + where + columns) | ✅ 1st-class | via pglite / pglite-oxide | ⚠️ community client deprecated | Apache-2.0 | 1.0 GA 2025-03-17; very active; "agent platform" pivot |
| **PowerSync** | Postgres (+Mongo/MySQL/SQL Server) → SQLite | Buckets over WS/RSocket/HTTP; checkpoints; upload queue | Central authority w/ offline write queue | **Sync Rules → buckets**; Sync Streams; priorities | ✅ (wa-sqlite/OPFS) | via web/Capacitor/Kotlin JVM | ✅ **1st-class** | Service **FSL-1.1-ALv2** | v1.23.2 (2026-07-02); SOC2+HIPAA Jan 2026 |
| **Zero (Rocicorp)** | Postgres → SQLite replica (zero-cache) → client cache | WS, custom protocol; ZQL streaming queries | Server-authoritative; optimistic cache | **Synced queries** + permissions | ✅ 1st-class | ❌ TS-only | ⚠️ `zero-react-native` pkg exists | Apache-2.0 (rocicorp/mono) | Active; docs: not local-first, no offline writes, <~100 GB |
| **Replicache** | KV store + mutations | Pull/push endpoints you implement | Server-authoritative | per-client views | ✅ | ❌ | ❌ | Apache-2.0 (in mono); old repo archived | **Maintenance mode**, superseded by Zero |
| **LiveStore** | Event log → materialized SQLite | Provider-specific (Electric, S2, CF Durable Objects) | Event-sourced; server as log | by event streams | ✅ 1st-class | ❌ | ❌ (Expo/RN experimental) | Apache-2.0 | Beta (≈2025-06); active |
| **Jazz** | CoValues (CoMap/CoList/CoStream/…) | Jazz sync server / Jazz Cloud mesh | CRDT-ish CoValues; groups/permissions | partial sync of tables/streams/files | ✅ | via Node | RN (not Flutter) | MIT | Active; Jazz Cloud commercial |
| **Triplit** | Triple store (client+server) | WS; HLC timestamped changes | CRDT LWW (HLC) | query-based subscriptions | ✅ | via Node | ❌ | **AGPL-3.0** | Acqui-hired by Supabase 2025-08; community-maintained |
| **Evolu** | SQLite (+ typed schema) | Evolu Relay (self-hostable/cloud); E2E encrypted | CRDT LWW per field; owner-sharded | per-owner shards | ✅ | Electron ✅ | RN (not Flutter) | MIT | Active; small team |
| **InstantDB** | Triples in one multi-tenant Postgres | WS; Clojure sync server; WAL→"topics" invalidator | Server-authoritative w/ optimistic client cache | query topics (Figma LiveGraph-style) | ✅ | ❌ | ⚠️ community pkgs only | Apache-2.0 | **1.0 launched 2026-04-09**; 10.4k★ |
| **DXOS** | ECHO object DB + HALO identity | MESH P2P (WebRTC swarms) + sync services | CRDT | per-space | ✅ | ❌ | ❌ | **FSL-1.1-Apache-2.0** | Active; low adoption (~510★) |
| **Ditto** | CRDT document store (DQL) | P2P mesh (BLE/LAN/WiFi) + Big Peer WS | CRDT multi-writer | subscriptions (DQL) | ✅ | ✅ | ✅ (`ditto_flutter`) | Proprietary | Commercial; enterprise edge focus |
| **cr-sqlite (vlcn)** | SQLite tables w/ CRR extension | bring-your-own transport | CRDT (LWW/counters per column) | row-level via queries | wasm ✅ | possible | ⚠️ none official | MIT | **Dormant** (last push 2024-10-25) |
| **RxDB** | JSON docs over pluggable storage | CouchDB/GraphQL/REST/WS/NATS replication plugins | Server + client conflict handlers | per-query replication | ✅ | Electron | RN only | Apache-2.0 (+paid premium) | Very active (23k★) |
| **TinyBase** | In-memory tabular KV store | Synchronizers (WS/BroadcastChannel/custom); MergeableStore HLC | CRDT merge (mergeable stores) | whole store (small data) | ✅ | possible | ❌ | MIT | Active; v9.2 (agent-friendly docs) |
| **WatermelonDB** | SQLite ORM (React/RN) | Two-phase `pullChanges`/`pushChanges` you implement | LWW by convention | sync query scopes | ⚠️ | ❌ | RN only (no Flutter) | MIT | Slow maintenance (last push 2025-08-11) |
| **Automerge** | JSON-ish CRDT docs | Efficient sync protocol; Repo network adapters (WS/BroadcastChannel/WebRTC-community) | **True CRDT** (multi-writer) | per-document sharePolicy | ✅ wasm | C FFI / Rust native | via Rust FFI (unofficial) | MIT | 3.0 (2025-05): 10× memory cut; Repo 2.0; active |
| **Yjs / Yrs** | Shared types (Text/Array/Map/XML) | y-protocols; y-websocket, **y-webrtc**, y-indexeddb; awareness | **True CRDT** (YATA) | per-doc rooms | ✅ | **Yrs (Rust)** native | via Yrs FFI (unofficial) | MIT / MIT | Very active; yrs 0.27.3 (2026-07-13) |
| **Loro** | JSON + rich-text CRDT (Eg-walker/Fugue) | op-based sync; shallow snapshots | **True CRDT**; movable list/tree | per-doc; shallow history | ✅ wasm | **Rust native**; Swift | via Rust FFI (unofficial) | MIT | **1.0 released 2026-06-15** |
| **Supabase Realtime** | Postgres changes as JSON events | Phoenix Channels WS; logical replication; RLS-aware authz | Central authority; **no client persistence** | filters on tables/events | ✅ | ✅ | ✅ (`supabase_flutter`) | Apache-2.0 | GA 2025; Broadcast-from-DB (2025-04); Replay (2025-12) |
| **TanStack DB** | Typed collections w/ live queries (d2ts) | delegates to backends (Electric, PowerSync, query, custom) | depends on backend; optimistic txns | per-collection queries | ✅ | ❌ | ❌ | MIT | New 2025-07; 3.8k★; de-facto client layer for Electric |

---

## 3. Deep dives — what exists and how it works

### 3.1 Electric (ElectricSQL) + PGlite — Postgres read-path sync

**What exists.** Electric is an Elixir service that sits in front of Postgres (`wal_level = logical`) and exposes a **read-path sync API over plain HTTP**: `GET /v1/shape?table=foo&offset=-1`, with `where` filters and column selection. **Shapes** are the partial-replication primitive. Responses are offset-stamped and CDN-cacheable; Electric advertises 1M+ concurrent readers with ~99% CDN cache hit rate and flat DB load. **1.0 GA 2025-03-17** with stable APIs, Antithesis-tested correctness, and production users (Trigger.dev, Otto). Managed **Electric Cloud** exists. In 2026 the company repositioned as *"the agent platform built on sync"* (electric.ax, accessed 2026-06-26): Electric Sync + **Electric Streams** (durable, addressable streams) + Electric Agents — relevant context: classic "local-first writes" are still not the focus.

**How it works (and the write-path caveat).** Electric is explicitly **read-path only**. Writes go client → your API → Postgres → Electric streams the change back out. AuthN/Z is a documented **proxy pattern**: a proxy validates JWTs and *rewrites* shape requests (adding `where` clauses), optionally plus `ELECTRIC_SECRET` between proxy and Electric. Clients: `@electric-sql/client`, `@electric-sql/react` (`useShape`), `phoenix_sync` (Phoenix.Sync), plus **TanStack DB** co-development (Electric collection + `awaitTxId` for write confirmation). A respected independent review (johnny.sh, 2026-03-09) criticized the long-poll push mechanism as "slow and brittle" and the DIY write path as the main DX gap — a signal the master's fabric should use **WebSocket streaming + a structured write path** instead.

**PGlite.** Real Postgres (single-user mode, no Linux VM) compiled to WASM, <3 MB gzipped, for browser (IndexedDB persistence), Node/Bun/Deno (fs). Extensions incl. **pgvector**, PostGIS. Live queries (`@electric-sql/pglite/live`, `pglite-react`), multi-tab worker. **`@electric-sql/pglite-sync`** provides `pg.electric.syncShapeToTable({ shape, table, primaryKey })` — a persistent shape subscription materialized into a local PGlite table (marked experimental→beta). Hard constraint: **single user/single connection** per PGlite instance.

**Key links:** [electric repo](https://github.com/electric-sql/electric) (Apache-2.0, 10.3k★, pushed 2026-07-17) · [Electric 1.0 released](https://electric.ax/blog/2025/03/17/electricsql-1.0-released) (2025-03-17) · [electric.ax](https://electric.ax/) (agent-platform positioning, 2026-06-26) · [PGlite product page](https://electric.ax/sync/pglite) ("PGlite beta") · [pglite.dev/docs/about](https://pglite.dev/docs/about) · [pglite repo](https://github.com/electric-sql/pglite) (15.6k★, pushed 2026-07-15) · [Neon + Electric guide](https://neon.com/guides/electric-sql) (proxy/authz architecture) · [Electric + TanStack DB](https://electric.ax/blog/2025/07/29/super-fast-apps-on-sync-with-tanstack-db) (2025-07-29) · [deprecated Dart client](https://pub.dev/documentation/electricsql/latest/).

### 3.2 pglite-oxide — embedded Postgres for Rust/Tauri (directly validates the master's Tauri bet)

**What exists.** `pglite-oxide` ([docs.rs](https://docs.rs/pglite-oxide), [GitHub f0rr0/pglite-oxide](https://github.com/f0rr0/pglite-oxide), created 2025-09-27; crates.io **v0.5.1, updated 2026-06-04**; license badge "MIT AND Apache-2.0 AND PostgreSQL") embeds Electric's PGlite **WASI PostgreSQL 17.5** runtime in Rust via **Wasmtime 44**. APIs: `Pglite` (direct embedded), `PgliteServer` (supervised local socket → SQLx/`tokio-postgres` URL; pool=1 because the runtime owns one backend), `Pglite::temporary()` for tests (clones a template cluster). Bundled extensions: `pgvector`, `pg_trgm`, `hstore`, `citext`, `ltree`; bundled WASIX `pg_dump` for logical backups/upgrades. Docs include an explicit **Tauri usage** guide and a Tauri SQLx profiler example. Benchmarks (M1 Pro): ~1.1–1.6× native-Postgres latency on typical CRUD, consistently faster than vanilla PGlite. A second, smaller experiment exists: [kshcherban/pglite-rust-bindings](https://github.com/kshcherban/pglite-rust-bindings) (early draft, `#[tokio::test]`-oriented).

**Implication.** The owner's `docs/pglite-oxide-tauri-hybrid.md` bet is externally validated: a Tauri app can run the *same* Postgres engine as the web client (PGlite) with pgvector parity. Remaining work for the master goal: a sync layer that treats the embedded PGlite/PGlite-wasm as a **replica target** (shape/bucket applier) — this piece does not exist off the shelf for pglite-oxide today.

### 3.3 PowerSync — the most complete central-authority sync (and the Flutter leader)

**What exists.** Kotlin-based sync service (**FSL-1.1-ALv2**, converts to Apache-2.0; Open Edition self-hostable) + client SDKs. Service v1.23.2 (2026-07-02). Source DBs: **Postgres** (logical replication), MongoDB (V1 GA 2025-03-06), MySQL, SQL Server (2025). Bucket storage: MongoDB or **Postgres ≥14** (2025-01). SDKs: **Flutter/Dart (first-class; `powersync`, `powersync_core`, `powersync_sqlcipher` incl. Flutter Web encryption)**, React Native/Expo (incl. OP-SQLite, Expo Go, background tasks), JS/Web (wa-sqlite + OPFS), Kotlin Multiplatform (+JVM desktop target), Swift, Node.js (alpha), .NET (alpha), Capacitor (alpha, 2025-11).

**How it works.** **Sync Rules** (YAML: bucket definitions + parameter queries + data queries) partition the source DB into per-client **buckets**; the service maintains bucket storage with checksums/checkpoints; clients stream deltas (WS/RSocket/HTTP+JSON). Writes: client executes against local SQLite → **upload queue** → `uploadData` callback → your backend API applies to Postgres (idempotency is your job) → changes flow back down. 2025–2026 additions: **Sync Bucket Priorities** (2025-03), sync progress tracking, fine-grained update tracking (previous values/metadata), raw SQLite tables (experimental, replacing JSON views), **Rust-based client core**, sync progress, Postgres bucket storage, `@tanstack/powersync-db-collection` (2025-11), `pg_ivm` guide for JOINs in Sync Rules, **Sync Streams** (next-gen, more expressive rules; IVM-based materialized-view sync still pending for 2026). SOC 2 + HIPAA compliance (Jan 2026). Notably, Cinapse publicly migrated **from CRDTs to PowerSync**, and the owner's ecosystem already assumes Supabase+PowerSync as the strongest offline-first stack.

**Implication.** PowerSync is the only turnkey option covering Flutter+web+RN today, and its bucket/priority/checkpoint design is the best-documented model for partial replication with offline writes. But: service is FSL (not Apache today), written in Kotlin, and duplicates what flint-realtime-fabric should own. **Pattern to reuse, not software to adopt.**

Links: [2025 roadmap update](https://powersync.com/blog/2025-powersync-roadmap-update) (2026-01-05) · [service changelog](https://releases.powersync.com/announcements/powersync-service) (v1.23.2, 2026-07-02) · [Nov 2025 changelog](https://powersync.com/blog/powersync-changelog-november-2025) (2025-12-04) · [QueryPlane architecture review](https://queryplane.com/blog/powersync-offline-first-sync/) (2026-02-07) · [powersync-service LICENSE (FSL-1.1-ALv2)](https://github.com/powersync-ja/powersync-service).

### 3.4 Zero (Rocicorp) — query-driven sync, server replica

**What exists.** Monorepo `rocicorp/mono` (Apache-2.0, 3.3k★, pushed 2026-07-17) containing `zero`, `zero-cache`, `zero-client`, `zero-pg`, `zero-protocol`, `zero-permissions`, `zero-react`, `zero-react-native`, `zero-solid`, `zql`, `zqlite`, `z2s`, `ast-to-zql`, `analyze-query`, and legacy `replicache`. `zero-cache` (TS) maintains a **SQLite replica of Postgres** (logical replication) and incrementally executes **ZQL** — a streaming query language over a shared TS `schema.ts` (tables, relationships incl. many-to-many, **permissions**). Clients cache rows touched by their queries; queries resolve locally first, then authoritatively; mutations are server-authoritative with optimistic rollback. Demo: "Gigabugs", a 1.2M-row issue tracker.

**Hard boundaries (official docs, accessed):** "Zero is **not local-first**. It's a client-server system with an authoritative server"; "**no offline writes**"; "**TypeScript clients only**"; recommended for datasets **< ~100 GB** (the zero-cache SQLite replica is the scaling unit). Their docs generously list alternatives (Automerge, Ditto, Electric, LiveStore, Jazz, PowerSync, Convex). **Replicache** is in maintenance mode inside mono; the standalone repo is archived (Rocicorp's own positioning: use Zero). (One 2026 blog claims "Replicache 14 added native Postgres backend in 2025" — **could not verify**; treat as noise.)

**Implication.** Zero's *synced-queries + server-replica + schema-embedded permissions* model is the most elegant answer to "sync exactly the slice the user wants and may see", but it is TS-only and online-write-only — a **design reference** for the fabric's query layer (and for `zql`-style incremental view maintenance ambitions), not adoptable infra for Flutter/Tauri.

Links: [zero.rocicorp.dev](https://zero.rocicorp.dev/) · [When To Use Zero](https://zero.rocicorp.dev/docs/when-to-use) · [What is Sync?](https://zero.rocicorp.dev/docs/sync) · [marmelab review](https://marmelab.com/blog/2025/02/28/zero-sync-engine.html) (2025-02-28) · [rocicorp/mono](https://github.com/rocicorp/mono).

### 3.5 LiveStore — event-sourced reactive SQLite

**What exists.** `livestorejs/livestore` (Apache-2.0, 3.6k★, pushed 2026-07-17; **beta** since ≈2025-06). By Johannes Schickling (Prisma co-founder). Local event log (git-inspired) materialized into **reactive SQLite** (wa-sqlite, OPFS, or in-memory); schema via materializers; client `sessionId`/`clientId` semantics; devtools. **Sync providers are pluggable**: Electric (`@livestore/sync-electric`, official integration), **S2** (`@livestore/sync-s2`, durable stream store), Cloudflare Durable Objects, or custom. Presented at Local-first Conf 2025 and ViteConf 2025. Web-first; Expo/React Native experimental; no Flutter/Tauri story.

**Implication.** The *event-sourced log as the sync envelope* is a clean fit for agent-session histories and audit trails in the master goal — and a LiveStore-style event log could ride over the fabric exactly like S2 does. But LiveStore itself doesn't solve Flutter/Tauri.

Links: [LiveStore repo](https://github.com/livestorejs/livestore) · [Electric↔LiveStore integration](https://electric-sql.com/docs/integrations/livestore) (page dated 2026-04-20) · [S2 provider](https://s2.dev/docs/integrations/livestore) · [docs.livestore.dev](https://docs.livestore.dev/).

### 3.6 CRDT-native databases and frameworks

**Jazz** ([jazz.tools](https://jazz.tools/), [garden-co/jazz](https://github.com/garden-co/jazz), **MIT** © Garden Computing, active). Batteries-included local-first "relational database": typed **CoValues** (CoMap/CoList/CoStream/FileStream) with Groups-based permissions and E2E encryption, sync via Jazz Cloud (global storage mesh) or self-host; auth built in; React/RN/Svelte/Vue/Node. Blog: ["What is Jazz?"](https://jazz.tools/blog/what-is-jazz) (2026-04-18). Strong DX pitch; proprietary gravity toward Jazz Cloud; no Flutter.

**Triplit** ([aspen-cloud/triplit](https://github.com/aspen-cloud/triplit), **AGPL-3.0**). Triple-store client DB + TS server, schema-first, HLC-based CRDT conflict resolution, offline outbox, relational client queries. **Team acqui-hired by Supabase (Aug 2025); project now community-maintained** (last push 2026-01-19). AGPL + maintenance uncertainty = avoid for new commercial work.

**Evolu** ([evolu.dev](https://www.evolu.dev/), [evoluhq/evolu](https://github.com/evoluhq/evolu), MIT, active). SQLite + typed schema (Kysely-style), **E2E-encrypted by default**, sync via self-hostable or cloud **Relays**, **owner-sharded** data (each owner = one shard), per-field LWW CRDT, migrations, time travel. Platforms: all browsers, Electron, React Native; no Flutter. Docs (accessed): "Local-first platform … sync via self-hostable or cloud relays. End-to-end encrypted by default. Built on SQLite with a scalable sync protocol."

**InstantDB** ([instantdb/instant](https://github.com/instantdb/instant), Apache-2.0, 10.4k★, pushed 2026-07-16). **1.0 launched 2026-04-09.** All user data as **triples in one big multi-tenant Postgres**; **Clojure sync server**; WAL-driven **invalidator** that maps transactions to query "**topics**" (architecture essay explicitly credits Asana's Luna and Figma's LiveGraph); client-side triple store with InstaQL; auth/permissions/storage/presence/streams; multi-tenant control plane makes new apps ~free (2026 positioning: "backend for AI-coded apps"). Caveats from practitioners: non-normalized query cache offline; self-hosting less mature. Flutter: only unofficial packages (`instantdb_flutter`, `flutter_instantdb`).

**DXOS** ([dxos.org](https://dxos.org/), [dxos/dxos](https://github.com/dxos/dxos), **FSL-1.1-Apache-2.0** — notable; ~510★ but pushed 2026-07-18). ECHO reactive object DB (CRDT), HALO decentralized identity, MESH P2P (WebRTC swarm) networking; framework + Composer app. Ambitious, research-grade, low mainstream adoption; FSL license.

**Ditto** ([ditto.live](https://docs.ditto.live/), proprietary/commercial). CRDT document store + **P2P mesh sync over BLE/LAN/WiFi** plus Big Peer cloud; DQL subscriptions for partial replication; SDKs for Flutter (`ditto_flutter`, actively released), Swift, Kotlin, JS, RN, .NET, C++. Enterprise edge (airlines, point-of-sale); MongoDB reference-architecture partnership. PowerSync's own comparison (2025-01-28): "Ditto enables P2P syncing whereas PowerSync has a more traditional client-server architecture." The mesh transport (esp. BLE) is the closest existing analogue to the master's WebRTC/LoRa ambitions — but closed-source and expensive.

**cr-sqlite (vlcn)** ([vlcn-io/cr-sqlite](https://github.com/vlcn-io/cr-sqlite), MIT, 3.7k★). SQLite loadable extension (Rust/CGo) adding CRRs: per-column LWW + counter CRDTs, `crsql_changes` for delta extraction, site IDs, DB versioning. Companion TS (`vlcn.io` js, wa-sqlite fork). **Effectively dormant: last push 2024-10-25**; issues through Dec 2025 are mostly automated. The "SQLite extension with CRDT tables" idea remains attractive, but you'd be adopting an unmaintained core.

**RxDB** ([pubkey/rxdb](https://github.com/pubkey/rxdb), Apache-2.0 core + commercial premium plugins, 23k★, pushed 2026-07-18). NoSQL JSON documents over pluggable storage (IndexedDB, OPFS, SQLite-wasm premium, etc.); replication plugins for CouchDB, GraphQL, REST/WebSocket, NATS, Supabase; premium adds WebRTC P2P replication, encryption, shared workers. Broad but JS-only and backend-agnostic (you wire the server side).

**TinyBase** ([tinyplex/tinybase](https://github.com/tinyplex/tinybase), MIT, 5.1k★, **v9.2**). Reactive in-memory tabular store (+KV); **MergeableStore** (HLC-stamped CRDT) + **Synchronizers** (WS client/server, BroadcastChannel, custom); **Persisters** incl. IndexedDB, OPFS/sqlite-wasm, and **server-side PostgreSQL**; queries/indexes/relationships/metrics/checklists. v9.2 explicitly optimized for coding-agent discoverability. Best for small-to-medium per-user datasets; whole-store sync model.

**WatermelonDB** ([Nozbe/WatermelonDB](https://github.com/Nozbe/WatermelonDB), MIT, 11.7k★, last push 2025-08-11). Lazy-loading SQLite ORM for React/RN; sync = two-phase `pullChanges`/`pushChanges` protocol you implement (changes since timestamp + push local changes). No Postgres adapter out of the box; slow maintenance. Historical significance (Linear-style sync popularizer); not a 2026 pick.

### 3.7 CRDT libraries (the layer the master's Rust core should embed)

**Automerge** ([automerge/automerge](https://github.com/automerge/automerge), MIT). Rust core compiled to WASM (JS), plus C FFI (`automerge-c`); crate `automerge` **0.10.0 (2026-06-05)**. **Automerge 3.0 (2025-05-23):** columnar on-disk format now used in memory → **10×+ memory reduction**, faster loads; `automerge-repo` 2.0 (storage/network adapter toolkit: websocket, BroadcastChannel, IndexedDB; community WebRTC). Ink & Switch is also building **Beelay**, a generic sync server in Rust. Known caveats (official): very large histories still heavy; sync server must load documents into memory; authZ/E2EE/schema-change/versioning left to you. `autosurgeon` improves Rust ergonomics.

**Yjs / Yrs.** [yjs/yjs](https://github.com/yjs/yjs) (MIT, 22k★, active): YATA CRDT shared types (Text/Array/Map/XmlFragment), **providers**: `y-websocket`, **`y-webrtc`** (P2P mesh; default `maxConns = 20 + floor(rand*15)`, BroadcastChannel for same-browser), `y-indexeddb`, plus awareness/presence protocol; editor bindings (ProseMirror/TipTap/Lexical/CodeMirror/Monaco/Quill); servers: Hocuspocus (MIT), **Y-Sweet (Rust, MIT, self-hostable)**. **Yrs** ([y-crdt/yrs](https://github.com/y-crdt/yrs), MIT per lib.rs): the Rust port — **crate `yrs` 0.27.3 (2026-07-13), ~2.0M downloads** — the natural way to put Yjs semantics **inside a Rust core** (gen_ui_core) with FFI to Dart/wasm.

**Loro** ([loro-dev/loro](https://github.com/loro-dev/loro), MIT). **1.0 released 2026-06-15** ([announcement](https://loro.dev/blog/v1.0)); crate `loro` **1.13.7 (2026-07-15)**. Rust core + JS (WASM) + Swift. Eg-walker-based (OT-speed local ops, CRDT merge semantics), **Fugue** text (anti-interleaving), rich-text CRDT, **movable list & tree**, LWW map, **shallow snapshots** (git-shallow-clone analogue), version control + realtime collab in one model; 10× load improvement, million-op docs load ~1 ms (M1, vendor benchmark). P2P sync: "two rounds of data exchange" to converge.

### 3.8 Supabase Realtime + Supabase ETL (Rust)

**Realtime** ([supabase/realtime](https://github.com/supabase/realtime), Apache-2.0, Elixir/Phoenix). Listens to Postgres via logical replication, converts changes to JSON, broadcasts over WebSocket channels with **RLS-aware authorization** (Realtime Authorization, 2024); `postgres_changes` + Broadcast (incl. **Broadcast from Database**, 2025-04-02, and **Broadcast Replay**, 2025-12-05) + Presence; GA 2025; 10K+ concurrent connections. **It is not a sync engine**: no client persistence, no offline queue — complements (does not replace) a local DB. Flutter supported via `supabase_flutter`.

**Supabase ETL / Pipelines** ([supabase/etl](https://github.com/supabase/etl), Apache-2.0, 2.3k★, pushed 2026-07-17). **Rust CDC framework on Postgres logical replication** (begun as `pg_replicate`), launched as **Supabase Pipelines 2025-12-02**: pipeline abstraction, pgoutput decoding, replication-slot management, backfill + streaming, destinations (BigQuery/Iceberg/DuckDB/…). "Realtime or Pipelines?" (Supabase blog, 2026-05-05) distinguishes the two. **This is the most directly relevant open-source Rust codebase for building the fabric's logical-replication consumer.**

### 3.9 2025–2026 newcomers & market moves

- **TanStack DB** ([TanStack/db](https://github.com/TanStack/db), MIT, 3.8k★, launched 2025-07-29 with Electric): reactive client store — collections, sub-ms **live queries** (built on Electric's `d2ts` differential dataflow), optimistic **transactional mutations**; backends: Electric, PowerSync (`@tanstack/powersync-db-collection`), REST query collections, local-only. Becoming the de-facto web client layer over sync engines.
- **InstantDB 1.0** (2026-04-09), **Loro 1.0** (2026-06-15), **LiveStore beta** (2025-06), **Supabase Pipelines** (2025-12-02), **Electric 1.0 + Cloud + "agent platform" pivot** (2025→2026), **Convex local-first ambitions** ($24M raise, 2025-11-20 Local-First News), **PowerSync Rust client core + Sync Streams** (2025→2026).
- Scene-setting sources: [localfirst.fm landscape](https://www.localfirst.fm/landscape/tinybase) · [awesome-local-first](https://github.com/alexanderop/awesome-local-first) (2025-01-06) · ["Choosing a Sync Engine for Local-First in 2026" (johnny.sh)](https://johnny.sh/blog/choosing-a-sync-engine-in-2026/) (2026-03-09) · ["Local-First Software in 2026" (birjob)](https://www.birjob.com/blog/local-first-software-2026) (2026-05-15) · [youngju.dev sync-engine deep dive](https://www.youngju.dev/blog/culture/2026-05-16-realtime-collaboration-engines-sync-2026-liveblocks-partykit-yjs-automerge-electricsql-replicache-zero-jazz-tools-deep-dive) (2026-05-16) · [Local-First News](https://www.localfirstnews.com/2025-11-20/) (2025-11-20).

---

## 4. Implications for the master goal

### 4.1 Postgres-compatible embedded replicas — *validated, with assembly required*

- **Web:** PGlite is the only production-track embedded Postgres for browsers; its shape-sync extension shows the replica-applier pattern (`syncShapeToTable`), but is still beta and read-path oriented. The master's web client can run PGlite with a **custom applier** against the fabric's sync protocol instead of Electric's cloud.
- **Tauri:** `pglite-oxide` (PG 17.5, Wasmtime 44, Tauri guide, SQLx-compatible socket) proves the desktop node can run the *same engine* as web — full SQL + pgvector parity, no SQLite impedance mismatch. Open work: replica applier + write queue on top (none exists for pglite-oxide today).
- **Flutter mobile:** no embedded Postgres path; SQLite via **drift** is the pragmatic base. Consequence: the sync protocol should speak **table/row deltas with a schema-mapping layer** (like PowerSync's Sync Rules or Electric shapes) rather than assuming Postgres-on-client everywhere; the mobile schema is a subset/mapping of the central schema.
- **pgvector everywhere:** PGlite (web) + pglite-oxide (Tauri) + central Postgres give vector search parity on 2/3 surfaces; mobile needs a sqlite-vec-style fallback.

### 4.2 Logical-replication-based sync — *build in Rust, reference designs exist*

- **`supabase/etl` (Apache-2.0, Rust)** is the reference implementation for a Rust logical-replication consumer: pgoutput decode, slot management, snapshot→streaming transition, exactly-once-ish delivery. flint-realtime-fabric should **embed this layer** (or equivalent, e.g. the community `pglogrepl` crate) rather than delegate to an external Elixir/Kotlin service.
- **Fan-out/delivery layer:** Electric demonstrates HTTP+CDN fan-out (great for scale, weak for interactivity; long-poll criticized); Supabase Realtime demonstrates WS+authorization-per-channel; Zero demonstrates per-query interest registration (topics) with a server-side replica. **Recommended hybrid for the fabric:** WAL → Rust CDC → **shape/bucket registry** (partial replication) → WebSocket streams with per-client offsets; CDN-cacheable HTTP catch-up API for initial loads (Electric's best idea) + WS live mode (PowerSync/Realtime's best idea).
- **Partial replication:** three points on the spectrum — Electric **Shapes** (declarative table+where; simplest; proxy-injected authZ), PowerSync **buckets/priorities** (parameterized; best offline/write story; checkpointed), Zero **synced queries + permissions** (most expressive; needs server-side IVM). A shape+bucket hybrid with server-side authZ injection and priority ordering fits KnowMe's per-user/per-space scoping; PowerSync's pending **IVM-based materialized-view sync** (2026) is worth tracking for join-heavy shapes (`pg_ivm` is already their documented stopgap).

### 4.3 Write path — *the landscape's biggest unsolved seam; choose deliberately*

Options observed: (a) **server-authoritative API writes** (Electric, Zero) — simple, online-only-ish; (b) **client upload queue → idempotent backend writes** (PowerSync) — real offline writes with central authority; (c) **CRDT merge** (Automerge/Yjs/Loro/Jazz/Ditto/Evolu/cr-sqlite) — true multi-writer, but you own document granularity, compaction, and authZ; (d) **event log** (LiveStore) — audit-friendly, needs materializers.
**Recommendation pattern for KnowMe:** relational app data (settings schemas, skills metadata, entities) → (b) central-authority with client queues (PowerSync-style, but in the Rust fabric + flint-forge); collaborative artifacts (agent session streams, notes/docs, ContentBlock trees, A2UI layout state) → (c) CRDT documents (Yrs or Loro **inside gen_ui_core**) replicated over the same fabric; agent/event histories → (d) append-only streams (LiveStore/S2/Electric-Streams pattern).

### 4.4 CRDT over WebRTC (and LoRa) — *feasible; transport-adapter pattern is the precedent*

- Precedents: `y-webrtc` (mesh with maxConns cap, BroadcastChannel shortcut), automerge-repo's pluggable `NetworkAdapter`s, libp2p's browser WebRTC stack incl. Rust↔browser bridging (`libp2p-webrtc-websys`, crates.io, 2025-01), Ditto's BLE/LAN mesh (commercial proof that non-IP transports carry CRDT ops well).
- For a Rust fabric: **Yrs or Loro inside `gen_ui_core`** gives one CRDT implementation across Flutter (FFI via flutter_rust_bridge), Tauri (native), and web (wasm build of the same crate) — no existing engine offers that; this is where the master's "one Rust crate" invariant pays off.
- **lora-rs:** no sync engine supports LoRa transports today. Op-based CRDTs (Loro/Automerge) with small, idempotent ops are the right payload model for LoRa's tiny frames; treat it as another `NetworkAdapter`-style transport behind the same sync interface. Expect to build this — it's novel, not derivable.

### 4.5 Flutter reality check

Production-ready today: **PowerSync** (first-class Dart SDK, SQLCipher, drift ecosystem), **Supabase** (`supabase_flutter` realtime — but not offline sync), **Ditto** (proprietary). Everything else is community/absent. **Implication:** the fabric's client protocol should be simple enough to implement a **drift-side Dart client** (HTTP catch-up + WS deltas + upload queue + checkpoint persistence) — i.e., closer to PowerSync's documented wire model than to Zero's ZQL machinery.

### 4.6 Skills/settings/component distribution

Settings schemas + synced client/server storage map naturally to ordinary replicated tables (shape/bucket sync, §4.2). WASM components / A2UI modules / skills registries map to flint-forge's existing IPFS/OCI/S3 stores with **metadata tables synced** and payloads fetched by CID — the sync engines surveyed (esp. LiveStore's event log and Electric Streams) validate the "sync metadata, fetch content-addressed payloads" split; nobody syncs binaries through the sync engine itself.

---

## 5. Gaps and risks

1. **No off-the-shelf engine covers web(PGlite)+Tauri(pglite-oxide)+Flutter(SQLite)+Rust fabric.** The master goal inherently requires assembling: Rust CDC (supabase/etl-style) + shape/bucket partial replication + WS delivery + Dart/Tauri/web client appliers + CRDT overlay. This is buildable but is the project's critical path.
2. **License exposure:** Triplit **AGPL-3.0** (viral); PowerSync Service & DXOS **FSL-1.1** (non-compete window, Apache conversion only after 2 years); Ditto proprietary; RxDB's most interesting pieces (WebRTC replication, SQLite storage, encryption) are **paid premium**; InstantDB self-hosting maturity lags its cloud. Safe cores: Electric/PGlite (Apache-2.0), Zero/mono (Apache-2.0), LiveStore (Apache-2.0), supabase/etl+realtime (Apache-2.0), Automerge/Yjs/Yrs/Loro/Evolu/TinyBase (MIT).
3. **Maintenance risk:** cr-sqlite dormant since 2024-10; Triplit drifting post-Supabase-acquihire; WatermelonDB slow; Electric's agent-platform pivot may keep write-path/local-first features deprioritized; LiveStore still beta; Replicache frozen.
4. **Single-connection PGlite** (and pglite-oxide pool=1) shapes concurrency design on every embedded node (one writer backend; queue at the application layer).
5. **Electric critique is a design warning:** long-poll push + DIY writes was called out as the weak architecture by a practitioner (johnny.sh, 2026-03-09) — the fabric should do WS streaming + a first-class write path from day one.
6. **Zero's <100 GB guidance and TS-only clients** rule it out as infra; its permissions-in-schema and synced-query ideas still merit theft.
7. **CRDT libraries don't give you authZ, E2EE, compaction policy, or schema evolution** (Automerge's own docs say so); Evolu (owner-sharding + E2EE) and Jazz (Groups) are the reference patterns for those gaps.
8. **Supabase Realtime ≠ offline sync** — using it as the mobile sync story would leave no client persistence or queueing; it's a presence/broadcast complement only.
9. **LoRa sync is greenfield** — no engine, provider, or prior art found; needs threat-model + MTU-aware op batching design from scratch.

---

## 6. Appendix A — repo/license/status snapshot (GitHub API + crates.io, 2026-07-18)

| Repo | License | Stars | Last push | Note |
|---|---|---|---|---|
| electric-sql/electric | Apache-2.0 | 10,271 | 2026-07-17 | 1.0 GA 2025-03-17 |
| electric-sql/pglite | Apache-2.0 | 15,610 | 2026-07-15 | "beta" per vendor site |
| f0rr0/pglite-oxide | MIT+Apache-2.0+PostgreSQL | — | crates v0.5.1 (2026-06-04) | PG 17.5, Wasmtime 44, Tauri guide |
| powersync-ja/powersync-service | **FSL-1.1-ALv2** | 362 | 2026-07-15 | v1.23.2 (2026-07-02) |
| rocicorp/mono (Zero, Replicache) | Apache-2.0 | 3,310 | 2026-07-17 | old replicache repo archived |
| aspen-cloud/triplit | **AGPL-3.0** | 3,099 | 2026-01-19 | post-Supabase community maintenance |
| garden-co/jazz | MIT | 133 (core pkg repo) | 2026-07-17 | Jazz Cloud commercial |
| livestorejs/livestore | Apache-2.0 | 3,636 | 2026-07-17 | beta |
| instantdb/instant | Apache-2.0 | 10,354 | 2026-07-16 | 1.0 on 2026-04-09 |
| evoluhq/evolu | MIT | 1,866 | 2026-07-16 | E2EE relays |
| pubkey/rxdb | Apache-2.0 (+premium) | 23,273 | 2026-07-18 | premium plugins commercial |
| tinyplex/tinybase | MIT | 5,124 | 2026-07-17 | v9.2 |
| Nozbe/WatermelonDB | MIT | 11,751 | 2025-08-11 | slow |
| dxos/dxos | **FSL-1.1-Apache-2.0** | 510 | 2026-07-18 | ECHO/HALO/MESH |
| vlcn-io/cr-sqlite | MIT | 3,742 | **2024-10-25** | dormant |
| automerge/automerge | MIT | 6,427 | 2026-07-16 | crate 0.10.0 (2026-06-05) |
| yjs/yjs | MIT | 22,198 | 2026-07-15 | y-webrtc, y-websocket |
| y-crdt/yrs | MIT (lib.rs) | — | crate 0.27.3 (2026-07-13) | ~2.0M crate downloads |
| supabase/realtime | Apache-2.0 | 7,603 | 2026-07-17 | Elixir |
| supabase/etl | Apache-2.0 | 2,283 | 2026-07-17 | Rust CDC; Pipelines 2025-12-02 |
| loro-dev/loro | MIT | 5,898 | 2026-07-18 | 1.0 on 2026-06-15; crate 1.13.7 |
| TanStack/db | MIT | 3,820 | 2026-07-16 | 2025-07 launch |

## 7. Appendix B — highest-value links (with dates)

1. Electric 1.0 GA — https://electric.ax/blog/2025/03/17/electricsql-1.0-released (2025-03-17)
2. Electric agent-platform pivot — https://electric.ax/ (accessed 2026-06-26); repo https://github.com/electric-sql/electric
3. PGlite docs/product — https://pglite.dev/docs/about ; https://electric.ax/sync/pglite ; repo https://github.com/electric-sql/pglite
4. pglite-oxide — https://docs.rs/pglite-oxide ; https://github.com/f0rr0/pglite-oxide (crates.io v0.5.1, 2026-06-04)
5. Electric production/authz proxy pattern — https://neon.com/guides/electric-sql (accessed)
6. TanStack DB launch — https://electric.ax/blog/2025/07/29/super-fast-apps-on-sync-with-tanstack-db (2025-07-29); https://tanstack.com/db/latest
7. PowerSync 2025 roadmap update — https://powersync.com/blog/2025-powersync-roadmap-update (2026-01-05); changelog https://releases.powersync.com/announcements/powersync-service (2026-07-02); https://powersync.com/blog/powersync-changelog-november-2025 (2025-12-04)
8. Zero docs — https://zero.rocicorp.dev/ ; https://zero.rocicorp.dev/docs/when-to-use ; review https://marmelab.com/blog/2025/02/28/zero-sync-engine.html (2025-02-28)
9. LiveStore — https://github.com/livestorejs/livestore ; https://electric-sql.com/docs/integrations/livestore (2026-04-20); https://s2.dev/docs/integrations/livestore
10. InstantDB architecture — https://www.instantdb.com/essays/architecture (2026-04-09); https://github.com/instantdb/instant
11. Automerge 3.0 / Repo 2.0 — https://automerge.org/blog/automerge-3/ ; https://www.inkandswitch.com/newsletter/dispatch-011/ (2025-05-23); https://automerge.org/blog/automerge-repo/
12. Loro 1.0 — https://loro.dev/blog/v1.0 (2026-06-15); https://github.com/loro-dev/loro
13. Yjs/y-webrtc — https://github.com/yjs/yjs ; https://github.com/yjs/y-webrtc
14. Supabase ETL/Pipelines — https://github.com/supabase/etl ; https://supabase.com/blog/introducing-supabase-pipelines (2025-12-02); https://www.definite.app/blog/supabase-etl (2026-06-12)
15. Supabase Realtime — https://github.com/supabase/realtime ; blog index https://supabase.com/blog/tags/realtime (Broadcast from DB 2025-04-02; Replay 2025-12-05)
16. Choosing a sync engine 2026 (practitioner) — https://johnny.sh/blog/choosing-a-sync-engine-in-2026/ (2026-03-09)
17. Local-first 2026 overview — https://www.birjob.com/blog/local-first-software-2026 (2026-05-15); https://www.localfirstnews.com/2025-11-20/ (2025-11-20)
18. Ditto Flutter/P2P — https://www.ditto.com/blog/cross-platform-development-with-flutter-just-got-better (2025-04-01); comparison https://powersync.com/blog/ditto-vs-powersync (2025-01-28)
19. cr-sqlite — https://github.com/vlcn-io/cr-sqlite (dormant since 2024-10-25)
20. libp2p browser WebRTC (Rust↔browser) — https://libp2p.io/docs/webrtc-browser-connectivity/ (2026-03-13); https://crates.io/crates/libp2p-webrtc-websys (2025-01-15)
