# Deep-Dive: flint-realtime-fabric as the KnowMe Sync Backbone

> Research brief · KNOWME_RESEARCHER · 2026-07-18
> Subject repo: `/Users/gqadonis/Projects/prometheus/flint-realtime-fabric`
> Master goal lens: local-first pglite (web) / pglite-oxide (Tauri) clients syncing through
> flint-realtime-fabric (FRF) to central Postgres (flint-forge), CRDT over WebRTC/lora-rs,
> WASM component model, decentralized packaging.

---

## 1. What exists (facts)

### 1.1 Repository status

- Contract-first Cargo monorepo (24 workspace crates + `uniffi-bindgen` bin crate),
  edition 2024, MSRV `rust-version = "1.85"` (`Cargo.toml` workspace manifest).
- README's "Current State" section says "Phase 18 complete" but is **stale**: `docs/` contains
  signoffs through **PHASE-35** (2026-07-09), and `.kbd-orchestrator/current-waypoint.json`
  (updated 2026-07-10) shows **phase-36 "sovereign-sfu-ice-linux-fix" execute_ready**.
  Phases 19–35 were consumed almost entirely by the sovereign-SFU (str0m) browser decode
  proof, which has never produced a decoded frame (`framesDecoded=0`); `SFU_MODE=sovereign`
  remains **gated OFF** (`docs/PHASE-35-SIGNOFF.md`, `docs/SECURITY.md` §6).
- Core data/sync planes were completed and hardened in phases 0–18: all **six proto services
  are live** on the gateway (`docs/API-REFERENCE.md`): `SpineService`, `SignalService`,
  `SyncService`, `AgentService`, `EntityService` (p17-c004), `AuthzService` (p17-c005).
- Frozen contract: `proto/flint/v1/{envelope,entity,agent,signal,sync,authz}.proto`,
  tagged `proto-v1`; breaking changes require a new proto version (CLAUDE.md).

### 1.2 Verified dependency pins (workspace `Cargo.toml` + `Cargo.lock`, confirmed in lock)

| Concern | Crate / version |
|---|---|
| CRDT engine | `loro 1.13.1` (+ `loro-ffi 1.13.1`) — ADR-001, accepted 2026-06-19 |
| On-device op-log | `redb 4.1.0` (`frf-store-redb`) |
| Server CRDT store | `surrealdb 3.1.5` (`frf-store-surreal`) |
| Event spine | `iggy` — **git fork `github.com/GQAdonis/iggy`, branch `master`** (`frf-broker-iggy`) |
| Postgres CDC | `pg_walstream 0.6` + `tokio-postgres` (`frf-postgres-cdc`) |
| Gateway | `axum 0.8.8`, `tonic/tonic-web/prost 0.14`, `tower_governor 0.8` (rate limit) |
| Media | `str0m 0.21.0` (sovereign SFU), `livekit-api 0.5.2` (hosted) |
| AuthN | `jsonwebtoken 9` vs flint-gate JWKS (`frf-identity-ory`) |
| AuthZ | Ory Keto over HTTP + `dashmap` cache (`frf-authz-keto`) |
| Policy | `cedar-policy 4` (`frf-policy-cedar`, embedded `policy.cedar`) |
| FFI | `uniffi 0.31.2` (ADR-003); Dart via `uniffi-bindgen-dart 0.1.3` |
| Browser | `wasm-bindgen 0.2` (`frf-wasm`), Connect-ES `@connectrpc/connect ^1.7` (TS SDK) |
| Actors | `ractor 0.15` (`frf-librefang`, "BossFang") |

### 1.3 Crate map (all present on disk under `crates/`)

- Layer 0/1: `frf-domain` (pure types, newtype IDs `EntityId`/`TenantId`/`ChannelId`,
  `#[non_exhaustive]` enums), `frf-ports` (12 trait seam files), `frf-app` (use-cases:
  `publish.rs`, `subscribe.rs`, `sync.rs`, `entity.rs`, `authz.rs`).
- Ports (`frf-ports/src/`): `log_broker.rs` (`LogBroker`), `authz.rs` (`AuthzProvider`),
  `identity.rs` (`IdentityVerifier`), `crdt_store.rs` (`CrdtStore`, `CrdtSnapshot`),
  `op_store.rs` (`OpStore`, `PendingOp`, `ApplyDelta`), `media.rs` (`MediaSignaler`),
  `media_transport.rs` (ADR-005 `MediaTransport`), `federation.rs` (`FederationBridge`),
  `agent_bus.rs`, `entity_store.rs`, `policy.rs`.
- Adapters: `frf-broker-iggy`, `frf-authz-keto`, `frf-identity-ory`, `frf-policy-cedar`,
  `frf-postgres-cdc`, `frf-crdt` (Loro), `frf-store-surreal`, `frf-store-redb`,
  `frf-media-str0m`, `frf-media-livekit`, `frf-bridge-matrix`, `frf-bridge-atproto`,
  `frf-agentproto`, `frf-librefang`.
- Interface/SDK: `frf-gateway` (bin+lib), `frf-cli`, `frf-sdk-rust`, `frf-ffi`, `frf-wasm`,
  `uniffi-bindgen`; generated SDKs in `sdks/{go,ts,csharp,swift,kotlin,dart,entity-management}`;
  `admin-ui/` (React 19 / Vite 7 / shadcn-ui), embedded into the gateway via `rust-embed`.

---

## 2. How it works

### 2.1 Architecture: feature-based hexagonal, compiler-enforced

`frf-domain` ← `frf-app`/`frf-ports` ← adapters ← `frf-gateway` is the only composition
root (README §Architecture; CLAUDE.md "Absolute Dependency Rule"). One port per adapter;
planes are selected at deploy time by which adapters `main.rs` wires. Quality gates:
workspace clippy `pedantic` warn + `unwrap_used`/`expect_used` deny; `#![deny(warnings)]`
in library crates; ≤500 lines/file.

### 2.2 Transports (one contract, three wire surfaces)

- **Native gRPC (HTTP/2)** on `GRPC_PORT`: all six tonic services registered in
  `crates/frf-gateway/src/main.rs` (~L390–400) with `accept_http1(true)` +
  `tonic_web::GrpcWebLayer` so browsers can reach them via **Connect/gRPC-web over HTTP/1.1**.
- **Axum WebSocket mux** on the HTTP port (`crates/frf-gateway/src/lib.rs` `build_router`):
  `/ws/v1/subscribe` (spine fan-out, JSON frames), `/ws/v1/agents` (agent event stream),
  `/ws/v1/signal` (WebRTC signaling, JSON `SignalFrame`), plus `POST /v1/publish`-style
  REST publish route. **There is no `/ws/v1/sync` route** — CRDT sync is gRPC-bidi only.
- Browser WS auth is `?token=` query param (browsers cannot set headers);
  HTTP/gRPC use `Authorization: Bearer` (`docs/SECURITY.md` §1).

### 2.3 Event spine + Postgres CDC (the Supabase-style plane)

- `frf-broker-iggy` implements `LogBroker` (publish/subscribe/checkpoint) over the owner's
  Apache Iggy fork; durable offsets let SDKs resume (`SubscribeRequest.from: Offset`).
- `frf-postgres-cdc` (`consumer.rs`, `decode.rs`, `config.rs`): opens a replication
  connection (`replication=database`), ensures a logical slot, streams **pgoutput protocol
  v2** in text mode via `pg_walstream`, decodes Insert/Update/Delete into
  `frf_domain::EntityChange` (PK column → `EntityId`), publishes to a configured spine
  channel, then advances the applied LSN (`feedback_interval` 10 s). `CdcConfig` is
  **single-tenant, single-channel** (`tenant_id`, `channel_path`) — multi-tenant fan-out
  is a deployment/topology question, not handled inside the consumer.
- Fan-out pipeline (RFC §07, implemented in `frf-app`): subscribe-time Keto
  `check(subject,"view",topic)` (coarse, cached via `frf-authz-keto/cache.rs` dashmap),
  then per-event Keto `view` check before delivery ("per-event RLS"). Tenant-equality
  guard on publish (p16). The per-event-check scaling hazard is explicitly flagged in
  `docs/IMPLEMENTATION-PLAN.md` §07 with mandatory mitigations (subscribe-time scoping,
  topic partitioning, check-cache with tuple-delete invalidation).

### 2.4 CRDT model

- **Engine: Loro 1.13.1**, chosen over automerge-rs in `docs/decisions/adr-001-crdt-engine.md`
  (2–9× faster encode/decode, 3.7× smaller docs, 2.7× less memory, Fugue anti-interleaving,
  first-party `loro-ffi` + production `loro-swift`; automerge-uniffi judged experimental).
  External corroboration: Loro 1.x line active through mid-2026 (loro-dev org, updated
  Jun 2026 — https://github.com/orgs/loro-dev/repositories, accessed 2026-07-18).
- `frf-crdt` is deliberately thin: `apply_delta(&[u8],&[u8]) -> Vec<u8>` (merge.rs),
  `LoroDeltaApplier` (implements the `ApplyDelta` port), `InMemoryCrdtStore`,
  `merge_into_store`, `export_updates_since` (store.rs). Deltas travel as opaque `bytes`
  (`SyncOp.payload`) — the engine encoding is never in the wire or FFI contract.
- Ports: `CrdtStore` (checkpoint/restore/purge of versioned snapshots),
  `OpStore` (device write-ahead log: `queue_op`/`drain_pending`/`mark_synced`, with
  `local_seq` acknowledgment), `ApplyDelta` (engine merge injected into app layer).
- `frf-app/src/sync.rs` `SyncUseCase::apply_server_delta`: restore snapshot → merge delta →
  checkpoint → `mark_synced(confirmed_seq)` → count remaining pending ops.
- Wire: `sync.proto` `SyncService.Sync` (bidi stream of `SyncRequest{ops}` ↔
  `SyncResponse{merged_ops, checkpoint}`) + unary `GetCheckpoint`. Server side:
  `crates/frf-gateway/src/sync_grpc_service.rs`.
- **⚠ `SyncGrpcService` performs NO authentication** — unlike Spine/Signal/Agent services,
  which extract and verify the bearer JWT per-RPC (`grpc_service.rs` L165+,
  `signal_service.rs` L230+, `agent_grpc_service.rs` L63+), `sync_grpc_service.rs` has no
  token extraction, no identity verify, no tenant-equality check. Any caller that can reach
  the gRPC port can push CRDT ops for any `entity_id`/`tenant_id`. (Verified by grep:
  no `token|jwt|verify|auth|interceptor` matches in that file.)
- Default wiring in `main.rs` uses `InMemoryCrdtStore` + `RedbOpStore::in_memory()`;
  `SurrealCrdtStore` (`frf-store-surreal`, table `crdt_snapshots`, UPSERT on
  `(entity_id, tenant_id)`) exists but must be explicitly wired for persistence.
- Offline lifecycle (RFC §06): device appends to local redb op-log, applies optimistically,
  sends version vector on reconnect, exchanges only missing ops; checkpoints + announce ride
  the spine. **P2P CRDT-over-WebRTC from the RFC behavior map is not implemented** (see §4).

### 2.5 WASM capabilities

- `frf-wasm` (`cdylib`+`rlib`, wasm-bindgen): `crdt_apply_delta` (Loro merge in-browser,
  target-independent), plus wasm32-only `subscribe` (raw `web_sys::WebSocket` to
  `/ws/v1/subscribe`), `publish` (fetch), `AgentStream`. Built into `sdks/ts/frf-wasm/`
  (wasm + JS glue present).
- This is **not** a WIT/component-model runtime: no sandboxing, no component registry, no
  host-guest ABI beyond wasm-bindgen. The WIT component model in the Prometheus stack lives
  in **flint-forge**, not FRF.

### 2.6 FFI / UniFFI surface for mobile & desktop embedding

- `frf-ffi` (`cdylib`+`staticlib`, UniFFI 0.31.2, `async_runtime = "tokio"`):
  - `FrfFfiClient` (`client.rs`): async `connect(endpoint, token)`, `publish(envelope_json)`,
    `ack(...)`; `subscribe(...)` spawns a `resilient_subscribe` stream (exponential backoff,
    resume-from-offset, mirroring `frf-sdk-rust::ReconnectPolicy`) delivering JSON envelopes
    to a foreign `EventCallback` trait. Domain types cross as JSON strings — wire encoding
    never in the FFI contract.
  - CRDT free functions: `crdt_apply_delta`, `crdt_new_snapshot`, `crdt_snapshot_version`.
- Generated: Swift + Kotlin via workspace `uniffi-bindgen` crate; **Dart via
  `uniffi-bindgen-dart 0.1.3`** (ADR-003 — flutter_rust_bridge cannot parse a UniFFI crate).
- **Dart transport gap (p18-c009):** `uniffi-bindgen-dart` 0.1.3 cannot emit the async
  constructor/callback ABI, so `FrfFfiClient.connect` throws at runtime. `sdks/dart/lib/src/
  transport.dart` ships an honest shim: `FrfCrdt` (sync CRDT surface, fully usable) +
  `FrfTransport` stubs throwing `FrfTransportUnavailable`. Flutter clients today get Loro
  merge but **no FRF transport** over this binding.
- `frf-sdk-rust` is the hand-written full client (all six services, gRPC, resilient
  subscribe) — the natural embed for any Rust host (e.g. Tauri/`gen_ui_core`).

### 2.7 Identity / AuthZ / Policy stack

- **AuthN:** flint-gate mints JWTs; gateway verifies RS256 against `GATEWAY_JWKS_URL`,
  enforces `JWT_AUDIENCE`, and **mandatory `JWT_ISSUER` in production** (p16-c004). Verified
  claims (`tenant_id`, `subject`, `session_id`) are the only trusted source downstream.
  `DEV_NO_AUTH` bypass is compile-gated behind the `dev-endpoints` cargo feature and absent
  from production images.
- **AuthZ (visibility):** Ory Keto (Zanzibar) via `AuthzProvider`; `AuthzService` gRPC
  exposes Check/WriteRelation/DeleteRelation, tenant-equality enforced per call (p17-c005);
  `frf keto seed|revoke` CLI for operators. User-controlled rights = owners writing relation
  tuples (RFC §07).
- **Policy (actions):** Cedar (`frf-policy-cedar`, embedded `policy.cedar`) — mutating-op
  authorization, orthogonal to Keto; do-not-conflate rule in CLAUDE.md.
- Independent re-audit (phase 16/17): **zero CRITICAL/HIGH** in the production build;
  rate-limit (tower-governor), body-size, CORS middleware on all HTTP routes.

### 2.8 Agent protocols

`frf-agentproto` holds AG-UI / A2A / A2UI schemas; `ContentBlock` enum (serde-tagged:
`text_delta`, `tool_call`, `tool_result`, `state_snapshot`, `run_start`, `run_end`,
`error`, forward-compatible `Unknown`) maps to `AgentEvent` on the `flint:agent` channel
family; `AgentService.RunAgent` is bidi gRPC with JWT verification. `frf-librefang` wires
ractor actors to publish/consume spine facts ("BossFang").

### 2.9 Media & federation (status honesty)

- str0m sovereign SFU: full session engine (`session.rs`, `sfu.rs`, `demux.rs` per ADR-008
  shared-socket), DTLS connectivity proven in-process, N-peer fan-out + PLI forwarding
  unit-tested, browser-drivable over `/ws/v1/signal` with per-participant Keto `view`
  check at room-join (ADR-007) — but **end-to-end decoded media never proven** (phases
  23–35; 11 blockers, mostly same-host Docker/Colima candidate topology; CI Linux run
  29057452278 reached `ice=checking`). `SFU_MODE=sovereign` stays OFF; **LiveKit hosted is
  the working media path**; LiveKit cross-node inbound relay is capability-gated behind the
  `realtime` cargo feature (off by default).
- Federation (behind `FEDERATION_ENABLED` + mandatory tenant/channel env): Matrix inbound
  (real `/sync` long-poll) + outbound (room send) functional; ATProto inbound (Jetstream WS)
  + outbound (PDS `createRecord`) functional when `ATPROTO_PDS_*` all-or-none set.

---

## 3. Implemented vs planned (authoritative)

| Plane | Status | Evidence |
|---|---|---|
| Spine pub/sub + resume (Iggy) | ✅ live | API-REFERENCE; phase-16/17 signoffs |
| Postgres CDC → spine | ✅ live | `frf-postgres-cdc`; `scripts/smoke-cdc.sh` |
| Keto RLS fan-out + Cedar policy | ✅ live (scale unproven) | SECURITY.md; RFC §07 hazard note |
| EntityService / AuthzService | ✅ live (p17) | API-REFERENCE |
| CRDT sync (Loro) client↔server bidi | ✅ live, **unauthenticated** | `sync_grpc_service.rs` (no auth code) |
| CRDT persistence (SurrealDB) | ✅ adapter exists, **not wired by default** | `main.rs` uses `InMemoryCrdtStore` |
| P2P CRDT over WebRTC data channels | ❌ not implemented | no `RTCDataChannel`/`DataChannel` anywhere in `crates/`; RFC map says "live: no" |
| lora-rs / LoRa transport | ❌ absent | no matches in repo |
| Browser CRDT sync transport | ❌ no `/ws/v1/sync`; gRPC-bidi unreachable from browsers | §4.1 below |
| Swift/Kotlin SDKs (UniFFI) | ✅ generated | `sdks/swift`, `sdks/kotlin` |
| Dart/Flutter transport | ❌ CRDT-only (async ABI blocked upstream) | `sdks/dart/GENERATED.md`, `transport.dart` |
| str0m sovereign SFU media | ◐ composed + layer-proven; **gated OFF** | PHASE-23…35 signoffs |
| LiveKit hosted media | ✅ working path; cross-node inbound gated | SECURITY.md §6 |
| Matrix / ATProto bridges | ✅ functional (scoped) | SECURITY.md §6 |
| frf-wasm browser SDK | ✅ (WS subscribe/publish/agent + Loro merge) | `sdks/ts/frf-wasm/` |
| WIT / WASM component model | ❌ not in FRF (lives in flint-forge) | crate survey |
| Spine → Postgres write-back | ❌ no writer adapter in FRF | crate survey; CDC is one-way pg→spine |

---

## 4. Implications for the master goal

### 4.1 How a pglite (web) client attaches

Attach points that exist **today**:
1. **Notification plane:** `@prometheusags/frf-sdk` (`SpineClient`) over Connect/gRPC-web
   (server-streaming `Subscribe` works in browsers) or `frf-wasm` WS subscribe — both give
   live `EntityChange` / `EventEnvelope` delivery with resume-from-offset; the
   `sdks/entity-management` `RealtimeAdapter` already maps envelopes to entity events and is
   the intended seam for `prometheus-entity-management` 3.x over PGlite (per TJ-ARCH-MOB-001).
2. **CRDT merge in-browser:** `frf-wasm::crdt_apply_delta` (or `loro-crdt` JS) applies Loro
   deltas locally; snapshots persist in IndexedDB.

The blocking gap: **CRDT `SyncService.Sync` is bidi-streaming, and browser transports cannot
do client/bidi streaming** — Connect-web/gRPC-web buffer request bodies (Connect maintainers:
https://github.com/connectrpc/connect-go/discussions/254, accessed 2026-07-18; bidi requires
HTTP/2 full-duplex, cf. connect-go issue #342). FRF has WS routes for subscribe/agents/signal
but **none for sync**. So a browser PGlite client cannot currently be a full CRDT sync peer.
Options, in increasing effort:
- (a) *Pull model*: poll unary `GetCheckpoint` + spine invalidation events; merge with
  frf-wasm; push local ops via unary `Publish` on a CRDT channel (server re-maps to
  SyncUseCase). Works with today's contract.
- (b) *Add `/ws/v1/sync`*: JSON/binary-framed WS route driving the same `SyncUseCase` —
  mirrors how `/ws/v1/signal` was added for browsers (precedent: p23-c003). Clean, small,
  and consistent with FRF idioms. Recommended.
- (c) Electric's `@electric-sql/pglite-sync` (0.6.3, Jun 2026 — https://github.com/electric-sql/pglite/releases,
  accessed 2026-07-18) shape-syncs Postgres→PGlite directly, bypassing FRF — but it is
  read-path-only (writes need your own API), has no CRDT semantics, and conflicts with the
  "FRF is the sync backbone" goal; treat as fallback, not primary.

### 4.2 How a pglite-oxide (Tauri) client attaches

This is the **clean path** — everything needed exists in Rust:
- In `gen_ui_core` (or a sibling crate), depend on `frf-sdk-rust` (full six-service client,
  native HTTP/2 gRPC — bidi works) + `frf-crdt` (Loro) + `frf-store-redb` (durable op-log).
  The Tauri desktop client becomes a first-class sync peer: queue ops offline in redb,
  stream them over `SyncService.Sync`, merge server deltas, checkpoint locally.
- pglite-oxide remains the relational/vector store; the Loro doc mirror holds
  collaborative/entity state; PG rows project from merged CRDT state (or stay authoritative
  for non-collaborative tables). Note pglite-oxide speaks the PG wire protocol, but
  **FRF's CDC consumer cannot attach to it** — PGlite does not expose logical replication
  slots, and `pg_walstream` requires them. The attach is at the sync-protocol layer, not WAL.
- Do **not** route this through `frf-ffi`/`sdks/dart`: that path is for Swift/Kotlin/Dart
  hosts. A Rust host uses the native crates directly — no FFI tax, identical merge code.

### 4.3 The central Postgres (flint-forge) loop

- Server→client: flint-forge's Postgres 17 WAL → `frf-postgres-cdc` → Iggy spine →
  Keto-filtered fan-out → subscribed clients. Proven and live.
- Client→server: **FRF has no spine→Postgres writer**. Today a client write path is either
  (a) CRDT deltas into `SyncService` (merged snapshot in SurrealDB/memory — Postgres never
  sees it), or (b) `Publish` to the spine (durable log, but nothing projects to Postgres).
  The master architecture needs a **writer/projection service** (natural home: flint-forge,
  consuming spine topics and applying to Postgres, which then re-emits via CDC — a clean
  event-sourced loop). This is a build item, not an FRF change per se.
- Multi-tenancy: `CdcConfig` is single-tenant/single-channel — the topology for N tenants
  (one consumer per tenant? channel naming convention `entity/changes/<tenant>`?) must be
  designed in the target architecture doc.

### 4.4 WASM component model positioning

FRF's `frf-wasm` ≠ the component model. In the master architecture, flint-forge's WIT
registry/components (skills, A2UI/AG-UI/HTMX modules, settings schemas) should treat FRF as
the **message substrate**: agent/component events ride `AgentService`/spine channels as
`ContentBlock`-typed envelopes; component distribution (IPFS/OCI/S3) stays in flint-forge's
extension registry. Do not duplicate a registry in FRF.

### 4.5 WebRTC / lora-rs CRDT sync positioning

- The RFC already *envisions* P2P CRDT over WebRTC ("Co-present devices skip the server
  entirely… reconcile peer-to-peer"), and the signaling plane (`SignalService`, str0m
  session engine, room router) is built. What is missing is a **data-channel sync adapter**:
  a `PeerSyncTransport` port implementation over str0m `RTCDataChannel` (str0m supports data
  channels) exchanging Loro `export_updates_since` deltas. This is a net-new crate
  (`frf-sync-str0m`?) — the ports pattern makes it additive.
- lora-rs: zero presence. A LoRa transport would be another adapter behind the same port,
  exchanging opaque delta bytes; nothing in FRF blocks it, nothing provides it.

---

## 5. Gaps / risks (ranked)

1. **[Security, high] `SyncService` is unauthenticated** — no JWT verification or tenant
   check in `sync_grpc_service.rs`, unlike its five sibling services. Must be fixed (bearer
   extraction + identity verify + tenant-equality, copying `grpc_service.rs`) before any
   production sync topology. 
2. **[High] No browser sync transport** — bidi gRPC unreachable from browsers; no
   `/ws/v1/sync`. Blocks web PGlite clients from full sync-peer status (§4.1).
3. **[High] No client→Postgres write path** — CDC is one-way; the event-sourced write-back
   loop (spine→Postgres projection) must be built, most naturally in flint-forge.
4. **[Medium] Flutter transport blocked upstream** — `uniffi-bindgen-dart` 0.1.3 lacks the
   async ABI; Dart SDK is CRDT-only. Options: wait for upstream, hand-lower the UniFFI async
   runtime (rejected by the project as fragile), or add a parallel `flutter_rust_bridge`
   crate exposing `frf-sdk-rust` (frb cannot parse the UniFFI crate — ADR-003). For
   TJ-ARCH-MOB-001 Flutter mobile this is a real schedule risk.
5. **[Medium] Sovereign SFU unproven** — 12+ phases spent on the decode proof; gate still
   OFF; phase-36 pending. Plan media on LiveKit-hosted and treat str0m as stretch.
6. **[Medium] In-memory defaults** — `SyncService` (CrdtStore/OpStore) and `EntityService`
   (entity_store_mem.rs) boot on in-memory stores; `SurrealCrdtStore` exists but isn't
   wired by default; the entity read plane has **no persistent adapter at all**.
7. **[Medium] Per-event Keto RLS at fan-out is unproven at scale** — RFC §07 names the
   hazard; mitigations (subscribe-time scoping, check-cache) are designed but no load-test
   evidence appears in signoffs (phase-7 hardening items not publicly signed off).
8. **[Low-medium] Iggy fork risk** — spine depends on `GQAdonis/iggy@master` (pre-1.0
   upstream, personal fork). `LogBroker` port keeps NATS/Redpanda a compile-time swap.
9. **[Low] P2P sync + lora-rs are greenfield** — RFC-blessed but unimplemented; requires a
   new port + adapters (§4.5).
10. **[Low] Stale docs** — README "Current State" lags ~17 phases behind signoffs; trust
    `docs/PHASE-*-SIGNOFF.md` + `.kbd-orchestrator/current-waypoint.json`, not the README.

---

## 6. Sources

Local (all read 2026-07-18): `README.md`, `CLAUDE.md`, `docs/IMPLEMENTATION-PLAN.md`
(RFC-FRF-002), `docs/API-REFERENCE.md`, `docs/SECURITY.md` (esp. §6),
`docs/PHASE-{19,21,23,25,27,34,35}-SIGNOFF.md`, `CHANGELOG.md`,
`docs/decisions/adr-{001,003,005,008}-*.md`, `.kbd-orchestrator/current-waypoint.json`,
`Cargo.toml` + `Cargo.lock`, `proto/flint/v1/*.proto`, and crate sources under `crates/`
(frf-crdt, frf-wasm, frf-postgres-cdc, frf-gateway, frf-proto, frf-ports, frf-ffi,
uniffi-bindgen, frf-store-redb, frf-store-surreal, frf-media-str0m, frf-media-livekit,
frf-bridge-matrix, frf-bridge-atproto, frf-identity-ory, frf-authz-keto, frf-policy-cedar,
frf-broker-iggy, frf-sdk-rust, frf-agentproto, frf-librefang, frf-app) + `sdks/{dart,ts,entity-management}`.

Web (accessed 2026-07-18):
- Loro project activity: https://github.com/orgs/loro-dev/repositories (Jun 2026 updates)
- `@electric-sql/pglite-sync` releases: https://github.com/electric-sql/pglite/releases (0.6.3, 2026-06-16)
- pglite-sync usage: https://www.npmjs.com/package/@electric-sql/pglite-sync
- Browser client/bidi streaming limitation (Connect maintainers): https://github.com/connectrpc/connect-go/discussions/254
- Bidi streaming requires HTTP/2: https://github.com/connectrpc/connect-go/issues/342
- Cross-repo context: `docs/pglite-oxide-tauri-hybrid.md`,
  `docs/reference-app/knowme-agentic-deployment-plan.md` (hybrid-mobile-architecture-src)
