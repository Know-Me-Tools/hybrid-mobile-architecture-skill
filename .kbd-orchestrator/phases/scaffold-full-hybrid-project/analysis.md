# Analysis — scaffold-full-hybrid-project

> Phase: `scaffold-full-hybrid-project` · Generated 2026-07-15
> Scope: technology landscape + build-vs-adopt decisions for the full example instance —
> an agentic application per the KnowMe model, running with common behavior on
> web (WASM), desktop (Tauri), and mobile (Flutter), all business/networking logic in Rust.

## 0. Target definition (from the two IPFS documents)

Both KnowMe documents were fetched and read
(`QmXFPBMvNw…` = functional spec v1.0; `QmWwTB6Mc…` = moodboard & user journeys v1.0):

- **Sovereign personal AI**: on-device inference (candle/llama.cpp GGUF), privacy by code
  location, no vendor servers in the data path.
- **Eight capability tiles** (Chat, Hands, Ask Image, Audio Scribe, Prompt Lab, Skills,
  Models, Settings) with the same React component tree across desktop/tablet/mobile.
- **SurrealDB local knowledge graphs** (memory, entity graph) with encryption at rest.
- **Cedar-governed autonomous agents** ("Hands") with deny-by-default skill access and
  human-in-the-loop consent.
- **OFP peer sync**: CRDT conflict resolution, Lamport clocks, no central broker.
- **WASM Component Model plugins** distributed via IPFS with Ed25519 signing.
- Stack named in spec: React 19, Vite 8, Tauri 2.10, SurrealDB 3.x (RocksDB), Cedar 4,
  Wasmtime — consistent with this repo's TJ-ARCH-MOB-001.

The example instance for this phase demonstrates the architecture that KnowMe-class
apps are built on.

---

## 1. Verified landscape findings

### 1.1 Embedded Postgres — CORRECTION to this repo's docs ⚠️

`docs/pglite-oxide-tauri-hybrid.md` (and the CLAUDE.md summary of it) contains two
**verified errors**:

1. pglite-oxide is **not** a "real PostgreSQL binary, Rust-native, not WebAssembly."
   The published crate (0.5.1, 2026-06-04) runs ElectricSQL's PGlite **WASI build inside
   a WASM runtime** (PostgreSQL 17.5 guest; bundles pgvector, pg_trgm, hstore, citext,
   ltree; exposes `PgliteServer` → real PG wire protocol → SQLx/tokio-postgres work).
2. **It does not support iOS/Android.** AOT runtime assets exist for Linux x64/arm64,
   macOS arm64, Windows x64 only. iOS structurally cannot run stock Postgres (no
   child processes, no JIT). The successor project "Oliphaunt" *claims* future native
   mobile Postgres but is pre-release (0.0.0, ~90 stars) — do not bet on it.

**Consequence:** "same Postgres SQL everywhere" holds for web/desktop/cloud, NOT mobile.
Mobile relational+vector = **SQLite (sqlx/rusqlite in Rust core) + sqlite-vec**.
→ Action item: fix `docs/pglite-oxide-tauri-hybrid.md` and CLAUDE.md claims (C-9).

### 1.2 Per-platform data layer matrix (adopt)

| Platform | Relational | Vector (RAG) | Graph RAG | Sync client |
|---|---|---|---|---|
| **Web** | PGlite 0.5.4 (`idb://` + relaxedDurability, multi-tab worker) | pgvector ext (HNSW works in WASM) | SurrealDB `kv-indxdb` (wasm32) or `@surrealdb/wasm` | `@electric-sql/pglite-sync` shapes |
| **Desktop (Tauri)** | pglite-oxide 0.5.1 (`PgliteServer` → sqlx `PgPool`; macOS arm64/Linux/Win x64) | pgvector (same SQL as cloud) | SurrealDB 3.2 `kv-rocksdb` | Rust Electric shape consumer |
| **iOS/Android (Flutter)** | SQLite via sqlx-sqlite in `gen_ui_core` | sqlite-vec (prebuilt iOS/Android libs) | SurrealDB 3.2 `kv-rocksdb` | Rust sync client (see 1.4) |
| **Cloud** | Postgres 18 / Supabase (RLS) | pgvector | SurrealDB server (FRF `frf-store-surreal` symmetry) | Electric sync-service 1.7.x |

Embedding dims: standardize on **384** (all-MiniLM/bge-small class) or truncated-768
(matryoshka) so vectors replicate cleanly across engines; generate on-device via
fastembed-rs/candle in `gen_ui_core`.

### 1.3 SurrealDB 3.2 embedded graph RAG (adopt — verified)

- `surrealdb = "3.2"` (3.2.1 latest, 2026-07-10). Engines: `kv-rocksdb` (native incl.
  iOS/Android), `kv-indxdb` (**wasm32 — first-class**), `kv-mem`, `kv-surrealkv` (beta).
- 2.x → 3.x breaking changes that affect our references/scaffolds: **MTREE removed → HNSW**
  (`DEFINE INDEX … HNSW DIMENSION 384 DIST COSINE`), `SEARCH ANALYZER` → `FULLTEXT
  ANALYZER`, function renames (`type::thing`→`type::record`, `rand::guid()`→`rand::id()`),
  `LET` required, synced writes default (slower writes), KNN operator `<|K,EF|>`.
- Graph RAG pattern verified: HNSW vector recall → `RELATE` graph expansion (recursive
  `@.{1..3}(->relates_to->entity)`) → BM25 full-text lane → reciprocal-rank fusion in Rust.
- **Caveat:** surrealdb-core build.rs re-run issue (#6954) → long compiles; isolate
  SurrealDB in its own crate (`gen_ui_db`) so it caches — reinforces the workspace split.
- **Dart access: FFI-only, confirmed.** No official Dart SDK; pub.dev community package is
  WebSocket-only, cannot do embedded. Expose intent-level functions
  (`memory_search(query,k)`, `graph_expand(id,depth)`) over frb — never raw SurrealQL.

### 1.4 Local-first sync (adopt read-path + decide write-path)

- **ElectricSQL v1.x** is read-path only (Postgres → HTTP "shapes"). Best fit for the
  Postgres-centric web/desktop story. Writes go through your own API — which is exactly
  what flint-gate/flint-forge provide. Shapes are plain HTTP+JSON: a **Rust consumer in
  `gen_ui_core`** serves desktop and mobile (write to SQLite), `pglite-sync` serves web.
- **PEM v4 already plans `prometheus-entity-sync` (PES)**: Rust-native bidirectional sync
  (Postgres WAL → FRF `frf-postgres-cdc` → bucket op-log → PSyncV1 WebSocket → PGlite/
  SQLite/pglite-oxide clients) with Dart and pglite-oxide as first-class targets. It
  exists as an OpenSpec umbrella (14 changes, waves 1–3 specified) — **not built yet**.
- **PowerSync** is the credible buy-option (Flutter+web+Kotlin+Swift, mature, Postgres
  upstream) if we want managed bidirectional sync now, at the cost of SQLite-shaped
  clients and the FSL license.
- **CRDT lane:** FRF ships `frf-crdt` (Loro) + `frf-store-redb` (on-device op-log) +
  `SyncService` (bidi op batches) — the OFP-style peer sync from the KnowMe spec.

**Contested choice (flagged, see Open Questions):** example-app write-path sync =
(A) DIY Rust Electric-shape consumer + write queue via forge API (smallest, proves the
architecture, aligns with PES later), vs (B) PowerSync (fastest to working bidirectional
sync, adds FSL dependency + parallel stack), vs (C) build PES wave-1 now (biggest, but
it's the ecosystem's declared direction). Recommendation: **(A)** for the example, with
trait seams (`SyncTransport`) that PES can implement later.

### 1.5 prometheus-entity-management (adopt for React; port model to Flutter)

Verified against the repo (all packages at **3.0.0-alpha.0**, pnpm+Turborepo monorepo):

- React binding = `@prometheus-ags/prometheus-entity-management`
  (dir `packages/entity-graph-react/`), single root export, ~547-line API surface:
  normalized Zustand+immer graph (`entities[type][id]`, lists hold IDs), v2 transport
  registry (`registerEntityTransport`, `makeRestTransport`), typed error taxonomy
  (Terminal/Transient + backoff), `useEntities`/`useEntityCRUD`, JSON-Schema & SQL-DDL
  entity registration (`registerEntityFromSql`), local-first runtime
  (`startLocalFirstGraph`, offline queue, retry+poison), adapters incl. **PGlite
  persistence, tenant-scoped ElectricSQL (the RLS-at-shape-factory enforcement seam),
  Tauri SQL, SurrealDB live, Flint realtime**, AG-UI ingestion + graph-as-LLM-tools.
- UI components are shadcn-token-compatible (cn() + shadcn CSS vars) — drop into a
  Tailwind 4 + shadcn theme. Example app already runs React 19.2.4 + Vite 8.0.3.
- Peers needed by consumer: zustand 5, immer, optional @tanstack/react-table, loro-crdt.
- **Flutter port design (build — new pub.dev package `prometheus_entity_management`):**
  canonical store lives in **Rust** (SQLite/pglite-oxide via `gen_ui_core`); Riverpod
  **provider families are the normalization map** (no hand-built Dart graph store);
  `EntityTransport` trait in Rust registered per type, exposed via frb + `ChangeEvent`
  stream; `ViewDescriptor`/`FilterSpec`/`SortSpec` mirrored as freezed unions ↔ Rust enums
  (compile-to-SQL in Rust); CRUD controller as `@riverpod class` composing list provider +
  selection + edit buffer with dirty-path tracking + optimistic snapshot/rollback;
  cascade invalidation via Rust-emitted invalidation events → one Dart bridge listener →
  `ref.invalidate`; relations schema and merge strategies (LWW/Loro) live in Rust.

### 1.6 Riverpod 3.x (adopt — mechanical migration from repo's 2.6 references)

Verified: riverpod/flutter_riverpod **3.3.2**, riverpod_annotation 4.0.3,
riverpod_generator 4.0.4, flutter_rust_bridge **2.12.0**.

- Changes affecting our references: unified `Ref` (typed `FooRef` gone), Notifier fusion
  (no more `AutoDisposeAsyncNotifier` supertypes), `AsyncValue` sealed, errors wrapped in
  `ProviderException`, `ref.mounted` guard, providers pause when widgets invisible.
- **Critical for FFI providers: automatic retry is ON by default** (200ms→6.4s backoff).
  Rust domain errors must set `retry: (_, __) => null` or Riverpod silently re-invokes
  the FFI call. This goes into the scaffold templates and references.
- New sanctioned patterns: **Mutations API** for send/submit flows (chat send), offline
  persistence (`riverpod_sqflite`) for provider cache.
- Streaming contract: `@riverpod` stream functions for read-only event feeds;
  `AsyncNotifier` + manual subscription + `ref.mounted` guard for ContentBlock folding
  (`ChatNotifier.streamBlock()` pattern survives with minor edits).

### 1.7 Flint platform integration (adopt — via Rust core; nothing on registries yet)

Verified division of labor:

```
Client (gen_ui_core owns ALL connections)
   │ HTTPS + SSE/WS, Bearer JWT or FLINT_ANON_KEY
   ▼
flint-gate :4456    — Kratos/JWT/API-key auth, Cedar NHI policies with
   │                  @require_approval human-in-the-loop, JWT minting
   │                  (anon/authenticated/agent/service_role), AG-UI/A2UI stream
   │                  filtering + token metering.  [phase: sdk-ecosystem DONE]
   ├─► flint-forge  — Postgres 18 + RLS Quarry (PostgREST-style REST + GraphQL +
   │                  graphql-transport-ws subs), A2UI registry AS AN MCP SERVER
   │                  (/mcp/v1/a2ui + SSE), AG-UI run streams (/agents/v1/*),
   │                  Kiln signed-WASM edge functions, Ember in-DB LLM.
   │                  [phase: p16 v1.0 release closure, executing]
   └─► flint-realtime-fabric — Iggy event spine, Loro CRDT SyncService,
                       frf-postgres-cdc, WebRTC signaling (sovereign SFU in
                       active dev — use LiveKit path near-term), EntityService
                       watch. gRPC native / Connect-web + frf-wasm browser.
                       [phase-36, mid-flight on feature branch]
```

Integration decisions:
- Consume `frf-sdk-rust` **inside `gen_ui_core`**; ignore FRF's UniFFI Dart bindings
  (broken generator, and wrong layer anyway). Browser surface uses `frf-wasm`/Connect-web.
- Forge's `/mcp/v1/a2ui` registers directly into `gen_ui_core::mcp::McpClient` (SSE
  transport exists both sides). AG-UI streams → existing ProtocolPipeline → ContentBlock.
- Auth: boot with `FLINT_ANON_KEY` → Kratos via gate → `authenticated`/`agent` JWT
  (`act` delegation claim for PMPO autonomous actions; gate Cedar `@require_approval`
  gives human-in-the-loop). Token lifecycle in Rust core. Keys spec is Draft (2026-07-15)
  — code to its claims schema (`role`, `principal_type`, `tenant_id`, `agent_id`,
  `workflow_id`, `act`).
- `@flint/react` and `flint_genui` (both v1.0.0, in-repo packages) slot into the
  presentation layer for A2UI surface rendering — but their built-in SSE transports are
  bypassed; the Rust core produces the event streams (layer contract).
- **All Flint SDKs/packages are unpublished** (path/git refs) → example app consumes via
  git dependencies or a private registry. Flag to Flint owners for publishing cadence.

### 1.8 Startup: migrations, seed data, distribution (adopt patterns)

- **One schema source of truth** → per-dialect migration sets: sqlx `migrate!`/refinery
  (Rust: desktop pglite-oxide, mobile SQLite — identical mechanism, different dialect),
  drizzle-kit bundled JSON (web PGlite). Additive-only while old clients live; `pgroll`
  for server-side zero-downtime cuts; schema-fingerprint check at client boot.
- **Boot order invariant: migrations → seed/lookup bundles → sync shapes attach.**
  (Shapes fail on unknown columns.)
- Seed distribution ladder: (1) bundled assets copy-on-first-run (lookup tables);
  (2) PGlite `dumpDataDir()`/`loadDataDir()` snapshot tarballs (fastest web cold start);
  (3) versioned HTTP lookup bundles with 304s (data that changes between releases);
  (4) IPFS content-addressed seed snapshots (CID-verified — fits Rule 12 and the KnowMe
  plugin-distribution model; DIY tooling, no off-the-shelf).
- SurrealDB migrations: no in-place 2.x→3.x RocksDB upgrade — in-app export→import step
  where prior data exists; for the new example this is greenfield.

---

## 2. Build-vs-adopt verdicts

| Capability | Verdict | Choice |
|---|---|---|
| Web relational+vector | **Adopt** | PGlite 0.5.x + pgvector + live + multi-tab worker |
| Desktop relational+vector | **Adopt** | pglite-oxide 0.5.1 (watch Oliphaunt) |
| Mobile relational+vector | **Adopt** | SQLite (sqlx) + sqlite-vec in `gen_ui_core` |
| Graph RAG (all platforms) | **Adopt** | SurrealDB 3.2 embedded (rocksdb native / indxdb wasm) |
| Read-path sync | **Adopt** | Electric shapes (pglite-sync web; Rust consumer native) |
| Write-path sync | **Contested** | DIY queue via forge API (rec) vs PowerSync vs PES-now |
| React entity mgmt | **Adopt** | `@prometheus-ags/prometheus-entity-management` 3.0.0-alpha.0 |
| Flutter entity mgmt | **Build** | `prometheus_entity_management` (Dart) per §1.5 design, Rust-backed |
| Peer CRDT sync (OFP-style) | **Adopt** | FRF `frf-crdt` (Loro) + `frf-store-redb` + SyncService |
| Auth/gateway | **Adopt** | flint-gate (anon/authenticated/agent keys, Cedar approvals) |
| Server data plane | **Adopt** | flint-forge Quarry (REST/GraphQL under RLS) + Kiln + MCP |
| Realtime spine | **Adopt** | flint-realtime-fabric via frf-sdk-rust / frf-wasm |
| Embeddings on-device | **Adopt** | fastembed-rs (384-dim default) in `gen_ui_core` |
| State mgmt Flutter | **Adopt** | Riverpod 3.3.2 (+ retry opt-outs on FFI, Mutations API) |
| State mgmt React | **Adopt** | Zustand 5 (+ PEM graph store) + TanStack |
| Migrations | **Adopt** | sqlx/refinery (Rust) + drizzle-kit (web), additive-only |

## 3. Impact on the assessment's change list

The analysis refines assessment C-1…C-8 and adds:

- **C-1 (workspace split)** gains a `gen_ui_db` sub-structure: `db/relational` (feature:
  `pg` for sqlx-postgres targeting pglite-oxide/cloud, `sqlite` for sqlx-sqlite mobile),
  `db/graph` (SurrealDB), `db/sync` (Electric shape consumer + write queue + trait seam
  for PES). SurrealDB isolated in its own crate for compile-cache reasons (#6954).
- **C-2 (WASM)** now concrete: `kv-indxdb` SurrealDB + PGlite interop on web; needs an
  early spike validating `gen_ui_core`-on-wasm32 with the full dep tree.
- **C-4 (Flutter packaging)** becomes two packages: `gen_ui_flutter` (FFI plugin) +
  `prometheus_entity_management` (the PEM-model Dart package, §1.5).
- **C-5 (React packaging)** consumes PEM 3.0.0-alpha.0 rather than reinventing; example
  app wires `registerEntityTransport` to forge Quarry REST + tenant-scoped Electric.
- **NEW C-9:** correct `docs/pglite-oxide-tauri-hybrid.md` + CLAUDE.md (pglite-oxide is
  WASM-runtime-based, desktop-only; mobile = SQLite+sqlite-vec; update the per-target
  mapping table; update references/flutter & rust patterns for Riverpod 3 / SurrealDB 3).
- **NEW C-10:** example-app startup orchestration module (migrations → seeds → shapes,
  per-platform) + seed distribution (bundled + IPFS CID option).
- **NEW C-11:** Flint integration layer in `gen_ui_core` (gate auth/token lifecycle,
  forge MCP registration, FRF spine via frf-sdk-rust, git-dependency wiring).

## 4. Open questions (for the user / plan phase)

1. **Write-path sync for the example app** — contested (§1.4): DIY-via-forge (rec) /
   PowerSync / build PES wave-1 now. Score gap between DIY and PowerSync < 15% on our
   criteria (speed-to-demo vs ownership) → flagging per protocol instead of silently
   picking. **Recommendation: DIY with PES-compatible trait seams.**
2. **Example app scope**: full 8-tile KnowMe demo vs a thinner vertical slice (Chat +
   entity CRUD + memory/RAG + sync status) that proves every architectural seam?
   Recommendation: vertical slice; the tiles are product work, not architecture proof.
3. **Flint git-dependency pinning**: pin to commit SHAs (reproducible) or branch heads
   (fresh)? Recommendation: SHAs, bumped deliberately.
4. **`flint-realtime-fabric` main vs feature branch**: repo is mid-flight on
   `sovereign-sfu-decode-proof`; media features should target the LiveKit path near-term.
5. **Publishing**: when do Flint SDKs/PEM land on registries? Example uses git deps until then.

## 5. Research provenance

Four parallel deep-research agents (2026-07-15): PEM repo inspection; flint-gate/FRF/forge
inspection (post `git pull` — all repos were current; FRF local main fast-forwarded without
touching its feature branch; flint-forge is 14 commits ahead of origin, nothing to pull);
PGlite/pglite-oxide/local-first/migrations (web-verified against crates.io/docs.rs/npm);
SurrealDB 3.2 + Riverpod 3 (web-verified). Both KnowMe IPFS docs fetched and read.
Key sources cited inline in the per-agent reports; version pins recorded in
`library-candidates.json`.
