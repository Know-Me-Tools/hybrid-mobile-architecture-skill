# KnowMe Local-First + Realtime Master Plan

> **Document:** Master architecture, functional specification, project plan, and research bibliography
> **Author:** KNOWME_CHIEF_ARCHITECT (synthesis of the 2026-07-18 research swarm)
> **Date:** 2026-07-18
> **Status:** PROPOSAL — awaiting owner decisions on the Open Questions in §9
> **Sources:** the ten verified research briefs in `docs/research/` (2026-07-18):
> `knowme-builder-skill-inventory` · `prometheus-skill-pack-inventory` · `flint-realtime-fabric-deepdive` · `flint-forge-deepdive` · `entity-management-sync-deepdive` · `prior-art-supporting-projects` · `landscape-local-first-sync-engines` · `transports-webrtc-lora-cdc` · `wasm-extensibility-packaging` · `agentic-ui-agent-harness-patterns`
>
> **Tag convention:** every capability claim carries one of:
> **[EXISTS]** — implemented and verified in-repo · **[PARTIAL]** — implemented but stubbed, gated, or incomplete · **[PROPOSED]** — designed here, not yet built · **[ABSENT]** — confirmed missing · **[STALE]** — documentation that contradicts verified code state.

---

## Table of Contents

1. [Executive Summary & Recommendation](#1-executive-summary--recommendation)
2. [Theory & Design Principles](#2-theory--design-principles)
3. [Current-State Capability Inventory](#3-current-state-capability-inventory)
4. [Target Architecture](#4-target-architecture)
   - 4.1 [Data plane](#41-data-plane)
   - 4.2 [Sync plane](#42-sync-plane)
   - 4.3 [Realtime & edge transports](#43-realtime--edge-transports)
   - 4.4 [Agent plane](#44-agent-plane)
   - 4.5 [Extension plane (WASM)](#45-extension-plane-wasm)
   - 4.6 [Distribution plane (FCP packaging standard)](#46-distribution-plane-fcp-packaging-standard)
   - 4.7 [End-to-end flows](#47-end-to-end-flows)
5. [Functional Specification](#5-functional-specification)
6. [Changes Required in the KnowMe Builder Skill Package](#6-changes-required-in-the-knowme-builder-skill-package)
7. [Project Plan](#7-project-plan)
8. [Research Bibliography](#8-research-bibliography)
9. [Open Decisions](#9-open-decisions)

---

## 1. Executive Summary & Recommendation

**The question.** How do we build a world-class, cohesive strategy for local-first operation and realtime syncing — client-side executing agents *and* cloud-hosted agents, a WASM-based extensibility model, and decentralized component distribution — across the KnowMe Builder skill set and the Prometheus platform, with PGlite (web) and pglite-oxide (Tauri) syncing through flint-realtime-fabric (FRF) onto central Postgres (flint-forge)? And what must be added to `hybrid-mobile-architecture-src` so AI harnesses can scaffold, test, and deploy all of it to web, mobile, and desktop?

**The recommended end-state, in nine bullets:**

1. **One sync backbone, owned end-to-end.** Postgres 18 (flint-forge) is the central authority; a single WAL→CDC pipeline (`frf-postgres-cdc` on `pg_walstream`) feeds a bucket-based sync gateway evolved from `prometheus-entity-sync` (PES), deployed as an FRF edge module, speaking a unified WebSocket+MessagePack protocol — **PSyncV2** — that adds create semantics, a durable offline write queue, and poison-message handling to PSyncV1's proven snapshot/delta/ack/resume core. Electric-style HTTP shapes are *not* adopted; the owner's "write path is custom software we own" decision stands (brief: knowme-builder-skill-inventory §3.1, prior-art-supporting-projects §9).

2. **A two-channel sync protocol.** PSyncV2 multiplexes (a) **bucket channels** — relational entities/settings, server-authoritative with last-write-wins at Postgres and double-authorized writes — and (b) **document channels** — Loro 1.13 CRDT documents merged server-side, for genuinely multi-writer artifacts (notes, agent scratchpads, collaborative ContentBlock trees). This is the industry-validated split (brief: transports-webrtc-lora-cdc §E): central-authority sync where authority matters, true CRDT only where multi-writer is intrinsic.

3. **Three client attach points, one Rust protocol implementation.** Web (PGlite) attaches via a new `/ws/v1/sync` route on the gateway; Tauri (pglite-oxide) attaches natively through a completed `pes-sdk-rust` embedded in `gen_ui_core`; Flutter mobile attaches through a `flutter_rust_bridge` surface over that *same* `pes-sdk-rust`. The pure-Dart PSyncV1 client question is resolved in favor of the TJ-ARCH-MOB-001 invariant — **all networking lives in Rust; Dart never re-implements the protocol** (brief: entity-management-sync-deepdive §3.5).

4. **A four-tier data matrix, deliberately kept.** PGlite on web, pglite-oxide on Tauri desktop, SQLite+sqlite-vec on mobile, Postgres 18 in the cloud — each is the only viable embedded option per surface, and the repository trait (not the connection string) is the portability seam. SurrealDB graph-RAG remains an *optional, benchmark-gated* module with a named fallback (sqlite-vec + FTS5 + recursive CTEs), answering the "DB matrix overbuilt" assessment flag (§7 risk register, R-6).

5. **Cooperating agents on one vocabulary.** Client-side agents run in `gen_ui_core` (GGUF via llama-cpp-2 on desktop/mobile, WebLLM on web); cloud agents run in UAR behind a process boundary (AGPL) with liter-llm routing. A deterministic **two-stage router** (privacy gate → complexity → availability) with **fail-closed** privacy semantics decides where each turn executes; shared state is a CRDT-synced conversation document; AG-UI carries the event stream and **Google's A2UI wire format** is adopted as the *external* declarative-UI serialization, with `ContentBlock` remaining the canonical internal Rust type (brief: agentic-ui-agent-harness-patterns §1.9, §5).

6. **One WASM component model across server and clients.** flint-forge's frozen WIT world `flint:host@0.1.0` governs server-side components (Kiln, wasmtime 46); a sibling client world is hosted by a new `gen_ui_plugins` crate in `gen_ui_core` — wasmtime+Cranelift on desktop/Android, wasmtime+Pulley on iOS, jco/Extism in the browser. Three component kinds: **agent skills**, **UI modules** (A2UI catalog fragments and/or HTMX templates), and **settings schemas** (VS Code `contributes.configuration` pattern with sync scopes; secrets never sync — Flint Vault references only).

7. **One decentralized packaging standard: the Flint Component Package (FCP).** An OCI artifact is the canonical transport (wkg-compatible); content-addressed mirrors ride iroh-blobs (BLAKE3-verified, resumable) and Kubo IPFS HTTP; a signed, append-only **git release-log** (gitoxide-managed) provides warg-style transparency and offline verification; signing is cosign/Sigstore and `did:prometheus` Ed25519 — the exact trust chain flint-forge already implements (`fke-sign-cosign`, `fke-sign-did`). Manifests are self-certifying: `name@version → digest`, WIT world pin, settings schema, A2UI/HTMX/skill assets, privacy class (brief: wasm-extensibility-packaging §C.7).

8. **Security invariants are launch gates, not enhancements.** The FRF `SyncService` is **unauthenticated today** — fixing it (bearer extraction + identity verify + tenant-equality) is Phase 0, before any production sync topology. Per-event authorization re-check at fan-out (Keto `view` + RLS re-query), dual-JWT (flint-gate auth token → short-lived sync token), fail-closed everywhere, secrets structurally excluded from sync, and signed+capability-manifested extensions (the 2026 skill-ecosystem audit found prompt injection in 36% of public skills — brief: agentic-ui-agent-harness-patterns §2.1).

9. **The skill package grows a sync/extensibility/publishing toolchain.** `hybrid-mobile-architecture-src` gains: four new scaffolding scripts (`scaffold-sync.sh`, `scaffold-extension.sh`, `add-pglite.sh`, `package-component.sh`), seven new reference docs (`references/sync/*`, `references/wasm/extensions.md`, `references/packaging/fcp.md`, `references/settings/model.md`, `references/transports/edge.md`), template packs (pes-gateway wiring, WASM component skeleton, FCP manifest, settings schema, A2UI catalog fragment), six new project-local skills, and toolchain additions in `versions.toml`/`check-env.sh` (wasm32-wasip2, cargo-component, wkg, iroh, gix) — all enforced by `audit.sh doc-consistency` (§6).

**Primary recommendation statement.**

> Adopt the **PES-over-FRF bucket model** as the single sync plane (evolving PSyncV1 into PSyncV2 behind the existing `gen_ui_types::sync::SyncTransport` seam), the **`flint:host` WIT component model** as the single extension plane (server *and* client runtimes), the **Flint Component Package** as the single distribution plane (OCI canonical + iroh/IPFS mirrors + signed git release-log), and the **AG-UI + A2UI protocol vocabulary** as the single agent/UI plane (ContentBlock canonical internally, Google A2UI JSONL externally). Fund Phase 0 immediately — the FRF `SyncService` authentication gap and the missing `/ws/v1/sync` browser route are the two defects that gate everything else. Estimated total program: ~26–37 engineer-weeks of serial scope across 7 phases, compressible to roughly two quarters with the layered-workspace parallel-worktree strategy the owner's development philosophy already mandates (§7).

This plan reuses, rather than redesigns: the substrate CRDT/privacy traits in `prometheus-skill-pack`, the frozen trait seams in `gen_ui_types`, the PES gateway and sync-rules DSL, FRF's CDC/Loro/op-log machinery, flint-forge's Kiln/registry/signing stack, and PEM's cross-framework entity graph. What is genuinely new is bounded: PSyncV2's create+queue semantics, three client appliers, the client-side WASM host, the FCP toolchain, and the edge-transport adapters (§4, §7).

---

## 2. Theory & Design Principles

This section is the intellectual scaffolding. It is rigorous but deliberately compressed; each subsection links out to the primary material the briefs verified.

### 2.1 Local-first principles

The local-first ideal (Ink & Switch lineage) holds that software should keep the user's data primarily on their devices: reads and writes are local-latency, work continues offline, the network is an enhancement, and the user retains agency over their data. The 2025–2026 ecosystem has consolidated this into **five architectural archetypes** (brief: landscape-local-first-sync-engines §1):

1. **Postgres read-path sync** (Electric) — logical replication → HTTP shape streams; writes via your own API.
2. **Bidirectional central-authority sync with upload queues** (PowerSync) — buckets, checkpoints, client-side persistent write queues.
3. **Query-driven sync with server-side replica** (Zero/Rocicorp) — elegant but explicitly *not* local-first (no offline writes, TS-only).
4. **Event-sourced local DBs** (LiveStore) — git-style event logs materialized into SQLite.
5. **CRDT-native systems** (Automerge, Yjs, Loro, Jazz, Evolu, Ditto…) — multi-writer merge semantics; server optional.

Our design is a deliberate **hybrid of archetypes 2 and 5**, which the transports brief identifies as the industry-validated split (brief: transports-webrtc-lora-cdc §E): relational data (entities, settings, skills metadata) flows through a central-authority pipeline with offline write queues; collaborative artifacts (documents, agent state) flow as CRDTs. The KnowMe-specific principle, inherited from TJ-ARCH-MOB-001, is that **the write path is first-class custom software we own** — Electric's abandonment of write-path sync in its 2024 electric-next rebuild is the cautionary precedent that justified this (brief: prior-art-supporting-projects §2; knowme-builder-skill-inventory §2.3).

Local-first ethics also dictate the offline/revocation semantics adopted in §4.6: yanked package versions refuse *new* installs but cached copies remain runnable; local data is never hostage to a server's availability.

### 2.2 CRDT theory: op-based vs state-based, and the Loro choice

CRDTs come in two families: **state-based (CvRDT)** — replicas exchange full or delta *states* and merge via a join-semilattice operation — and **op-based (CmRDT)** — replicas exchange *operations* that commute by construction. Op-based CRDTs transmit small, idempotent ops (ideal for constrained transports) but require reliable causal delivery or buffering; state-based are tolerant of lossy channels but heavier on the wire. Modern text/document CRDTs (Automerge, Yjs/YATA, Loro/Eg-walker+Fugue) are effectively op-based with version-vector summarization: peers exchange version vectors, then only the missing ops.

The platform's CRDT engine is **Loro 1.13**, chosen by FRF's ADR-001 (accepted 2026-06-19) over automerge-rs on measured grounds: 2–9× faster encode/decode, 3.7× smaller documents, 2.7× less memory, Fugue anti-interleaving for text, first-party `loro-ffi`, and production `loro-swift` (brief: flint-realtime-fabric-deepdive §2.4). External corroboration: Loro 1.0 shipped a stable data format (2026-06-15 announcement; crate 1.13.7 as of 2026-07-15), with vendor benchmarks showing 260K-edit documents applying in ~290 ms and loading in ~1 ms (brief: entity-management-sync-deepdive §1.6, landscape-local-first-sync-engines §3.7). Yjs/Yrs remains relevant at the browser edge (y-webrtc provider ecosystem), but the Loro↔Yjs wire protocols are incompatible and no interop layer exists — **we standardize on Loro inside the platform and treat Yjs providers as legacy peer-sync only** (brief: transports-webrtc-lora-cdc §A).

Two CRDT discipline rules follow:

- **Deltas are opaque bytes at every boundary.** FRF's design — `SyncOp.payload` as `bytes`, engine encoding never in the wire or FFI contract — is preserved in PSyncV2. This lets the engine evolve without protocol churn (brief: flint-realtime-fabric-deepdive §2.4).
- **Relational authority beats CRDT for entities.** For bucket-synced relational rows, WAL order is the total order and last-write-wins at Postgres is the conflict model; CRDT merges apply only to `CrdtPatch` document columns. Mixing the two semantics in one row is how systems silently lose data (brief: entity-management-sync-deepdive §2.3).

### 2.3 Partial replication: shapes, buckets, scopes

No client holds the whole database. The three points on the partial-replication spectrum, per the landscape brief (§4.2): Electric's **shapes** (declarative table+where+columns; simplest; proxy-injected authZ), PowerSync's **buckets** (parameterized sync rules mapping JWT claims → bucket membership; best offline/write story; checkpointed), and Zero's **synced queries + permissions** (most expressive; needs server-side incremental view maintenance).

We adopt **buckets** as the partial-replication primitive, with shape-like declarative ergonomics: PES's TOML sync-rules DSL (`[buckets.x]` with `parameter_queries` — parameterized SQL, `$1` = JWT `sub` — and `data` queries referencing `{bucket_parameters.X}`) is a direct, security-reviewed descendant of PowerSync's model, with template substitution restricted to an allowlisted value grammar (`^[a-zA-Z0-9_-]{1,128}$`) and four load-time validation rules (brief: entity-management-sync-deepdive §2.3). The security boundary principle, from the PGlite field guide: *"the only way a client cannot see cross-tenant data is if the shape factory refuses to attach a shape that lacks a tenant predicate"* — enforcement lives at bucket/shape **assignment time**, because RLS is not evaluated during WAL replication (brief: prior-art-supporting-projects §1, §2). PowerSync's vendored monorepo documents the storage invariants (checksums, compaction, checkpoint semantics) we must honor when hardening `pes-oplog` (brief: prior-art-supporting-projects §4).

**Scopes** generalize buckets for settings and extension data: every synced value carries a scope (`application`/`user`/`machine`/`workspace` analogs) that determines its bucket membership and merge semantics (§4.5.3).

### 2.4 Capability-based security for WASM

The WebAssembly Component Model gives a structural capability discipline: a component can only use interfaces it *imports*; the host links only what it chooses to grant. Deny-by-default linking, typed WIT boundaries, and host-supplied imports only (brief: wasm-extensibility-packaging §A.4). On top of the structural layer we stack three enforcement layers, all already implemented in flint-forge's Kiln:

1. **Declared capabilities** in the signed manifest (`Capability::{Db, Llm, Kv, Identity, Secrets, HttpOutgoing}` in `fke-domain`), bound to the publisher's DID.
2. **Cedar policy intersection at instantiation** — granted = declared ∩ Cedar(publisher), with per-capability actions (`kiln:capability:<name>`) and per-secret reveal gates (`kiln:secret:reveal`), audited to `vault.access_log` (brief: flint-forge-deepdive §1.4, §1.10).
3. **Resource limits** — fuel metering (`consume_fuel`, default 10M instructions/invocation), epoch interruption (deadline preemption), `StoreLimits` (linear memory/table caps), fresh `Store`+`WasiCtx` per invocation (no cross-request linear-memory leakage), and the pooling allocator for dense multi-tenant hosting. Under the Pulley interpreter (iOS), fuel/epoch limits are *more* critical because interpreter loops are tighter (brief: wasm-extensibility-packaging §A.3–A.4).

Secrets never enter WASM linear memory for high-value credentials: the host brokers them at the boundary (`flint:secrets.get` returns an opaque resource handle; `reveal()` is Cedar-gated and audited). This same brokered model is the BYOK answer for WASM skills (brief: flint-forge-deepdive §1.5, §3.2).

### 2.5 Content addressing and CIDs

All three distribution universes we care about are content-addressed: OCI digests (sha256), IPFS CIDs (multihash over dag-pb/dag-cbor), and iroh BLAKE3 hashes (with bao-tree verified streaming). The design rule from the packaging brief: **the digest is the join key across transports** — the FCP manifest records all representations (`digests: { wasm: sha256:…, ipfs: bafy…, iroh: blake3:… }`), so a package has one identity regardless of which transport served it (brief: wasm-extensibility-packaging §C.5).

Content addressing yields *integrity* (fetch validates against the digest) but not *availability* or *naming*. Hence: names resolve through signed release-logs (§4.6), and availability comes from pinned mirrors and multiple transports — never from raw public-DHT discovery, which remains Sybil-attackable (arXiv:2505.01139, active content-eclipse attack with ~80% lookup denial; brief: wasm-extensibility-packaging §C.1).

### 2.6 Convergence invariants

The architecture's correctness rests on a small set of invariants, each named here and referenced throughout:

- **INV-1 (Single authority per datum).** Every datum has exactly one authority: Postgres rows for relational entities; the Loro document for CRDT artifacts; the client for unsent drafts and `machine`-scoped settings; Flint Vault for secrets. No datum has two authorities. (Precedent: UAR's "server entity versions win conflicts; unsent drafts remain client-owned" — brief: prior-art-supporting-projects §6.)
- **INV-2 (WAL is the total order).** For bucket-synced relational data, Postgres commit order (LSN) is the only ordering; clients advance checkpoints only when complete (PowerSync's causal+ checkpoint model).
- **INV-3 (Fail-closed).** Any authorization, signature, or availability failure results in denial/stubbed-empty behavior, never fallback to a less-checked path. Explicit and audible, never silent (precedents: Forge's `FabricChangeSource`, PES's create rejection, UAR's Cedar "deny is final").
- **INV-4 (Secrets never sync).** Secret values never enter CRDT documents, buckets, PEM, PGlite, Zustand, logs, URLs, ordinary Postgres columns, Compose files, ConfigMaps, or images. Only Vault *references* sync (brief: knowme-builder-skill-inventory §2.3).
- **INV-5 (Boot order).** Migrations → seed/lookup bundles → sync attach. Sync shapes attach only after the schema they expect exists; a failed boot phase halts visibly (PoC §3.4 invariant; brief: knowme-builder-skill-inventory §3.1).
- **INV-6 (Additive-only schema evolution).** Synced schemas evolve additively (rename to `_deprecated_*`, never drop synced columns); divergence beyond the compatibility window triggers reset-and-resync, never silent drift (the Smashing Magazine dropped-column incident is the counterexample — brief: prior-art-supporting-projects §2).
- **INV-7 (One engine per concern).** One CRDT (Loro), one CDC pipeline (`frf-postgres-cdc`), one sync gateway, one WIT world family, one packaging standard. Competing paths (Electric *and* FRF CDC; flint.ts *and* PES in PEM) converge or one is explicitly deprecated (§9, OD-2/OD-3).

---

## 3. Current-State Capability Inventory

Honest accounting of what exists today, with crate/package names and versions. Each table distinguishes **[EXISTS]** (verified implemented), **[PARTIAL]** (stubbed, gated, or incomplete), and **[ABSENT]** (confirmed missing). Stale documentation is flagged **[STALE]** where briefs caught docs contradicting code.

### 3.1 `hybrid-mobile-architecture-src` — the KnowMe Builder skill package (TJ-ARCH-MOB-001)

The repo is a **skill package, not an application**: scaffolding scripts, reference docs, and templates that generate real projects (brief: knowme-builder-skill-inventory §1.1).

| Capability | Status | Evidence |
|---|---|---|
| 13-crate layered Rust workspace scaffolding (L0 `gen_ui_types` traits → L2 impls → FFI/Tauri/wasm leaves) | [EXISTS] | `scripts/scaffold-rust-core.sh`; PoC instance `apps/knowme-poc/` runs 16 workspace members |
| Frozen sync seams: `SyncTransport` (`start()`, `enqueue_write()`, status) and `EntityTransport` traits in `gen_ui_types` | [EXISTS] | `scaffold-rust-core.sh` emits `sync.rs`/`transport.rs`; doc-comment explicitly reserves the seam for "a future prometheus-entity-sync (PES) client" |
| `gen_ui_db::sync` DIY Electric-consumer + write queue (C-005); `gen_ui_db::relational` multi-backend (C-003: sqlx pg / pglite-oxide / SQLite+sqlite-vec, per-dialect migrations, bundled/HTTP/IPFS seeds) | [EXISTS] | `scaffold-rust-core.sh` (gen_ui_db emission, SyncEngine impl) |
| FRF integration behind feature flags (`frf`, `peer-crdt`), SHA-pinned git deps (`frf-sdk-rust`, `frf-crdt`, `frf-store-redb` @ `9ba04ae6…`) | [PARTIAL] | deps **commented out** by default; `frf.rs` façade verified clippy-clean against real FRF checkout (C-006) |
| pglite-oxide data-layer doctrine (corrected 2026-07-15: WASI PGlite in Rust, desktop-only, no iOS/Android) | [EXISTS] | `docs/pglite-oxide-tauri-hybrid.md`; `versions.toml` pins `pglite_oxide = "0.5.1"` |
| SurrealDB 3.2 graph-RAG (HNSW→RELATE→BM25→RRF; intent-level FFI only) | [EXISTS] (design + scaffold) | `references/rust/patterns.md`, `references/rust/wasm-targets.md` (C-002 spike) |
| ContentBlock protocol (11 frozen variants) + 7-step `new-block-type.md` process | [EXISTS] | `references/rust/new-block-type.md`; exhaustive React/Flutter switches |
| KnowMe reference-app plan (host-neutral `gen_ui_host`, Axum `gen_ui_server_axum`, delivery profiles) | [PARTIAL] | Phase C implemented + live-validated; **Phase D (realtime, durable BYOK, identity) open — not launch-verified** (2026-07-17) |
| PES-backed sync engine behind `SyncTransport` | [ABSENT] | PES waves 1–5 built in PES repo, but no `gen_ui_db::sync` PES backend exists here |
| WASM plugin host / WIT world / signing / distribution in scaffolds | [ABSENT] | spec'd in KnowMe IPFS spec (~3× over-scoped per assessment §3.6); nothing implemented |
| Synced settings model | [ABSENT] | config DB (`providers`, `model_prefs`, `app_settings`) is local-only; no merge semantics |
| IPFS client / git-versioning crates in scaffolds | [ABSENT] | seeds reference IPFS; no plugin distribution code |

Stale-doc flags: internal "A2UI" ≠ Google's A2UI standard (`docs/corrections-2026-07-16.md`, open adopt-vs-rename decision); earlier pglite-oxide native/mobile claims corrected 2026-07-15; PEM's internal research claiming pglite-oxide "not on crates.io" is superseded — it is on crates.io at 0.5.1 (2026-06-04) with `Pglite`/`PgliteServer` API and a Tauri guide (brief: entity-management-sync-deepdive §1.6).

### 3.2 `prometheus-skill-pack` — skills + Rust substrate

| Capability | Status | Evidence |
|---|---|---|
| `storage-provider` crate: `StorageProvider` + `CrdtEngine` traits; `LocalDirAdapter`, `LoroAdapter` (Loro 1.13), `IrohDocsAdapter` (iroh-docs 0.101, ticket flow, tested 2-node sync) | [EXISTS] | `substrate/storage-provider/` (`loro = "1.13"`, `iroh = "1.0"`, `iroh-blobs = "0.103"`) |
| `SyncManifest` privacy gate (`PrivacyClass::{Public, Trusted, Local}`; `Local` structurally excluded from sync) | [EXISTS] | `substrate/storage-provider/src/sync_manifest.rs` |
| `sovereign-sync` daemon: iroh QUIC gossip (`blake3(operator_id ‖ "sovereign-sync-v1")` topic), per-domain Loro docs, redb state | [PARTIAL] | p2p/crdt/store real; **MCP sync tools + REST sync endpoints are hardcoded stubs** ("wired in change-sync-010/014/015") |
| `sovereign-client` Rust SDK (typed REST + AG-UI SSE stream) | [EXISTS] | `substrate/sovereign-client/` |
| `prometheus-research`: A2UI `ComponentRegistry` (8 server-side HTMX components over SSE), AG-UI emit, vendored htmx/alpine | [EXISTS] (prototype) | `substrate/prometheus-research/src/a2ui/registry.rs` |
| `surface-bridge` Tier-2 MCP App shell | [PARTIAL] | acknowledges intents; iframe/AG-UI renderer "deferred to a future phase" |
| `learner-model` CRDT domain store (proof-of-pattern for domain-state-as-CRDT) | [EXISTS] | `substrate/learner-model/` |
| FRF SDK skills for 6 languages (`@prometheusags/frf-sdk` TS via Connect-RPC; `frf_dart` via flutter_rust_bridge 2.11.1) | [EXISTS] | `skills/flint/flint-sdk-{ts,dart,…}` |
| PEM local-first skill (Electric shapes → PGlite → entity graph) | [EXISTS] | `skills/react/…/entity-realtime-local-first/SKILL.md` (pins `@electric-sql/pglite ^0.2` — reverify) |
| `librefang-wasm-skill`: raw non-WIT WASM Guest ABI | [EXISTS] (legacy) | collides with flint-forge WIT; **treat as legacy** (§9, OD-5) |
| Skill distribution: git submodules + flat-file copy installers | [EXISTS] but [STALE]-model | no content addressing, no signing, no decentralized store |
| WebRTC transport for substrate sync | [ABSENT] | iroh is QUIC-native; browsers can't join iroh gossip |
| Privacy-class naming | [PARTIAL] [STALE] | code `Local` vs skills/docs `LocalOnly` vs REST stub `local_only`/`sync_encrypted_only` — reconcile before building |

### 3.3 `flint-realtime-fabric` (FRF) — the realtime fabric

24-crate hexagonal Rust monorepo, MSRV 1.85, frozen `proto-v1` contract; signoffs through PHASE-35 (2026-07-09) (brief: flint-realtime-fabric-deepdive §1).

| Capability | Status | Evidence |
|---|---|---|
| Six gRPC services live on gateway: Spine, Signal, Sync, Agent, Entity (p17), Authz (p17) | [EXISTS] | `docs/API-REFERENCE.md` |
| Iggy spine (`LogBroker` over owner's `GQAdonis/iggy@master` fork) with durable offsets/resume | [EXISTS] | `frf-broker-iggy` |
| Postgres CDC: logical slot + pgoutput v2 via `pg_walstream 0.6` → `EntityChange` → spine channel | [EXISTS] | `frf-postgres-cdc`; single-tenant/single-channel config |
| Loro 1.13.1 CRDT (`frf-crdt`), redb op-log (`frf-store-redb` 4.1.0), SurrealDB store (`frf-store-surreal` 3.1.5) | [EXISTS] | ADR-001; `SurrealCrdtStore` **not wired by default** (in-memory defaults) |
| `SyncService.Sync` bidi gRPC CRDT sync + `GetCheckpoint` | [PARTIAL] — **UNAUTHENTICATED** | `sync_grpc_service.rs` has **no token extraction, no identity verify, no tenant check** (grep-verified 2026-07-18; re-verified for this document). Any caller reaching the gRPC port can push CRDT ops for any entity/tenant |
| Keto per-event authz at fan-out (`view` check per event, dashmap cache) + Cedar policy + JWT (JWKS, mandatory `JWT_ISSUER` in prod) | [EXISTS] (scale unproven) | `frf-authz-keto`, `frf-policy-cedar`; RFC §07 hazard note, no load-test evidence |
| WS routes: `/ws/v1/subscribe`, `/ws/v1/agents`, `/ws/v1/signal` | [EXISTS] | `frf-gateway/src/lib.rs` `build_router` — **`/ws/v1/sync` [ABSENT]**: browser clients cannot reach bidi CRDT sync (Connect-web/gRPC-web can't do client/bidi streaming) |
| `frf-wasm` browser SDK: WS subscribe/publish/agent + in-browser Loro merge | [EXISTS] | `sdks/ts/frf-wasm/` — not a WIT/component runtime |
| UniFFI SDKs: Swift/Kotlin generated; Dart CRDT-only | [PARTIAL] | `uniffi-bindgen-dart 0.1.3` lacks async ABI → `FrfFfiClient.connect` throws at runtime; Dart SDK ships honest stubs (`FrfTransportUnavailable`) |
| `frf-sdk-rust` full native client (all six services, resilient subscribe) | [EXISTS] | the natural embed for `gen_ui_core`/Tauri |
| Spine→Postgres write-back adapter | [ABSENT] | CDC is one-way pg→spine; the event-sourced write-back loop must be built (natural home: flint-forge or the sync gateway) |
| str0m sovereign SFU | [PARTIAL] — **gated OFF** | phases 19–35 consumed by decode proof; `framesDecoded=0`; `SFU_MODE=sovereign` OFF; **LiveKit hosted is the working media path** |
| P2P CRDT over WebRTC data channels; lora-rs | [ABSENT] | RFC-blessed, unimplemented; no `DataChannel` anywhere in `crates/` |
| `WatchEntityType` RPC (needed by Forge's `FabricChangeSource`) | [ABSENT] | tracked as **OQ-FRF-1**; Forge fabric change source fails closed (brief: flint-forge-deepdive §4.1) |
| README "Current State" (says "Phase 18 complete") | [STALE] | trust `docs/PHASE-*-SIGNOFF.md` + `.kbd-orchestrator/current-waypoint.json` (phase-36 execute_ready), not the README |

### 3.4 `flint-forge` — central Postgres 18 backbone + WASM registry

v1.0.0 released (p15); MSRV 1.96; wasmtime 46; PG18/pgrx 0.18.1 (brief: flint-forge-deepdive §1.1).

| Capability | Status | Evidence |
|---|---|---|
| Quarry (`fdb-*`): PostgREST-compatible REST + GraphQL over Postgres 18 with RLS injection (`SET LOCAL ROLE`/`request.jwt.claims`); pure PostgREST→SQL translator (`fdb-query`); hot-swap reflection (`fdb-reflection` StateManager/ArcSwap) | [EXISTS] | `fdb-gateway` routes incl. `a2ui/`, `agui/`, `mcp/`, `a2a/`, `htmx/` |
| Realtime change sources: LISTEN/NOTIFY (default, working); `FabricChangeSource` (FRF) | [PARTIAL] | fabric source **fails closed** on missing `WatchEntityType` (OQ-FRF-1); per-event RLS re-query designed-in and "NEVER removed or skipped" |
| Anvil pgrx extensions: `flint_auth` (GUC vocabulary), `flint_hooks` (webhooks, durable outbox), `flint_llm` "Ember" (in-DB LLM via gate/UAR, BGW queue), `flint_vault` (XChaCha20-Poly1305, KMS-wrapped DEK envelope encryption, access_log), `flint_meta` (reflection cache, in-DB Keto tuples) | [EXISTS] | `crates/ext-flint-*`; PG18/pgrx 0.18.1 |
| Kiln (`fke-*`): WIT `flint:host@0.1.0` frozen world (`db`/`llm`/`kv`/`identity`/`secrets` + `wasi:http` proxy); wasmtime 46 `EdgeRuntime` (fuel 10M, epoch 10ms, ProxyPre cache, per-request Store); Cedar capability intersection; AOT compiler behind `compiler` feature | [EXISTS] | `wit/flint/host/world.wit`, `fke-runtime`; AOT data-plane **not wired** — JIT `Component::from_binary` at load |
| Component stores: OCI (`oci_client`, primary), IPFS (Kubo HTTP), S3 (`object_store` 0.14), fs — all content-addressed behind `ComponentStore` port | [EXISTS] | `fke-store-{oci,ipfs,s3,fs}`; IPFS adapter minimal (no IPNS/pubsub/pinning; `exists()` conflates unreachable with absent) |
| Signing: `did:prometheus` Ed25519 (inline key or HTTP resolver) + cosign/Sigstore (Fulcio chain + SCT verification, Rekor) | [EXISTS] | `fke-sign-{did,cosign}`; DID method informal (no rotation/revocation spec) |
| Registry: Postgres `flint_kiln.functions` (name,version→manifest) + artifacts + invocations audit | [EXISTS] | name→digest resolution centralized in Postgres — manifests are self-certifying, DB row is a discovery cache |
| `flint-skill` guest SDK (traits mirroring the five WIT interfaces; compiles on `wasm32-wasip2`) | [EXISTS] | crates.io publication planned v1.1.0 |
| A2UI registry: `flint_a2ui` schema (components, overrides, applications, design systems, embeddings HNSW 1536-dim, schemas, bindings auto-gen, assembly_rules, events; REST/A2A/MCP surfaces; hot-reload via NOTIFY) | [EXISTS] (registry) | RFC-FORGE-A2UI-001; **Milestone 8 CRDT federation + CDN distribution NOT built** |
| pglite/pglite-oxide client sync contract (snapshots, deltas, offline writes) | [ABSENT] | "no client-side sync contract at all" (brief §4.7) |
| CLAUDE.md status prose ("Scaffold, todo!() bodies, pgrx 0.12/PG17") | [STALE] | trust README/ROADMAP/code: v1.0.0 released, PG18/pgrx 0.18.1 |

### 3.5 `prometheus-entity-management` (PEM 3.x) — client entity graph

Monorepo `3.0.0-alpha.0`, MIT; 15 packages (brief: entity-management-sync-deepdive §1.1).

| Capability | Status | Evidence |
|---|---|---|
| `entity-graph-core`: framework-agnostic Zustand normalized graph, `startLocalFirstGraph` (hydration, persistence, pending-action replay w/ `ReplayRetryPolicy` + poison handler), `registerEntityFromSql`/`registerEntityJsonSchema`, FilterSpec/SortSpec compilers | [EXISTS] | `@prometheus-ags/entity-graph-core` |
| Framework bindings: React (keeps v1 package name), Svelte, Solid, Alpine, HTMX (SSE fragment server), Web Components, `a2ui-react` (alpha) | [EXISTS] | packages all at `3.0.0-alpha.0` |
| Adapters: Electric, tenant-scoped Electric (refuses shapes without `tenantColumn`), Surreal live, PGlite persistence (`_graph_snapshot`), Tauri-SQL persistence, **Flint FRF bridge (`flint.ts` via `RealtimeAdapter.watchEntities()`)** | [EXISTS] | two PEM↔FRF integration points exist (see OD-3) |
| `entity-graph-sync`: pluggable peer sync (Yjs via y-websocket/y-webrtc, Loro via `loro-crdt`) | [EXISTS] | peer deps optional |
| `entity-graph-tauri` plugin (tauri-specta bindings) | [PARTIAL] | persists graph snapshots via **SQLite (`@tauri-apps/plugin-sql`), NOT pglite-oxide** |
| `entity_graph_flutter` (Dart graph + Riverpod providers + transport registry + SDL parser) | [PARTIAL] | in-memory only — **no sync transport, no persistence, no offline queue**; deps pin `flutter_riverpod ^2.6.1` despite "Riverpod 3" description; unpublished |
| `entity-graph-sdl` (JSON/TOML schema IR consumed by Rust CLI, TS generators, Dart parser) | [EXISTS] | the cross-language contract |
| `entity-graph-mcp` (Rust MCP server), `entity-graph-a2a` (A2A server), `entity-graph-cli` (Rust codegen) | [EXISTS] | machine access to the graph |
| npm publish evidence | [ABSENT] | pre-release; monorepo-resolution blocker (`workspace:*` not resolvable outside monorepo) |

### 3.6 `prometheus-entity-sync` (PES) — the MIT sync engine

Rust workspace `0.1.0`, MIT, built independently of PowerSync (FSL-1.1-ALv2) on FRF machinery (brief: entity-management-sync-deepdive §1.2).

| Capability | Status | Evidence |
|---|---|---|
| `pes-core` types (LSN, rules, `Op::{Upsert, Delete, CrdtPatch}`, checksums), proptest roundtrips | [EXISTS] | 312-line types.rs |
| `pes-rules` TOML DSL + `BucketAssigner` (JWT claims → parameterized SQL → buckets; TTL cache + sweeper; `find_affected_buckets`) | [EXISTS] | security-reviewed; marked CRITICAL in wave notes; value allowlist `^[a-zA-Z0-9_-]{1,128}$` |
| `pes-snapshot` (keyset-paginated), `pes-oplog` (per-bucket append-only log on `frf-store-redb`, range scans, checksums), `pes-router` (WAL→buckets) | [EXISTS] | off-by-one redelivery bug found live and fixed |
| `pes-protocol` PSyncV1 codec: snapshot/delta/ack/checkpoint/keepalive, MessagePack (`rmp-serde`), `PROTOCOL_VERSION = 1` | [EXISTS] | `ClientMessage::{Subscribe, Ack, Write, Ping}` |
| `pes-gateway` WS server: JWT auth (350-line auth.rs), subscribe handshake, **double write authorization** (bucket-membership + row ownership), 50ms oplog poll | [EXISTS] | server-side Loro merge for `CrdtPatch` via `frf_crdt::apply_delta` |
| `pes-server` deployable binary (config, wiring, replication slot `pes_server_slot`, `/health` `/ready` `/metrics`, 30s drain, Dockerfile) | [EXISTS] | runnable `examples/docker-compose/` demo |
| Create semantics in protocol | [ABSENT] | inserting a new id fails the ownership check (fail-closed, deliberate) — new entities must be created via app API first |
| Client offline write queue | [ABSENT] | TS `SyncClient` **throws on writes while disconnected**; PEM's replay queue is not wired to the PES transport |
| `pes-sdk-rust` | [ABSENT] — **1-line stub** | `//! Native Rust client SDK…` only |
| `@prometheus-ags/entity-sync-tauri` | [ABSENT] — **empty stub** | `export {};` — design exists only as `v4-tauri-plugin` proposal (pglite-oxide + Rust PSyncV1 client + rusqlite fallback `[patch]`) |
| Dart client (`v4-dart-sdk` proposal: pure-Dart drift + web_socket_channel) | [ABSENT] | zero Dart files in repo; **README overstates reality** (advertises Dart/Rust/Tauri SDKs) [STALE] |
| `@prometheus-ags/entity-sync-pglite` (PGlite extension `prometheusSync` + `applyOps` + `prometheusSyncTransport` PEM bridge) | [EXISTS] | two-user PGlite integration tests; `CrdtPatch` stored as opaque bytes client-side (no browser CRDT runtime here) |
| Gateway delta delivery | [PARTIAL] | 50ms polling, no push/broadcast channel in pes-oplog (noted deferred) |

### 3.7 `universal-agent-runtime` (UAR) — cloud agent runtime

v1.0.0, **AGPL-3.0-only** (SDKs MIT), single Rust/Axum process (brief: prior-art-supporting-projects §6).

| Capability | Status | Evidence |
|---|---|---|
| liter-llm routing (142+ providers, 269-provider catalog), OpenAI-compatible `/v1`, Cedar governance (deny final), MCP tool bridge | [EXISTS] | `POST /api/uar/route` capability routing |
| Three skill kinds: Manifest (`SKILL.md`), **WASM Component Model (`uar:skill@0.1.0` world: `run: func(input: string) -> result<string, string>`)**, Native (in-process Rust trait) | [PARTIAL] | WASM dispatch currently an **untyped stub**; wit-bindgen end-to-end invocation pending; browser-side arbitrary WASM explicitly unsupported |
| AG-UI event transport + A2UI validated catalogs (`urn:uar:a2ui:catalog:1`, fail-closed unknown components, 3 renderers, cross-renderer conformance fixtures) | [EXISTS] | A2UI surface replay for late joiners |
| UAR-AGENT-MD agent artifact spec (15 required sections → signed JSON descriptors) | [EXISTS] | `docs/agents/AGENTS_SPEC_RFC.md` |
| SurrealDB authoritative + PGlite client cache + versioned events (server wins; drafts client-owned); Postgres remote persistence provider | [EXISTS] | `config.remote.postgres.yaml` — the flint-forge integration seam |
| Tauri localhost-server pattern (Axum on ephemeral port; SSE/EventSource compatibility) | [EXISTS] (Preview) | contested vs TJ-ARCH-MOB-001 in-process `invoke()` default — per-surface decision (§9, OD-8) |

### 3.8 Supporting prior art (owner's fleet)

| Project | Status | Lesson for this plan |
|---|---|---|
| `PGLITE-LOCAL-FIRST-ARCHITECTURE.md` (952 lines, 2026-07-13) + `pglite.agent.final.md` (~3000 lines) | [EXISTS] (doctrine) | 7-decision framework; augmented `_local_*` table pattern + sync-trigger; tenant-predicate enforcement; additive migrations; four-phase boot; offline write-queue state machine (`PENDING → IN_FLIGHT → SYNCED / RETRYABLE_ERROR / FATAL_ERROR → DEAD_LETTER`); dual-JWT (auth token → 15–60min shape token); CVE-2026-40906 (Electric `ORDER BY` SQLi, CVSS 9.9) as the injection-surface lesson; LobeChat reversal as the PGlite-everywhere cautionary tale |
| `electric-tauri-postgres/` (pg_embed prototype) | [STALE] (Tauri 1.4-era) | full embedded Postgres binaries are the wrong embedding depth — the "before" picture justifying pglite-oxide |
| `powersync-service/` (vendored monorepo) | [EXISTS] (read-only reference, **FSL-1.1-ALv2**) | bucket model + sync-protocol spec + test-client = conformance-test template; **read for design, never copy code** |
| `juit-pgproxy/` | [EXISTS] (reference) | pooled Postgres-over-WS thin-client escape hatch; 48-byte HMAC one-time WS tokens (replay-proof) — the WS-upgrade auth pattern for gateways |
| `FLINT_ANON_SERVICE_ROLE_KEYS_SPEC.md` (v1.0 draft) | [EXISTS] (spec) | `anon`/`authenticated`/`service_role` + new 4th **`agent` role**; `flint_pk_`/`flint_sk_` key hygiene; signing authority stays in flint-gate; Ed25519 default |
| `flint-architecture-module-ownership-report.md` | [EXISTS] | gate=identity, forge=data-access, FRF=event-plane authz, platform-agent=Cedar NHI lifecycle, UAR=agentic streaming (not auth infra) |

### 3.9 External ecosystem state (verified 2026-07-18)

| Component | State | Relevance |
|---|---|---|
| PGlite | `0.4.4` (2026-04-09), Apache-2.0, ~3.5MB gz; `@electric-sql/pglite-sync` **alpha**, read-path only | web embedded Postgres — validated |
| pglite-oxide | crates.io `0.5.1` (2026-06-04), PG 17.5 WASI via Wasmtime 44, MIT+Apache-2.0+PostgreSQL, Tauri guide, ~1.1–1.6× native latency | desktop embedded Postgres — validated |
| Loro | 1.0 GA (2026-06-15), crate `1.13.7`, MIT, stable format | platform CRDT — validated |
| Electric | 1.0 GA (2025-03-17), Apache-2.0; read-path only; "agent platform" pivot | reference architecture only — **not adopted** |
| PowerSync | service v1.23.2 (2026-07-02), **FSL-1.1-ALv2**; client SDKs Apache/MIT; SOC2+HIPAA | bucket-model reference — pattern reuse only |
| supabase/etl | Apache-2.0, Rust CDC on logical replication (Pipelines launch 2025-12-02) | reference for `frf-postgres-cdc` hardening |
| WASI / Component Model | 0.2 stable (2024-01); **0.3 ratified 2026-06-11**; Component Model 1.0 roadmap published 2026-06-08 | target 0.2 worlds for production; track 0.3 behind feature flag |
| Wasmtime | 45 (2026-05-21, initial async) / 46 in flint-forge; Pulley default on non-Cranelift targets since v29 (2025-01-20) | server/desktop runtime + iOS interpreter path |
| warg registry | **archived 2025-07-28**; ecosystem converged on OCI artifacts via `wkg` | FCP canonical transport = OCI (§4.6) |
| IPFS | Kubo alive (0.33–0.39 in 2025; Provide Sweep default 0.39; AutoTLS); **rust-ipfs dead** (archived 2022-10-23); DHT Sybil caveat (arXiv:2505.01139) | Kubo HTTP API server-side + delegated routing |
| iroh | `1.0.0-rc` (2026); iroh-blobs BLAKE3/bao-tree verified streaming (0.9x/0.10x self-declares non-production; pin 0.35 for prod); iroh-docs 0.95 set-reconciliation sync | P2P/edge substrate + FCP mirrors |
| gitoxide | `gix 0.55.0` (2026-05); clone/fetch/push/merge implemented; no LFS | FCP git release-log substrate |
| AG-UI | open protocol (CopilotKit, 2025-05-12); ~16 event types; community Dart+Rust SDKs | agent↔UI event wire |
| Google A2UI | open-sourced Jan 2026; **v0.9 (2026-04-17)**; official React renderer + production Flutter/Angular/Lit renderers; GenUI SDK for Flutter (`genui` ^0.8.x) | external declarative-UI wire format |
| Agent Skills | open standard at agentskills.io (2025-12-18); ~40 compatible products; skills.sh marketplace (34k+ skills, Jan 2026); **36% of public skills prompt-injected (2026 audit)** | SKILL.md packaging + supply-chain security posture |

---

## 4. Target Architecture

### 4.0 System overview

Five planes, each with exactly one owner inside the fleet (INV-7). Nothing here introduces a second implementation of a concern that already has one.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CLIENT SURFACES                                  │
│  Web (React 19)        Tauri Desktop (React 19)      Flutter Mobile         │
│  PGlite 0.4.4          pglite-oxide 0.5.1            SQLite + sqlite-vec    │
│  (IndexedDB/OPFS)      (PgliteServer→sqlx)           (sqlx-sqlite in Rust)  │
│       │                      │                            │                 │
│  PEM entity graph      PEM / Zustand 5               entity_graph_flutter   │
│  (Zustand)             + Tauri commands              (Riverpod mirror)      │
└───────┼──────────────────────┼────────────────────────────┼─────────────────┘
        │  gen_ui_core (shared Rust crate — THE invariant: all networking,     │
        │  LLM, agent logic, persistence, sync, WASM hosting live HERE)        │
        │  ┌───────────────────────────────────────────────────────────────┐ │
        │  │ gen_ui_db (repository traits) · gen_ui_sync [NEW] (PSyncV2    │ │
        │  │ client over pes-sdk-rust) · gen_ui_agent (PMPO + router) ·    │ │
        │  │ gen_ui_plugins [NEW] (WASM host) · gen_ui_settings [NEW] ·    │ │
        │  │ gen_ui_protocol (ContentBlock ↔ A2UI/AG-UI serde)             │ │
        │  └───────────────────────────────────────────────────────────────┘ │
        │  TS: entity-sync-core (PSyncV2) over /ws/v1/sync   (web only)      │
┌───────┼──────────────────────────────────────────────────────────────────┐
│       ▼                 SYNC PLANE  (PSyncV2)                              │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │ sync gateway (pes-server evolved → FRF edge module)                │   │
│  │  /ws/v1/sync  — bucket channels (LWW, authz×2) + doc channels      │   │
│  │  (Loro merge) · snapshot/delta/ack/resume · create · queue drain   │   │
│  │  pes-rules BucketAssigner · pes-oplog (frf-store-redb) · JWT dual  │   │
│  └───────────────┬───────────────────────────────────▲───────────────┘   │
│                  │ WAL (pgoutput via frf-postgres-cdc)│ writes (applied   │
│                  │ → WalToBucketRouter                │ to Postgres,      │
│                  ▼                                    │ re-enter via WAL) │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │ flint-forge: Postgres 18 + pgvector · Quarry REST/GraphQL · Anvil │   │
│  │ pgrx (auth/hooks/llm/vault/meta) · Kiln WASM (flint:host@0.1.0) · │   │
│  │ A2UI registry · Flint Vault (KMS envelope)                        │   │
│  └───────────────────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │ flint-realtime-fabric: Iggy spine · SignalService · AgentService  │   │
│  │ EntityService · AuthzService (Keto/Cedar) · SyncService (CRDT)    │   │
│  └───────────────────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │ flint-gate: Kratos authn · JWT mint (incl. agent role) · Keto     │   │
│  │ UAR (AGPL, process boundary): cloud agents, liter-llm routing     │   │
│  └───────────────────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────────────────┤
│ EDGE TRANSPORTS: WebRTC DataChannel · iroh (QUIC/gossip/docs/blobs) ·    │
│ BLE · LoRa (beacon-only)                                                 │
├──────────────────────────────────────────────────────────────────────────┤
│ DISTRIBUTION: FCP packages — OCI (canonical) · iroh-blobs · Kubo IPFS ·  │
│ git release-log (gitoxide) · cosign/did:prometheus signatures            │
└──────────────────────────────────────────────────────────────────────────┘
```

### 4.1 Data plane

#### 4.1.1 The four-tier database matrix [EXISTS as doctrine; PARTIAL as implementation]

| Tier | Engine | Vector | Persistence | Query stack | Status |
|---|---|---|---|---|---|
| Web | Electric **PGlite 0.4.4** (Apache-2.0) | pgvector ext (HNSW in WASM) | `idb://` + relaxedDurability; OPFS AHP on Chrome/Firefox only (Safari 252-handle bug → IdbFs fallback); SharedWorker multi-tab | SQL via PGlite; PEM graph on top | [EXISTS] in PEM/PES clients |
| Desktop (Tauri) | **pglite-oxide 0.5.1** (crates.io) | pgvector (same SQL as cloud) | `PgliteServer` → sqlx `PgPool` (pool=1) | one sqlx query set shared with cloud | [EXISTS] in scaffold (C-003) |
| Mobile (Flutter) | **SQLite via sqlx-sqlite** in `gen_ui_core` | **sqlite-vec** | app documents dir | deliberate dialect exception behind repository trait | [EXISTS] in scaffold (C-003) |
| Cloud | **Postgres 18** (flint-forge) | pgvector 0.4 | — | Quarry + RLS + Anvil | [EXISTS] v1.0.0 |

Design rules (from `docs/pglite-oxide-tauri-hybrid.md`, corrected 2026-07-15, and brief: knowme-builder-skill-inventory §2.2):

- **The repository trait, not the connection string, is the portability seam.** Desktop+cloud share one sqlx query set swapped by connection string; mobile is a dialect exception implemented behind the same `EntityTransport`/repository traits. Dart and TypeScript never see SQL for settings/sync metadata (intent-level FFI only).
- **Embedding dimensions standardized at 384** (or matryoshka-truncated 768) so vectors replicate across engines; on-device embeddings via fastembed-rs/candle in `gen_ui_core`; PGlite guest bundles pgvector/pg_trgm/citext/hstore/ltree; mobile equivalents sqlite-vec/FTS5/JSON1.
- **PGlite is single-user, single-connection** on web and pglite-oxide alike (pool=1). All concurrency is application-layer queueing; there is no `SET ROLE`, no `current_user`, no RLS inside PGlite — tenancy is enforced at the sync gateway's bucket assignment, never in the client (§2.3).
- **Embedded-engine lifecycle contract** (applies to PgliteServer, PGlite, SurrealDB): exclusive data-dir lock via OS advisory lock (dies with process; stale locks impossible; never write lock-file cleanup code); `tauri-plugin-single-instance` first in the builder; coalesced init via `tokio::sync::OnceCell::get_or_try_init` (never check-then-act — React StrictMode double-invokes startup); warn on double-init, never silently swallow.
- **Boot order INV-5**: migrations → seed/lookup bundles → sync attach, orchestrated by the typestate startup orchestrator emitted in `gen_ui_db::relational`.

#### 4.1.2 SurrealDB graph-RAG role [EXISTS as module; PROPOSED as gated option]

SurrealDB 3.2 remains the pinned graph-RAG spine **where its value is proven**: HNSW vector search → RELATE graph expansion → BM25 → RRF fusion in Rust, exposed to Dart/TS only as intent-level FFI (`memory_search`, `graph_expand`, `upsert_entity`). Given the assessment's "no verified production-readiness evidence" finding and known 3.0 embedded/RocksDB regressions (surrealdb#6800, #5541; brief: knowme-builder-skill-inventory §4.2), the architecture makes SurrealDB an **optional module behind a benchmark gate** with a named fallback (sqlite-vec + FTS5 + recursive CTEs behind the same repository traits). It never appears on the sync critical path: graph-RAG indices are *derived* from synced relational/CRDT state and can be rebuilt locally.

#### 4.1.3 Portability seams [EXISTS]

- `gen_ui_types::transport::EntityTransport` — entity CRUD seam (`list(view)`, `get`, `create`, `update`, `delete`); implemented by `gen_ui_db`, `gen_ui_client` (Forge Quarry), and PEM bridges. "UI never implements it."
- `gen_ui_types::sync::SyncTransport` — sync engine seam (`start()` for a shape/bucket into local store, `enqueue_write(change_json)`, status driving the SyncChip UI). **PSyncV2 plugs in here** — this is the only trait a new sync engine must implement per client.
- `gen_ui_types::view::{ViewDescriptor, FilterSpec, SortSpec}` — transport-agnostic query AST compiling to SQL in `gen_ui_db`, REST params in PEM, and bucket predicates in sync rules.
- `entity-graph-sdl` IR — the cross-language schema contract (Rust CLI, TS generators, Dart parser consume the same IR). **Canonized as the single schema source** for entities, settings schemas, and codegen (brief: entity-management-sync-deepdive §3.1).

### 4.2 Sync plane

The sync plane is the heart of this plan. It evolves PSyncV1 into a unified protocol — working name **PSyncV2** — and consolidates the CDC spine, the gateway, and the three client appliers.

#### 4.2.1 CDC spine (server side) [EXISTS; hardening PROPOSED]

```
Postgres 18 (flint-forge)
   │  logical replication slot (ONE per deployment; `pes_server_slot` today)
   │  publication `pes_pub`; pgoutput protocol v2 (text mode)
   ▼
frf-postgres-cdc  ──decodes Insert/Update/Delete──▶  frf_domain::EntityChange
   │  (pg_walstream 0.6; applied-LSN feedback every 10s)
   ▼
InProcessBroker (channel `entity/changes`)          ← pes-server today;
   │                                                 FRF Iggy spine at scale
   ▼
WalToBucketRouter (pes-router)
   │  BucketAssigner.find_affected_buckets(WAL row)
   ▼
per-bucket append-only op logs (pes-oplog on frf-store-redb, running checksums)
   │
   ▼
PSyncV2 gateway → clients (§4.2.2)
```

Rules:

- **One slot + fan-out is the only viable topology** at thousands of clients (default `max_replication_slots = 10`; a phantom slot retains WAL forever → disk-full outage). Slot hygiene is a standing operational duty: lag alerts, `max_slot_wal_keep_size` ≥ 10 GB policy, PG17 failover slots where available (brief: transports-webrtc-lora-cdc §D).
- **`REPLICA IDENTITY`** governs UPDATE/DELETE identification (PK default; `FULL` at ~2× WAL cost on legacy tables); DDL is **not** replicated — schema evolution rides the additive-migration + compatibility-window machinery (INV-6).
- `supabase/etl` (Apache-2.0, Rust) is the reference codebase for hardening the consumer (snapshot→streaming transition, slot management, backfills); Debezium is explicitly the wrong tool here (JVM/Kafka, no per-user shape concept) (brief: landscape-local-first-sync-engines §3.8, transports-webrtc-lora-cdc §D).
- **Multi-tenant fan-out** is a topology decision: `CdcConfig` is single-tenant/single-channel today. [PROPOSED] channel naming convention `entity/changes/<tenant_id>` with one router per tenant-group, sized by the per-event authz budget (NFR-SYNC-4).

#### 4.2.2 PSyncV2 — the unified sync protocol [PROPOSED; core inherits PSyncV1 EXISTS]

One WebSocket endpoint — **`/ws/v1/sync`** — on the sync gateway (pes-server evolved, deployed as an FRF edge module), MessagePack-framed (`rmp-serde`), multiplexing two channel kinds:

```
Client ──Subscribe{channels, token, resume:{bucket_lsns, doc_vvs}, protocol_version:2}
       ──▶ Gateway
Client ◀── per bucket: SnapshotBegin → SnapshotBatch*{rows} → SnapshotComplete{checksum}
Client ◀── live: Delta{channel, ops, lsn}   ──Ack{lsn}──▶   (resume from last acked LSN)
Client ◀── per doc:   DocState{vv, snapshot?} ↔ DocDelta{loro_bytes}  (server merges)
Client ──Write{channel, entity_type, entity_id, op}──▶ authorized×2, applied, re-enters via WAL
Client ◀── Checkpoint{bucket_checksums} · Keepalive{server_time_ms}
       ──Error{code, redacted_message}   (4000 = protocol version mismatch)
```

| PSyncV1 element [EXISTS] | PSyncV2 evolution [PROPOSED] |
|---|---|
| `Subscribe{buckets, token, resume_lsn}` | `Subscribe{channels[]}` where a channel is `bucket:<id>` or `doc:<id>`; resume carries per-bucket LSNs **and** per-doc Loro version vectors |
| `Write{op: Upsert\|Delete\|CrdtPatch}` | adds **`Create`** — ownership-establishing insert: server validates the payload against the bucket's data-query shape, assigns ownership from JWT claims (e.g. `owner_id = sub`), inserts, and lets it re-enter via WAL. Fail-closed validation exactly as today |
| Writes while disconnected **throw** (TS client) | **durable client offline write queue** with the field-guide state machine `PENDING → IN_FLIGHT → SYNCED / RETRYABLE_ERROR / FATAL_ERROR → DEAD_LETTER`; idempotent ops (client UUIDs + `ON CONFLICT`); server acknowledges per-op (`mark_synced(confirmed_seq)` semantics from FRF's `OpStore`) |
| No poison handling | **poison/DLQ**: `FATAL_ERROR` ops quarantine to a dead-letter table with operator surface (SyncChip → diagnostics screen); never silently dropped, never infinitely retried (parity with PEM's `poisonHandler`) |
| 50 ms oplog poll per connection | push/broadcast channel in `pes-oplog` (subscribe API, deferred in PES today) → target p95 delta latency < 100 ms (NFR-SYNC-2) |
| Bucket channels only | adds **doc channels**: Loro deltas as opaque bytes; server-side merge via `frf_crdt::apply_delta`; snapshots/checkpoints via `CrdtStore` port (wire `SurrealCrdtStore` or redb by default — in-memory defaults are unacceptable) |
| Custom JWT validation in `pes-gateway/auth.rs` | **dual-JWT**: flint-gate-minted auth token → short-lived sync token scoped to buckets/docs (15–60 min, juit-pgproxy HMAC one-time-token pattern for the WS upgrade `?token=` handshake, since browsers can't set headers); JWKS rotation, `tenant_id` claims, alignment with Kratos/Supabase auth references |
| `PROTOCOL_VERSION = 1` | `= 2`; version mismatch → error 4000 with redacted client-facing message |

**Conflict model (unchanged, deliberately):** bucket channels are server-authoritative — WAL order is the total order, last-write-wins at Postgres for `Upsert`/`Delete` (whole-row JSON payloads), true CRDT merge only for `CrdtPatch` doc columns. Checksums + LSN-gap detection (`SyncError::LsnGap`, `ChecksumMismatch`) catch stream corruption. **No client-side conflict resolution ever exists for bucket channels** (PowerSync's causal+ checkpoint invariant — brief: transports-webrtc-lora-cdc §D).

**Per-event authorization re-check [EXISTS in FRF/Forge; PROPOSED as PSyncV2 invariant]:** subscribe-time Keto `check(subject,"view",channel)` (coarse, cached, tuple-delete invalidation), then per-event re-check before payload release — the "per-event RLS" discipline both FRF's fan-out and Forge's `FabricChangeSource` implement ("NEVER removed or skipped"; WAL bypasses RLS, so the changed row is re-queried as the subscriber). Mitigations for the known scaling hazard: subscribe-time scoping, topic partitioning, check-cache with invalidation (brief: flint-realtime-fabric-deepdive §2.3).

**Tenant-safe shape/bucket factories [EXISTS as pattern; PROPOSED as gate]:** the rule from the PGlite doctrine — a bucket/shape definition without a tenant predicate must be rejected at load time — becomes a CI assertion and a `pes-rules` validator rule: every sync-rule factory includes a tenant-predicate proof (parity with PEM's `createTenantScopedElectricAdapter` refusing tenantless shapes). CVE-2026-40906 (Electric `ORDER BY` SQLi, CVSS 9.9) is the standing lesson: parameterized queries and identifier allowlists everywhere in the rule surface (brief: entity-management-sync-deepdive §1.6).

#### 4.2.3 Client attach points

**(a) Web — PGlite in the browser [PARTIAL today; PROPOSED completion].**

The blocking gap: FRF's CRDT `SyncService` is bidi gRPC, unreachable from browsers (Connect-web/gRPC-web buffer request bodies; bidi requires HTTP/2 full-duplex). PSyncV2 solves this by making the sync gateway's **WebSocket** endpoint the single browser-reachable surface — exactly how `/ws/v1/signal` was added for browsers in FRF (precedent p23-c003) (brief: flint-realtime-fabric-deepdive §4.1).

```
React 19 app
  └─ PEM 3.x entity graph (Zustand)
       └─ prometheusSyncTransport (EntityTransport<T> bridge)      [EXISTS]
            └─ @prometheus-ags/entity-sync-core (PSyncV2 client)   [EVOLVE]
                 │ WS+MessagePack → /ws/v1/sync  (?token= HMAC)
                 ▼
            applyOps → PGlite tables (transactional, idempotent)   [EXISTS]
            doc channels → Loro merge in-browser                   [EXISTS via
                 (frf-wasm::crdt_apply_delta or loro-crdt JS)       frf-wasm]
            offline queue → PGlite `_operation_queue` table        [PROPOSED]
```

- Web client store: PGlite tables for bucket channels (augmented `_local_*` columns + sync-trigger pattern to distinguish server-replayed rows from user writes), `_operation_queue` table for the offline write queue, `_graph_snapshot` for PEM persistence, CRDT doc bytes as `crdt_state BYTEA` (merged client-side now — PES stores them opaquely today).
- Four-phase boot (INV-5): `idle → hydrating → syncing → ready` with `useGraphSyncStatus`; resync-on-resume on iOS Safari; OPFS detection with IdbFs fallback; SharedWorker leader election for multi-tab.
- Electric's `@electric-sql/pglite-sync` is **not** used (read-path-only, alpha, conflicts with INV-7 one-CDC-pipeline). Recorded as fallback only.

**(b) Tauri desktop — pglite-oxide [PROPOSED; clean path].**

Everything needed exists in Rust; no FFI tax:

```
Tauri app (React 19 frontend)
  └─ Tauri commands → gen_ui_core
       └─ gen_ui_sync [NEW crate] implements SyncTransport
            ├─ pes-sdk-rust [COMPLETE THE STUB] — PSyncV2 client
            │    (tokio-tungstenite WS + rmp-serde; reconnect w/ backoff;
            │     proactive JWT refresh; resume from acked LSN / doc VV)
            ├─ frf-store-redb — durable offline op-log (queue_op/drain_pending/
            │    mark_synced)                                        [EXISTS]
            ├─ frf-crdt (Loro) — doc-channel merges                  [EXISTS]
            └─ sqlx PgPool → PgliteServer (pglite-oxide) — apply     [EXISTS]
                 bucket ops transactionally; augmented _local_* cols
```

Do **not** route through `frf-ffi`/`sdks/dart` (that path is for Swift/Kotlin/Dart hosts, and its Dart transport is blocked upstream anyway). A Rust host uses the native crates directly — identical merge code, no binding tax (brief: flint-realtime-fabric-deepdive §4.2). The same `gen_ui_sync` implementation serves the Axum web-server host (`gen_ui_host`) unchanged.

**(c) Flutter mobile — frb2 bridge over `pes-sdk-rust` [PROPOSED; resolves the Dart question].**

The TJ-ARCH-MOB-001 invariant — all networking in the shared Rust crate, never re-implemented in Dart — collides with PES's `v4-dart-sdk` proposal (pure-Dart `web_socket_channel` + `drift`). **Decision (recommended, OD-2c): one protocol implementation, in Rust, exposed to Flutter via flutter_rust_bridge 2.12:**

```
Flutter app
  └─ Riverpod 3.3 providers (retry: (_, __) => null on FFI providers!)
       └─ gen_ui_ffi (frb2 codegen target)
            └─ gen_ui_sync (same crate as Tauri) — pes-sdk-rust inside
                 ├─ storage: sqlx-sqlite + sqlite-vec (mobile dialect)
                 ├─ redb op-log (same as desktop)
                 └─ typed event streams → Dart (SyncStatus, DeltaApplied,
                      QueueDepth) — never raw frames
```

This also absorbs the FRF Dart-transport blockage (`uniffi-bindgen-dart` 0.1.3 lacks the async ABI; `FrfFfiClient.connect` throws): Flutter never touches the UniFFI binding — `gen_ui_core` uses `frf-sdk-rust`/`pes-sdk-rust` natively and exposes only intent-level typed surfaces over frb2 (brief: flint-realtime-fabric-deepdive §5.4). The `entity_graph_flutter` package keeps its graph/providers/SDL role as the *state mirror*; sync lives in Rust.

#### 4.2.4 The write-back loop [PROPOSED]

FRF has no spine→Postgres writer today; PES's gateway applies writes directly to Postgres (which then re-enter via WAL — a clean event-sourced loop). PSyncV2 keeps the PES model: writes are authorized and applied at the gateway against Postgres with the origin JWT's RLS context; the change re-enters through CDC and is broadcast to all subscribers *including the writer* as ordinary `Delta`s (self-echo deduplicated by op UUID). No separate projection service is needed at PSyncV2 scope; a future spine-consumer projection service in flint-forge remains an option for high-write-volume tenants (brief: flint-realtime-fabric-deepdive §4.3).

---

### 4.3 Realtime & edge transports

The CDC spine (§4.2.1) is the consistency backbone. Everything in this section is an **edge optimization or an offline channel** — gossip-style eventual delivery never replaces server-authoritative ordering (brief: transports-webrtc-lora-cdc §B).

#### 4.3.1 Backbone transports [EXISTS]

- **Native gRPC (HTTP/2)** on the FRF gateway for all six tonic services, with `tonic_web::GrpcWebLayer` + `accept_http1(true)` so browsers reach unary/server-streaming RPCs via Connect/gRPC-web over HTTP/1.1.
- **WebSocket mux** on the HTTP port: `/ws/v1/subscribe` (spine fan-out), `/ws/v1/agents`, `/ws/v1/signal`, and — added by this plan — **`/ws/v1/sync`** (§4.2.2). Browser WS auth via `?token=` query param (HMAC one-time token, §4.2.2); HTTP/gRPC via `Authorization: Bearer`.
- **MessagePack** for sync frames (PSyncV2); JSON envelopes for spine/agent/signal (wire encoding never leaks domain types — JSON at FFI boundaries, opaque bytes for CRDT payloads).

#### 4.3.2 WebRTC DataChannel sync adapter [PROPOSED]

Precedents and limits (brief: transports-webrtc-lora-cdc §A):

- y-webrtc's mesh tops out at ~20–30 peers (`maxConns = 20 + floor(rand*15)`; beyond that, partial mesh with no sync guarantees — Kevin Jahns's own guidance). Trystero 0.23 adds the admission-handshake hook, connection reuse across rooms, and chunking/throttling we should copy.
- Rust terminators: **`webrtc-rs/rtc`** (preferred — includes TURN/mDNS pieces str0m lacks; sans-IO, tokio-composable; 0.x semver caution) or **str0m** (simpler single-state-machine embed; lacks TURN/mDNS; "peer-2-peer has received less testing"). `flutter_webrtc` 1.4.1 covers all Flutter targets.
- TURN is a real operational cost — every relayed byte consumes server bandwidth; budget for coturn or accept WebSocket fallback for a fraction of peers.

Design: a new crate **`frf-sync-webrtc`** [PROPOSED] implementing a `PeerSyncTransport` port over DataChannels, exchanging Loro `export_updates_since` deltas and PSyncV2 doc-channel frames; signaling rides the existing FRF `SignalService` (built for the SFU work); admission follows the Trystero handshake pattern bound to flint-gate JWTs. Scope: **small-group P2P sessions and LAN** — phone↔phone, phone↔desktop, co-present collaboration, agent side-channels. Explicitly **not** the fan-out backbone to thousands of clients. DataChannel payload cap (~16–256 KiB depending on stack) forces app-layer chunking for large doc snapshots. Note: FRF's str0m media SFU work is *separate* and remains gated OFF; this adapter needs DataChannels only, not media (brief: flint-realtime-fabric-deepdive §2.9).

#### 4.3.3 iroh path (sovereign P2P substrate) [EXISTS in substrate; PROPOSED convergence]

- **iroh 1.0.0-rc** (2026): QUIC with hole-punching + relay fallback, pkarr/DNS discovery, ALPN protocol mounting; WASM/browser support demonstrated. **iroh-docs** (0.95): namespace-scoped multi-author KV with range-based set-reconciliation sync + live gossip; **iroh-blobs**: BLAKE3 content-addressed, bao-tree verified streaming, resumable; **iroh-gossip**: lightweight pub/sub (brief: transports-webrtc-lora-cdc §B).
- The skill-pack's substrate already runs this: `IrohDocsAdapter` (ticket-based two-node sync, tested) and `sovereign-sync`'s gossip topics (brief: prometheus-skill-pack-inventory §2).
- Convergence design [PROPOSED]: a **`FlintAdapter` implementing the substrate's `StorageProvider` trait over FRF channels** — making flint-realtime-fabric a third storage backend alongside `LocalDirAdapter` and `IrohDocsAdapter`, rather than replacing sovereign-sync wholesale. Device-to-device P2P replication (iroh-docs tickets) stays for operator-scoped sync groups; FRF remains the server-anchored path (brief: prometheus-skill-pack-inventory §6.2).
- Sovereign deployment means running your own iroh relay + discovery (n0's are conveniences); iroh 0.x churn mandates pinning behind an internal trait. iOS background limits mean P2P is foreground-only on mobile — store-and-forward via the server spine covers the rest.

#### 4.3.4 BLE and platform-local P2P [PROPOSED]

BLE 5 (~1–2 Mbps PHY) and OS P2P APIs (Apple MultipeerConnectivity, Android Nearby Connections, Wi-Fi Direct) are the realistic last-10-meters transports for consumer devices — vastly more practical than LoRa (BitChat's store-and-forward messenger proves phone-native P2P sync without internet). Scoped as a Phase-6 adapter behind the same `PeerSyncTransport` port, exchanging Loro deltas between phone-adjacent devices (brief: transports-webrtc-lora-cdc §C).

#### 4.3.5 LoRa — explicitly scoped as opportunistic beacon channel only [PROPOSED, LOW priority]

The verdict is LOW practicality for general sync (brief: transports-webrtc-lora-cdc §0, §C):

- Meshtastic hard payload cap **233 bytes**; LongFast ≈ **1.07 kbps** PHY before mesh overhead, duty-cycle limits (EU868 1%), and collision loss — effective app throughput is a few hundred bytes per minute in a busy mesh.
- `lora-rs` (`lora-phy`, `lorawan-device`, `lorawan-encoding`) is `no_std` end-device tooling; there is **no mature Rust mesh stack** — greenfield on ESP32-class hardware; BitChat-over-LoRa (phone ↔ ESP32 via BLE, bridge into mesh) is the validated hybrid shape.

Design: a dormant opportunistic channel behind the transport registry that carries **only** version-vector/checkpoint gossip and tiny high-priority ops ("my doc is at VV {…}", merkle roots, presence). If peers diverge, real sync is *scheduled* over BLE/Wi-Fi/internet when available. LoRa never carries initial sync, snapshots, blobs, or chatty anti-entropy. Budget: a few messages per node per minute. This is a field/off-grid feature, not a consumer transport.

### 4.4 Agent plane

#### 4.4.1 Two execution tiers [EXISTS as pieces; PROPOSED as system]

| Tier | Runtime | Inference | Governance | Status |
|---|---|---|---|---|
| **Client agents** | `gen_ui_core` PMPO loop (UAR embedded mode) | GGUF via llama-cpp-2 (desktop/mobile catalog: Qwen2.5 0.5B/1.5B, Phi3.5Mini, Llama3.2 1B/3B, Gemma2 2B, SmolLM2 1.7B); WebLLM on web | local Cedar policy + user approvals; `UarMode::Embedded` | [EXISTS] in scaffold |
| **Cloud agents** | UAR v1.0.0 (**AGPL-3.0-only** — process boundary mandatory; MIT SDKs only) | liter-llm routing (142+ providers, capability requirements); Flint Ember (in-DB LLM via gate) for DB-adjacent jobs | Cedar hot-reloaded PolicySet; deny is final; audit | [EXISTS] |

Browser/in-app inference limits are respected: ≤3B single-user workloads in-browser (WebLLM ~70–80% of native speed; Firefox WebGPU immature — feature-detect + fallback); mobile GGUF via the existing Rust path; cold-start 30–60s models are cached at process start (brief: agentic-ui-agent-harness-patterns §3.1).

#### 4.4.2 The two-stage router [PROPOSED]

Following Microsoft's hybrid reference pattern (2026-05-27) and the LiteLLM three-pillar pattern (brief: agentic-ui-agent-harness-patterns §3.2), `gen_ui_agent` gains a router module:

```
turn request
  ▼
Stage 1 — DETERMINISTIC PRIVACY GATE (code, not LLM):
   privacy_class(prompt, context, entity ACLs)
   ├─ RESTRICTED → local-only path. If local fails → FAIL CLOSED.
   │   A RESTRICTED prompt never falls back to cloud. Honest
   │   "could not complete locally" label, never silent escalation.
   └─ GENERAL ──▶ Stage 2 — complexity heuristic (small local
       classifier or rules: token count, tool requirements,
       needs_vision, min_context) → local | cloud
  ▼
Stage 3 — AVAILABILITY circuit breaker: GPU saturation overflows
   to cloud (GENERAL only); cloud outage falls back local with
   degraded-capability label.
```

Hard rules (from the field): deterministic gates beat probabilistic ones; same response schema from every path with honest fallback labels; correlation IDs everywhere; non-reasoning model for the router. **Per-turn provenance** is first-class in the protocol: every ContentBlock carries `{path: local|cloud, model, privacy_class, correlation_id}` so the UI can render provenance per block (brief: agentic-ui-agent-harness-patterns §3.2).

#### 4.4.3 Shared state: one synced conversation, two writers [PROPOSED]

There is no off-the-shelf standard for local/cloud agent shared state; the composable pieces are AG-UI `STATE_DELTA`, A2A task delegation, and the sync engine itself. The KnowMe pattern: **one CRDT-synced conversation/state document, two writers** —

- Conversation entities (messages, artifacts) are bucket-synced relational rows (INV-1: Postgres authority); the *live working state* of a run (scratchpad, partial plans, pending confirmations) is a Loro doc channel (§4.2.2) that both the client agent and the cloud agent write to.
- "The conversation is the entity graph": messages are entities, tool calls are patches, tool results are entities; the durable agent loop rides PEM's pending-actions queue so a crash mid-agent resumes on next launch (brief: prior-art-supporting-projects §1.10).
- Cloud agents participate through UAR's Postgres persistence provider (`config.remote.postgres.yaml`) pointing at flint-forge — the integration seam that puts cloud-agent state on the same CDC spine as everything else.

#### 4.4.4 The protocol vocabulary — and the A2UI naming resolution [PROPOSED; decision OD-1]

The 2026 stack (brief: agentic-ui-agent-harness-patterns §1.1): MCP (+MCP Apps) for tools, A2A for agent↔agent delegation, AG-UI for the agent↔user event stream, A2UI for declarative UI. Oracle's one-liner: "Agent Spec defines what runs, AG-UI carries the interaction, and A2UI defines what the user touches" (2026-03-12).

Mapping to the owner's existing design:

| Industry (external wire) | KnowMe internal (canonical) | Notes |
|---|---|---|
| AG-UI events (~16 types: TEXT_MESSAGE_CONTENT, TOOL_CALL_START, STATE_DELTA…) | `AguiEvent` (12 variants) in `gen_ui_protocol` | align event vocabulary → interop with LangGraph/CrewAI/Microsoft AF backends |
| **Google A2UI** JSONL (`createSurface`, `updateComponents`, `updateDataModel`, `deleteSurface`; catalog negotiation) | **ContentBlock** (11 frozen variants) + internal `A2uiEvent` (27 variants) | **adopt A2UI as the external serialization; ContentBlock stays the canonical Rust type** — one serde mapping in `gen_ui_protocol` |
| A2UI catalogs (URL-identified, client-declared renderers) | ContentBlock variant set + extension-contributed catalog fragments (§4.5.2) | catalog negotiation = the distribution hook for UI modules |
| A2A (`/.well-known/agent-card.json`, tasks, artifacts) | client agent card (localhost/LAN) + UAR cloud cards | client↔cloud delegation across trust boundaries |
| MCP Apps (`_meta.ui.resourceUri`, `text/html;profile=mcp-app`) | flint-forge A2UI registry MCP server + HTMX fragment modules | server-driven UI modules |

**Naming resolution (recommendation for OD-1):** the owner's internal "A2UI" predates Google's but the namespace is now occupied (a2ui.org, v0.9 shipped 2026-04-17, production Flutter/React renderers). Recommended: **adopt Google's A2UI wire format externally** (option (i) in brief: agentic-ui-agent-harness-patterns §1.3), keep `ContentBlock` as the canonical internal type, and rename *documentation-level* references to the internal 27-variant enum to "gen_ui surface events" (`GenUiEvent` at the next protocol-major) to end the collision. Google's GenUI Flutter SDK (`genui` ^0.8.x, official docs 2026-05-27) validates the category; KnowMe's differentiators are Rust-side protocol enforcement, local-first sync, and WASM-component catalogs. Watch `genui_core` (pure-Dart A2UI parser, ~40% complete Apr 2026): if it matures, Flutter could consume a raw A2UI stream — but per the invariant, the *parse/translate* step still lives in Rust, with Dart receiving typed ContentBlocks.

#### 4.4.5 Client↔cloud handoff protocol [PROPOSED]

1. Local agent classifies a turn as cloud-bound (router, §4.4.2) → mints/attaches a delegation token (flint-gate `agent`-role JWT, delegatable, `workflow_id`-scoped per the anon/service-role spec's 4th role) → A2A `message/send` to the cloud agent's card with the conversation doc's version vector.
2. Cloud agent streams AG-UI events (through UAR's AG-UI SSE); the client folds them into ContentBlocks locally; `STATE_DELTA`s write into the shared Loro doc; artifacts persist to Postgres (bucket-synced back to all devices).
3. Late joiners / reconnects catch up via A2UI surface replay (UAR pattern) + doc sync resume from version vectors.
4. Revocation: token expiry + Keto tuple deletion; per-event authz re-check on the spine ensures revoked access stops flowing (INV-3).

---

### 4.5 Extension plane (WASM)

One component model, two runtime placements, three component kinds. The goal: an extension author writes **one signed package** that adds a native skill to agent harnesses, a UI surface, and synced settings — installable on web, mobile, desktop, and server.

#### 4.5.0 The unified component model [server: EXISTS; client: PROPOSED]

```
                    flint WIT package family
        ┌──────────────────────────────────────────────┐
        │ flint:host@0.1.0  (FROZEN — server world)    │
        │   db · llm · kv · identity · secrets         │
        │   world edge-function (wasi:http proxy)      │
        ├──────────────────────────────────────────────┤
        │ flint:client@0.1.0  [PROPOSED — client world]│
        │   same five interface SHAPES, local bindings: │
        │   db→repository traits · llm→InferenceProvider│
        │   (+router escalation) · kv→settings service  │
        │   identity→local session · secrets→keychain/  │
        │   Vault refs                                  │
        ├──────────────────────────────────────────────┤
        │ flint:skill@0.1.0 [PROPOSED — skill world]   │
        │   run/stream over typed records (converges    │
        │   uar:skill@0.1.0's string-in/string-out)     │
        └──────────────────────────────────────────────┘
              │                        │
   Server runtime            Client runtime
   Kiln fke-runtime          gen_ui_plugins [NEW crate in gen_ui_core]
   wasmtime 46 Cranelift     ├─ desktop/Android: wasmtime + Cranelift
   fuel 10M · epoch 10ms     ├─ iOS: wasmtime + PULLEY interpreter
   ProxyPre cache            │   (no JIT allowed; 2–10× slower — pair
   Cedar capability ∩        │   with AOT .cwasm where policy allows)
   per-request Store         ├─ browser: jco-transpiled components OR
                             │   Extism core modules + VS Code-style
                             │   worker+SharedArrayBuffer bridging
                             │   (requires cross-origin isolation)
                             └─ same fuel/epoch/StoreLimits discipline
```

Design rules:

- **Interface shapes are identical across worlds** so pure-compute components run unmodified in both placements; platform-specific capabilities are declared as separate WIT interfaces (brief: wasm-extensibility-packaging §A.6.2). WIT has no `json` type — params/rows are JSON-encoded strings, matching the server world's existing style.
- **Target WASI 0.2 worlds for production**; track WASI 0.3 (ratified 2026-06-11; native `future<T>`/`stream<T>`) behind a feature flag until runtime support matures — the exact gating wasmCloud uses (brief: wasm-extensibility-packaging §A.7).
- **Convergence over invention for skills**: UAR's `uar:skill@0.1.0` (`run: func(input: string) -> result<string, string>`) and the legacy librefang raw ABI (`memory`/`alloc`/`execute` exports + `host_call`) both collapse into the flint WIT family (OD-5). WIT/components are the decision; librefang ABI is legacy (brief: prometheus-skill-pack-inventory §5.3, §7-G4). The flint-forge convergence invariant already shares `fke-runtime` host primitives between Kiln and UAR Tier-2 WASM skills — the client host reuses the same engine configuration, ProxyPre caching, capability linker, and fuel/epoch limits (brief: flint-forge-deepdive §1.15).
- **Version discipline**: wasmtime's host-embedding API is still moving (45→46 churn); isolate behind the runtime abstraction and record `wasmtime_version` in the AOT cache key — `fke-domain` already does this (brief: wasm-extensibility-packaging §A.6.4).
- **iOS App Store risk (guideline 2.5.2)**: downloaded executable code is a store-review risk for consumer plugin delivery. Mitigations: enterprise/TestFlight channels, in-app-bundled components for the base set, and treating downloaded components as *data-driven* (A2UI catalogs, settings schemas are pure data; only skills carry executable wasm). Noted as a program risk (R-11), not a blocker (brief: wasm-extensibility-packaging §A.7).

#### 4.5.1 Component kind (a): native skills for agent harnesses [server: PARTIAL; client: PROPOSED]

A skill component = WIT-typed native capability (tools, transformers, encoders) plus its `SKILL.md` procedural knowledge. Guest authoring: Rust (`cargo component` + a `flint-skill`-style SDK — the server SDK already compiles on `wasm32-wasip2`), JS/TS (`jco`/`componentize-js`), Python (`componentize-py`), TinyGo. Host capabilities are coarse-grained by design (wasm↔host chatty interfaces cost serialization): `db` queries route through governed seams (server: flint-gate under origin JWT; client: repository traits with the component's declared scope), `llm` routes through the router (never direct provider keys — the host injects credentials via Flint Vault/keychain), `kv` per-invocation ephemeral, `identity` read-only claims, `secrets` opaque handles with Cedar-gated reveal.

#### 4.5.2 Component kind (b): UI/UX modules [registry: EXISTS; client rendering: EXISTS; packaging: PROPOSED]

A UI module ships **declarative assets**, not code, in the common case:

1. **A2UI catalog fragments** — widget schemas (JSON Schema prop contracts) + renderer bindings (`renderers: {react, flutter, htmx}`, package overrides), mirroring flint-forge's `flint_a2ui.components` model. At install, fragments merge into the client's catalog; the agent can then compose surfaces from them through the normal A2UI flow. Unknown component types **fail closed** (UAR's certified-catalog rule).
2. **HTMX fragment templates** — server-driven UI (settings panels, admin surfaces, extension config forms) rendered server-side and streamed over SSE, following the event-as-invalidation pattern (CDC event → `hx-trigger="sse:x.updated"` → fragment re-fetch). Precedent: `prometheus-research`'s `ComponentRegistry` (8 server-rendered components) and the htmx.org MCP-Apps hypermedia pattern ("the less state you pack into the client, the less surface area for things to go wrong") (brief: prometheus-skill-pack-inventory §2.6, agentic-ui-agent-harness-patterns §1.8).
3. **(Optional) remote-DOM / MCP Apps iframe modules** — the escape hatch for unconstrained surfaces: `text/html;profile=mcp-app` resources in sandboxed iframes (`sandbox="allow-scripts"`), actions bridged via postMessage. Deliberately positioned as opt-in; constrained generation is the default (brief: flint-forge-deepdive §1.11, agentic-ui-agent-harness-patterns §1.5).

Most UI modules never need wasm at all — **wasm is for skills/compute, JSON is for UI** (brief: wasm-extensibility-packaging §B.3).

#### 4.5.3 Component kind (c): settings schemas with synced client/server storage [PROPOSED]

The VS Code `contributes.configuration` pattern, extended with sync semantics (brief: wasm-extensibility-packaging §B.2, agentic-ui-agent-harness-patterns §4):

- **Declaration**: the package manifest carries a self-contained JSON Schema (no `$ref`/`definitions`; draft 2020-12 pinned; per-property `type`/`default`/`enum`/`pattern`/`markdownDescription`/`deprecationMessage`).
- **Scopes per key** (VS Code's scope enum + sync annotations): `application` (org-managed, server default), `user` (**synced** across the user's devices), `machine`/`machine-overridable` (never sync), `window`/`resource` (session/workspace-local), and `secret` (secure storage class, **never synced — INV-4**).
- **Storage**: values live in a synced `(extension_id, scope, key)` table — PGlite (web) / pglite-oxide (Tauri) / SQLite (mobile) / Postgres (server). `user`-scoped rows ride a per-user settings bucket in PSyncV2 with **last-writer-wins per key** and schema-version migrations (VS Code punts on this with flat KV; we must version). Org-managed defaults live server-side (Chrome `storage.managed` precedent) and override at read time.
- **Secrets**: `secret`-scoped keys store only a reference (`vault://…` or keychain ID); values live in Flint Vault (server) / platform keychain (desktop) / flutter_secure_storage (mobile). The sync layer structurally cannot replicate them — they are filtered at queue-enqueue time, not by convention.
- **Rendering & validation**: the same schema drives web settings UI (RJSF v6 or JSON Forms — budget a shadcn renderer set), Tauri settings UI, server validation (`schemars` from Rust types), and agent-facing introspection (MCP tools reading/writing settings). Zod v4's native `z.toJSONSchema()` covers TS-side generation; the manifest schema is the single source of truth shipped *inside* the package.
- **Merge semantics**: LWW per key via bucket sync; where a settings document is genuinely collaborative (shared workspace config), it moves to a Loro doc channel instead. Keys carry `$origin`/`$updatedAt` sync metadata exactly like PEM entities.

#### 4.5.4 Capability manifests and Cedar policy [EXISTS server; PROPOSED client]

Every package declares capabilities in its signed manifest; at instantiation, granted = declared ∩ Cedar(publisher). Server actions exist (`kiln:invoke`, `kiln:capability:<name>`, `kiln:secret:reveal`, `KILN_REGISTER`). Client equivalents [PROPOSED]: `genui:component:invoke`, per-capability grants (`genui:capability:db|llm|kv|identity|secrets|http`), policy evaluated by the same `cedar-policy 4` engine embedded in `gen_ui_core`, with policy packs synced as org-managed settings (§4.5.3) and hot-reloaded (UAR's hot-reload pattern). The skill-pack's vertical overlays (healthcare requires `audit_trail_id`; financial requires `dual_approval`) are the governance precedent (brief: prometheus-skill-pack-inventory §4.4).

#### 4.5.5 Resource limits [EXISTS server; PROPOSED client-parity]

Fuel metering (10M instructions default), epoch interruption (10 ms ticker), `StoreLimits` memory/table caps, fresh Store per invocation, pooling allocator for multi-tenant density, AOT `.cwasm` keyed by `(source_digest, target_arch, wasmtime_version)` in the control plane with deserialize-only data plane. Under Pulley (iOS), budgets tighten: interpreter ≈2–10× slower than Cranelift, three Pulley-specific advisories landed in 2025, and fuel/epoch limiting is *more* critical under interpretation (brief: wasm-extensibility-packaging §A.3–A.4). Cold-start targets: ~0.5 ms per invocation server-side; ~300 KB–1 MB per instance; 10K+ tenants/host (flint-forge's own sandboxing research — WASM primary, microsandbox as the optional higher-isolation tier for untrusted AI-generated code).

### 4.6 Distribution plane (FCP packaging standard)

The **Flint Component Package (FCP)** [PROPOSED] — the single standard for distributing WASM components, agent skills, UI modules, and settings schemas across the platform. It takes the strongest piece of each proven mechanism and matches the crates flint-forge already has (brief: wasm-extensibility-packaging §C.7).

#### 4.6.1 Why not pure-IPFS or pure-git alone

- **Pure IPFS**: no maintained full Rust node (`rust-ipfs` archived 2022-10-23); public DHT is Sybil-attackable (arXiv:2505.01139, ~80% lookup denial in the wild); operational heaviness. Kubo is healthy (0.39, Provide Sweep, AutoTLS) but is a server-side tool here, not a client embed.
- **Pure git**: excellent audit/mirror semantics (and gitoxide makes it embeddable everywhere incl. iOS/wasm), but git is a *log*, not a content store — no LFS in gitoxide, blobs don't belong in it.
- **warg**: the transparency-log ideas are right, but the reference implementation was archived 2025-07-28; the ecosystem converged on OCI artifacts via `wkg`.
- **FCP synthesis**: OCI canonical transport (universal, `wkg`-compatible tooling, digest-addressed) + content-addressed P2P mirrors (iroh-blobs for LAN/offline/device↔device; Kubo HTTP for IPFS interop) + a signed git release-log (warg's transparency idea on gitoxide's substrate) + existing Flint signing (cosign/did:prometheus). **Multi-transport, one identity** — the digest is the join key (§2.5).

#### 4.6.2 Package layout [PROPOSED]

```
OCI artifact (wkg-compatible):
  config:  application/vnd.wasm.config.v0+json        # standard wasm config
                                                       # (imports/exports — searchable)
  layers:
    application/wasm                                   # the component (single .wasm)
    application/vnd.flint.component.manifest.v1+json   # flint-component.json
    application/vnd.flint.component.wit.v1+tar         # WIT package (world + deps)
    application/vnd.flint.component.assets.v1+tar      # SKILL.md, A2UI fragments,
                                                       # HTMX templates, tokens, icons
  annotations:
    org.opencontainers.image.{source,revision,created}
    sh.flint.signature = cosign bundle ref / DID signature
```

`flint-component.json` — the self-certifying manifest (adapting flint-forge's `FunctionManifest`):

```jsonc
{
  "apiVersion": "flint.sh/v1",
  "kind": "ComponentPackage",            // SkillPackage | UiModulePackage | SettingsPackage
  "name": "prometheus:content-block-markdown",
  "version": "1.4.0",
  "world": "flint:host/extension@0.3.0",          // pinned WIT world
  "requires": { "host": ">=0.9 <2.0",
                "capabilities": ["wasi:http/outgoing-handler", "flint:kv/read"] },
  "settings": { /* VS Code-style JSON Schema; per-key "scope":
                   "application|user|machine|workspace|secret" */ },
  "ui":    { "a2ui": "assets/a2ui.catalog.json",
             "htmx": "assets/templates/",
             "designTokens": "assets/tokens.json" },
  "skill": { "manifest": "assets/SKILL.md",
             "harness": ["claude-code", "kimi", "opencode", "codex"] },
  "privacy": { "class": "public|trusted|local" },  // SyncManifest classes
  "digests": { "wasm": "sha256:…", "ipfs": "bafy…", "iroh": "blake3:…" },
  "signatures": [{ "kind": "did", "key": "did:prometheus:…", "sig": "…" }],
  "not_before": "…", "not_after": "…"
}
```

The manifest binds `name@version → digest → WIT world pin → capabilities → privacy class`; the signature chain (Ed25519 over `sha256(artifact) ‖ content_digest`, or cosign/Rekor keyless) makes the manifest **self-certifying** — the Postgres registry row (`flint_kiln.functions`) is only a discovery cache, not a trust root (brief: flint-forge-deepdive §4.2).

#### 4.6.3 Distribution planes [stores: EXISTS; release-log + mirroring: PROPOSED]

1. **Canonical**: OCI registry (GHCR/Harbor/ECR) — `wkg oci push/pull`; `.well-known/wasm-pkg/registry.json` on the platform registry domain pointing at OCI (+ optional warg-compatible endpoints for tooling interop). `fke-store-oci` is already aligned.
2. **P2P / local-first**: iroh-blobs tickets for device↔device, LAN, and offline install (BLAKE3 verified, resumable — pin the production line per the crates.io caveat); Kubo HTTP API + delegated routing for IPFS-public mirroring (`fke-store-ipfs` stays; deployment docs pin Kubo ≥0.39 for Provide Sweep; integrity never depends on DHT lookup).
3. **Source/audit**: per-package **append-only signed release-log as a git repository** (gitoxide-managed): commits = releases (init/release/yank), signed tags = versions. Transparency and mirroring = `git fetch`; offline verification against the log head you trust; yank entries refuse *new* installs while cached copies remain runnable (local-first ethics, §2.1). Large blobs never enter git (no gix-lfs) — only logs and manifests.
4. **Index/discovery**: flint-forge Postgres (JSONB + pgvector embeddings, extending the A2UI registry model) as the query/semantic-search layer; a replicated git index repo for offline clients. Vector search is a server-side luxury, not a sync requirement.

#### 4.6.4 Client install behavior [PROPOSED]

```
resolve name@version
  → fetch release-log head (git over HTTPS / iroh-gossip topic / LAN mirror)
  → verify signature chain + locate manifest → pick best transport
    (local iroh peer → LAN Kubo → OCI registry)
  → fetch artifact, VERIFY digest against manifest (all hash universes:
    sha256 / IPFS CID / BLAKE3 translation tooling)
  → cache in content-addressed store
  → load: wasmtime (native) / jco-or-Extism (browser)
  → register: settings schema into settings service (sync rules per scope);
    A2UI/HTMX assets into the UI registry; SKILL.md into harness skill dirs
  → updates: watch release-log head; prompt or auto-update per policy
```

Offline install works end-to-end: resolve from a local mirror (iroh ticket / LAN peer / USB git bundle), verify signature + digest against the trusted log head, install from the content store — **no central service required** (brief: wasm-extensibility-packaging §C.6).

---

### 4.7 End-to-end flows

Five walkthroughs that exercise the whole architecture. Each names the crates/packages actually involved.

#### Flow 1 — Web PGlite client: first-boot sync [protocol PROPOSED; pieces EXISTS]

```
Actor: new browser session, authenticated user, KnowMe web app

1. BOOT (INV-5, four-phase): idle → hydrating → syncing → ready
   a. PGlite opens (idb://, relaxedDurability; SharedWorker leader elected
      for multi-tab; OPFS probe → IdbFs fallback on Safari).
   b. Local migrations run (additive-only, __migrations table); schema
      fingerprint checked vs compatibility window → mismatch triggers
      reset-and-resync, never silent drift (INV-6).
   c. Lookup bundles fetched (GET /v1/lookups/{name}, ETag/304) — server-
      managed reference data, NOT synced via buckets.
2. ATTACH: app exchanges flint-gate auth token for a short-lived sync token
   (dual-JWT); opens WSS to /ws/v1/sync?token=<HMAC one-time token>.
3. SUBSCRIBE: entity-sync-core sends Subscribe{channels:
   [bucket:user-<sub>-tasks, bucket:user-<sub>-settings, doc:conv-<id>],
   resume:{bucket_lsns:{}, doc_vvs:{}}}  (first boot → empty resume).
4. SNAPSHOT: per bucket, gateway keyset-paginates SnapshotBegin →
   SnapshotBatch* → SnapshotComplete{checksum}; applyOps writes rows
   transactionally into PGlite (augmented _local_* columns maintained by
   the sync trigger; server rows never clobber _local_dirty).
5. LIVE: gateway streams Delta{ops, lsn} as WAL changes route into the
   user's buckets; client Ack{lsn} per batch; RealtimeManager coalesces
   per 16 ms frame → PEM graph → React views. SyncChip: syncing → ready.
6. PER-EVENT AUTHZ: each delta passed Keto view check at fan-out and an
   RLS re-query as the subscriber before release (INV-3); a revoked
   tuple stops flow within one cache-invalidation.
```

Failure paths: WS drop → reconnect with backoff, resume from last acked LSN; LSN gap → `SyncError::LsnGap` → bucket re-snapshot; checksum mismatch → same; token expiry → proactive refresh (timer) + one-time-token re-mint on reconnect.

#### Flow 2 — Tauri pglite-oxide: offline write → reconnect → convergence [PROPOSED]

```
Actor: desktop user edits an entity while offline (train, airplane mode)

1. OFFLINE WRITE: user saves in the React UI → Tauri command →
   gen_ui_db repository applies the row locally (PgliteServer via sqlx;
   _local_dirty=1 via trigger) → gen_ui_sync.enqueue_write(change_json)
   appends an idempotent op (client UUID) to the redb op-log
   (frf-store-redb: queue_op) → SyncChip shows "offline · 3 pending".
2. RECONNECT: pes-sdk-rust re-establishes /ws/v1/sync, sends Subscribe
   with resume cursors. Two things happen concurrently:
   a. DOWN: server deltas since last acked LSN stream in; applied to
      pglite-oxide transactionally (server rows don't clobber _local_dirty).
   b. UP: queue drains (drain_pending) — each op sent as
      Write{op: Upsert|Create|Delete, client_uuid}. Server authorizes
      twice (bucket membership; ownership — for Create, ownership is
      established from JWT claims), applies to Postgres under the origin
      RLS context, ACKs (mark_synced(confirmed_seq)).
3. CONVERGE: the write re-enters via WAL → CDC → router → bucket oplog →
   arrives as an ordinary Delta (self-echo deduplicated by client_uuid);
   _local_dirty clears when the server row lands. WAL order is the total
   order: if another device wrote the same row, last-write-wins at
   Postgres and BOTH clients converge on the server's row (INV-2).
4. POISON: an op failing with FATAL_ERROR (e.g. schema-window violation)
   moves to DEAD_LETTER with the reason surfaced in diagnostics; the
   queue continues behind it. Nothing is silently dropped or retried
   forever.
```

#### Flow 3 — Installing a WASM extension across web + mobile + desktop [PROPOSED]

```
Package: "prometheus:meeting-notes@2.1.0" — a skill (summarize notes),
an A2UI catalog fragment (NoteCard, ActionItemList), and a settings
schema (default template, retention days, BYOK provider ref = secret).

1. RESOLVE: user clicks install (or org policy pushes it). Client fetches
   the release-log head for prometheus:meeting-notes (git over HTTPS;
   LAN mirror if offline), verifies the signed tag 2.1.0, reads the
   manifest digest set.
2. FETCH: best transport selected — iroh ticket from a nearby peer →
   LAN Kubo → OCI registry. Artifact bytes verified against
   digests.wasm (sha256) [+ cross-checked blake3 for the iroh path].
3. VERIFY TRUST: signature verified (did:prometheus Ed25519 or cosign
   bundle); not_before/not_after window; yank check against the log;
   Cedar: publisher may grant the declared capabilities
   (granted = declared ∩ policy).
4. LOAD (per surface):
   - Desktop/mobile: gen_ui_plugins instantiates the component
     (wasmtime; Pulley on iOS) with fuel/epoch/StoreLimits and the
     granted capability linker.
   - Web: jco-transpiled component in a cross-origin-isolated worker
     (or Extism js-sdk); pure-data parts (A2UI catalog, settings)
     need no wasm at all.
   - Server (if the package has a server half): registered into Kiln
     via forge fn register (service_role, separate admin plane).
5. REGISTER:
   - SKILL.md → harness skill dirs (.claude/.opencode/.agents/.kimi-code/
     skills/) + gen_ui_agent's skill registry (hot-reload).
   - A2UI catalog fragment → client catalog merge; agent can now compose
     NoteCard surfaces; unknown types still fail closed.
   - Settings schema → settings service: validation active on all
     surfaces; user-scoped keys join the user's settings bucket and
     sync to all devices; the BYOK provider ref (secret scope) stores
     only a vault:// reference — the key itself never leaves keychain/
     Vault (INV-4).
6. USE: on mobile, the user opens a meeting note → local agent invokes
   the skill component (kv/db/llm calls governed per §4.5.1) → A2UI
   surface renders with the new cards → a settings change on desktop
   (retention 30→14 days) syncs via the settings bucket and applies on
     mobile within one delta round-trip.
```

#### Flow 4 — Client agent hands off to cloud agent mid-conversation [PROPOSED]

```
Actor: mobile user in a chat; turn requires a 70B model + web research

1. ROUTE: two-stage router (§4.4.2) — privacy gate: conversation contains
   no RESTRICTED entities (deterministic check against entity ACLs) →
   GENERAL; complexity: needs_tools + long context → cloud; availability:
   healthy. Path = cloud, labeled as such.
2. DELEGATE: gen_ui_agent requests an agent-role delegation token from
   flint-gate (workflow_id-scoped, short-lived); A2A message/send to the
   UAR cloud agent's card, carrying the conversation entity IDs + the
   Loro scratchpad doc's version vector (not the whole history).
3. STREAM: UAR (liter-llm picks the 70B provider; BYOK key resolved via
   Flint Vault — never in the token, never in WASM memory) emits AG-UI
   events → FRF AgentService / direct SSE → client folds them into
   ContentBlocks (provenance fields: path=cloud, model, correlation_id).
   STATE_DELTA writes go into the shared Loro doc; the local agent
   observes them (it may be streaming cheap local turns in parallel).
4. PERSIST: messages/artifacts commit to Postgres under the user's RLS
   context → CDC → bucket deltas sync to ALL the user's devices; the
   scratchpad doc merges via its doc channel.
5. RESUME/REVOKE: user backgrounds the app (iOS kills sockets) → on
   foreground, doc sync resumes from version vectors + bucket resume
   from acked LSNs + A2UI surface replay. Delegation token expires;
   Keto tuple deletion would cut the stream within one invalidation.
```

#### Flow 5 — LoRa beacon-assisted presence/version gossip [PROPOSED; field scenario]

```
Actor: two field devices (phone + ESP32 LoRa companion via BLE), off-grid

1. BEACON: each phone's gen_ui_sync periodically emits a tiny beacon over
   BLE → ESP32 bridges into the LoRa mesh (Meshtastic-class, 233B frames,
   ~1 kbps LongFast): {operator_id_hash, doc_id, version_vector_digest,
   checkpoint_lsn_hint, priority_flags}. A few messages/node/minute max.
2. DETECT: a peer's beacon shows a divergent VV digest for a shared doc
   (they edited the same field report on separate devices).
3. SCHEDULE — LoRa itself carries NOTHING more: when the devices next
   share a real transport (BLE in range, Wi-Fi, or one regains internet),
   the actual Loro export_updates_since exchange runs over that link
   (iroh/QUIC or WebRTC DataChannel), and/or both sync to the server via
   PSyncV2 when back in coverage.
4. CONVERGE: doc channels merge commutatively (Loro); any bucket-channel
   rows follow server-authoritative LWW once connectivity returns.
   LoRa's role was purely opportunistic: presence + "you are behind"
   hints — never bulk data (§4.3.5).
```

---

## 5. Functional Specification

Numbered, testable requirements. Priorities use MoSCoW (**M**ust / **S**hould / **C**ould / **W**on't-this-phase). Each requirement carries acceptance criteria phrased so a verifier agent could check them (the skill-pack's rule: every acceptance criterion must be machine-verifiable — brief: prometheus-skill-pack-inventory §4.1).

### 5.1 Sync plane (FR-SYNC)

| ID | Requirement | Pri | Acceptance criteria |
|---|---|---|---|
| FR-SYNC-001 | The FRF `SyncService` MUST authenticate every RPC: bearer extraction, JWKS identity verification, tenant-equality check — copying `grpc_service.rs`'s pattern. | **M** | Grep shows token extraction in `sync_grpc_service.rs`; unauthenticated calls return UNAUTHENTICATED; cross-tenant op push rejected in integration test |
| FR-SYNC-002 | The sync gateway MUST expose `/ws/v1/sync` (WSS, MessagePack) multiplexing bucket channels and doc channels over one connection. | **M** | Browser client completes a full Subscribe→Snapshot→Delta→Ack cycle in a headless-Chrome integration test |
| FR-SYNC-003 | PSyncV2 MUST preserve PSyncV1 semantics: SnapshotBegin/Batch/Complete with per-bucket checksums, Delta/Ack with LSN resume, Checkpoint, Keepalive, version-mismatch error 4000. | **M** | PowerSync-style test-client conformance suite passes (snapshot integrity, resume-without-redelivery, checksum mismatch → re-snapshot) |
| FR-SYNC-004 | PSyncV2 MUST add `Create` write semantics: ownership-establishing insert, server-side validation against the bucket's data-query shape, ownership assigned from JWT claims. | **M** | A client offline-creates an entity; after reconnect the row exists with `owner_id = sub`; malicious create with spoofed owner is rejected (fail-closed) |
| FR-SYNC-005 | Every client MUST maintain a durable offline write queue with states `PENDING → IN_FLIGHT → SYNCED / RETRYABLE_ERROR / FATAL_ERROR → DEAD_LETTER`; ops idempotent via client UUIDs. | **M** | Kill-network test: 50 writes queued offline, all SYNCED after reconnect in WAL order; zero duplicates after mid-drain crash (redb op-log replay) |
| FR-SYNC-006 | FATAL_ERROR ops MUST quarantine to dead-letter with operator visibility (SyncChip → diagnostics); no infinite retry, no silent drop. | **M** | Poison op surfaces in diagnostics UI with reason; queue behind it continues draining |
| FR-SYNC-007 | Writes MUST be authorized twice at the gateway: (1) entity_type ∈ authorized bucket data queries; (2) row-level ownership via resolved data query. | **M** | Negative tests: write to unauthorized entity_type rejected; write to another user's row rejected; both logged without PII |
| FR-SYNC-008 | Sync rules MUST be parameterized-only: `$1` = JWT `sub` in parameter queries; template substitution allowlist `^[a-zA-Z0-9_-]{1,128}$`; 4+ validator rules reject bad DSL at load. | **M** | Injection attempts (UNION, comments, `order_by` payloads à la CVE-2026-40906) rejected at parse/validate time |
| FR-SYNC-009 | Every bucket/shape factory MUST carry a tenant predicate; a tenantless definition is rejected at load and asserted in CI. | **M** | CI gate fails a PR that adds a tenantless sync rule (parity with `createTenantScopedElectricAdapter`) |
| FR-SYNC-010 | Doc channels MUST merge Loro deltas server-side (`frf_crdt::apply_delta`) and persist checkpoints in a durable `CrdtStore` (SurrealDB or redb — never in-memory in production). | **M** | Two clients concurrently edit a doc; both converge byte-identically; server restart loses nothing |
| FR-SYNC-011 | Per-event authorization re-check MUST run before payload release at fan-out (Keto `view` check + RLS re-query as subscriber); revocation stops flow within one cache invalidation. | **M** | Revoke-tuple test: subscriber stops receiving events ≤ 1 invalidation window; no payload released post-revocation |
| FR-SYNC-012 | Dual-JWT: sync gateway accepts short-lived sync tokens (15–60 min) minted against a flint-gate auth token; WS upgrade uses one-time HMAC tokens (replay-proof). | **M** | Expired token rejected; replayed upgrade token rejected; JWKS rotation transparent to clients |
| FR-SYNC-013 | CDC spine MUST run exactly one logical replication slot per deployment with monitored lag, `max_slot_wal_keep_size` policy, and alerting. | **M** | Ops dashboard shows slot lag; kill-consumer drill: WAL growth bounded by policy; slot invalidation alarms fire |
| FR-SYNC-014 | The Tauri client MUST sync pglite-oxide through `gen_ui_sync`/`pes-sdk-rust` natively (no `frf-ffi` detour). | **M** | Tauri demo app: offline edit → reconnect → convergence with zero Dart/TS protocol code |
| FR-SYNC-015 | The Flutter client MUST reach sync exclusively through the frb2 bridge over `pes-sdk-rust` (typed intent-level surfaces; no pure-Dart protocol client). | **M** | `grep -r "web_socket_channel" mobile/` returns nothing; FFI providers set `retry: (_, __) => null` (audit check) |
| FR-SYNC-016 | Client boot MUST follow INV-5 (migrations → seeds → sync attach) with a visible phase state machine (`idle/hydrating/syncing/ready`) and reset-and-resync on schema-window violation. | **M** | Boot-order integration test per surface; forced fingerprint mismatch triggers resync, not corruption |
| FR-SYNC-017 | Schema evolution MUST be additive-only with a recorded compatibility window; synced-column drops forbidden (rename to `_deprecated_*`). | **M** | Migration linter rejects DROP of synced columns; drift-detection CI compares server/client schema parity |
| FR-SYNC-018 | The gateway SHOULD replace 50 ms oplog polling with a push/broadcast subscribe API in `pes-oplog`. | **S** | p95 server→client delta latency < 100 ms at 1k connected clients in load test |
| FR-SYNC-019 | Multi-tenant CDC topology (channel convention `entity/changes/<tenant_id>`, router-per-tenant-group) SHOULD be documented and load-tested. | **S** | Topology doc + k6 load test evidence at target tenant count |
| FR-SYNC-020 | Electric `@electric-sql/pglite-sync` is **not** used in the primary path. | **W** | ADR records the decision; fallback runbook exists |

### 5.2 Extension plane (FR-EXT)

| ID | Requirement | Pri | Acceptance criteria |
|---|---|---|---|
| FR-EXT-001 | A `gen_ui_plugins` crate MUST host WASM components in `gen_ui_core`: wasmtime+Cranelift (desktop/Android), wasmtime+Pulley (iOS), jco/Extism (browser). | **M** | Same hello-world component runs on all four placements in CI |
| FR-EXT-002 | The client WIT world `flint:client@0.1.0` MUST mirror `flint:host@0.1.0`'s interface shapes (db/llm/kv/identity/secrets) with local bindings; platform-specific capabilities are separate interfaces. | **M** | WIT package published; a pure-compute component targets both worlds unmodified |
| FR-EXT-003 | All host runs MUST enforce fuel metering, epoch interruption, StoreLimits, and fresh-Store-per-invocation isolation. | **M** | Runaway-loop component traps at fuel limit; memory-cap test traps; two invocations share no linear memory |
| FR-EXT-004 | Capability grants MUST be computed as declared ∩ Cedar(publisher) at instantiation; client actions (`genui:component:invoke`, per-capability grants) evaluated by embedded `cedar-policy`. | **M** | Component declaring `secrets` without publisher grant runs without the secrets import linked |
| FR-EXT-005 | Secrets MUST be brokered as opaque handles; `reveal()` is Cedar-gated per-secret and audited; high-value secrets never enter WASM linear memory. | **M** | Audit log records every reveal; component memory dump (test build) contains no secret bytes |
| FR-EXT-006 | Skill components MUST be loadable from SKILL.md + component.wasm packages with hot-reload into `gen_ui_agent`'s registry. | **M** | Edit→rebuild→reload cycle without app restart; old invocation drains before swap |
| FR-EXT-007 | UI modules MUST support A2UI catalog fragments (schema + renderer bindings) with fail-closed unknown types, and HTMX fragment templates (server-driven, SSE event-as-invalidation). | **M** | Installed fragment composable by agent; unknown type renders explicit fallback; CDC event triggers fragment refresh < 500 ms |
| FR-EXT-008 | MCP Apps / remote-DOM iframe modules MAY be supported as opt-in unconstrained surfaces (sandboxed iframe, postMessage bridge). | **C** | Sandboxed module cannot read host graph state except via bridge API |
| FR-EXT-009 | WASI 0.2 worlds are the production target; WASI 0.3 tracked behind a feature flag. | **S** | Build matrix compiles both; default release ships 0.2 |
| FR-EXT-010 | iOS component delivery MUST respect App Store 2.5.2 policy: bundled base components for store builds; downloadable components gated to enterprise/TestFlight channels. | **S** | Store build contains no download path; enterprise build exercises it; policy note in release checklist |
| FR-EXT-011 | The legacy librefang raw ABI MUST NOT be used for new components. | **M** | ADR + lint rule; migration guide for existing librefang skills |
| FR-EXT-012 | Microsandbox-tier isolation (microVM) MAY be evaluated for untrusted AI-generated code. | **C** | Spike report only |

### 5.3 Packaging/distribution plane (FR-PKG)

| ID | Requirement | Pri | Acceptance criteria |
|---|---|---|---|
| FR-PKG-001 | FCP MUST be an OCI artifact with the specified config/layers/annotations media types (§4.6.2), `wkg`-compatible. | **M** | `wkg oci pull` retrieves a package; media types inspect correctly via `oras manifest fetch` |
| FR-PKG-002 | `flint-component.json` MUST bind name@version → digests (sha256 + IPFS CID + BLAKE3) → WIT world pin → capabilities → privacy class → settings schema; signed (did:prometheus or cosign). | **M** | Tampered manifest fails verification; all three digest representations verify against fetched bytes |
| FR-PKG-003 | A per-package git release-log (gitoxide-managed) MUST record init/release/yank entries as signed commits/tags. | **M** | `git log` shows append-only history; yanked version refuses new install; cached copy still runs |
| FR-PKG-004 | Clients MUST resolve best available transport (iroh peer → LAN Kubo → OCI) and verify digest + signature before load. | **M** | Airplane-mode install from LAN iroh ticket succeeds; corrupted bytes rejected at verification |
| FR-PKG-005 | IPFS mirroring MUST use Kubo HTTP API + delegated routing; integrity MUST never depend on public-DHT lookup. | **M** | Deployment pins Kubo ≥0.39; retrieval works with DHT disabled (HTTP block provider) |
| FR-PKG-006 | The flint-forge registry index (JSONB + embeddings) MUST treat Postgres rows as discovery cache only; trust root is the signed manifest + release-log. | **M** | Registry row deletion does not invalidate an already-verified local package |
| FR-PKG-007 | `package-component.sh` MUST build (wasm32-wasip2), sign, assemble, and publish a package in one command, updating the release-log. | **M** | One-command publish from template to registry + log entry |
| FR-PKG-008 | Install MUST register settings schemas, A2UI/HTMX assets, and SKILL.md into their respective services atomically (all-or-none per package version). | **M** | Interrupted install leaves no half-registered state; retry is idempotent |
| FR-PKG-009 | Update policy (prompt vs auto) SHOULD be configurable per privacy class. | **S** | `local`-class packages never auto-update; `public` can |

### 5.4 Agent plane (FR-AGENT)

| ID | Requirement | Pri | Acceptance criteria |
|---|---|---|---|
| FR-AGENT-001 | The two-stage router MUST implement deterministic privacy classification → complexity heuristic → availability circuit breaker, in that order. | **M** | Router unit tests cover the decision matrix; RESTRICTED + local-failure → honest failure label, never cloud fallback (fail-closed test) |
| FR-AGENT-002 | Every ContentBlock MUST carry per-turn provenance `{path, model, privacy_class, correlation_id}`. | **M** | UI renders provenance badge; correlation ID traces a turn across router → agent → persistence |
| FR-AGENT-003 | Client and cloud agents MUST share run state through a Loro doc channel; AG-UI STATE_DELTA semantics map onto it. | **M** | Cloud turn and local turn interleave in one doc; both sides converge; offline client resumes from VV |
| FR-AGENT-004 | Delegation MUST use flint-gate agent-role tokens (delegatable, workflow-scoped, short-lived) over A2A; UAR accessed only across a process boundary (AGPL). | **M** | No AGPL UAR code linked into client binaries (license audit in CI); delegation token expiry cuts access |
| FR-AGENT-005 | The external UI wire format MUST be Google A2UI JSONL with catalog negotiation; ContentBlock remains the canonical internal type; the serde mapping lives in `gen_ui_protocol`. | **M** | Round-trip test: A2UI JSONL → ContentBlock mutations → A2UI; catalog handshake negotiates exactly the client's declared renderers |
| FR-AGENT-006 | Internal naming MUST be disambiguated: docs refer to "gen_ui surface events"; code rename to `GenUiEvent` scheduled at next protocol-major. | **S** | `docs/corrections-2026-07-16.md` decision recorded as ADR; no new docs use bare "A2UI" for the internal protocol |
| FR-AGENT-007 | Cloud-agent state MUST persist via UAR's Postgres provider against flint-forge (same CDC spine). | **M** | Cloud turn artifacts appear in the user's bucket sync on all devices |
| FR-AGENT-008 | Local model catalog MUST be pinned/checksummed (GGUF); explicit model selection never silently falls back to another lane. | **M** | Missing model → explicit error + picker; no silent cloud escalation |
| FR-AGENT-009 | Routing decisions (not just model outputs) SHOULD be regression-tested. | **S** | Golden routing test-set in CI |

### 5.5 Settings plane (FR-SETTINGS)

| ID | Requirement | Pri | Acceptance criteria |
|---|---|---|---|
| FR-SETTINGS-001 | Settings MUST be declared as self-contained JSON Schema (no `$ref`), per-key scope ∈ {application, user, machine, machine-overridable, workspace, secret}, in the package manifest. | **M** | Manifest linter rejects `$ref`/external refs; VS Code-style subset enforced |
| FR-SETTINGS-002 | `user`-scoped settings MUST sync via per-user settings buckets with LWW-per-key merge and schema-version migrations. | **M** | Two devices set the same key; both converge to the later write; v1→v2 schema migration preserves values |
| FR-SETTINGS-003 | `secret`-scoped keys MUST store references only; values never enter sync, PEM, PGlite, Zustand, logs, URLs, or ordinary columns (INV-4). The filter applies at queue-enqueue time. | **M** | Fuzz test: no payload containing a secret value ever appears in the queue, the wire, or server logs |
| FR-SETTINGS-004 | `application`-scoped (org-managed) defaults MUST be served from flint-forge and override at read time. | **M** | Org default change propagates to all devices via bucket sync; local override only where scope permits |
| FR-SETTINGS-005 | Settings UI MUST render from the schema on web (RJSF/JSON Forms + shadcn renderer set) and Tauri, and validate identically on client (Zod v4) and server (schemars). | **M** | Same invalid value rejected on all surfaces with the same error |
| FR-SETTINGS-006 | Agents MUST be able to introspect and (policy-permitting) write settings via MCP tools. | **S** | MCP tool read/write round-trip respects Cedar policy |
| FR-SETTINGS-007 | Machine-scoped settings MUST never sync (VS Code parity). | **M** | Device-specific key absent from other devices after sync |

### 5.6 Non-functional requirements (NFR)

**Performance envelopes.**

| ID | Requirement | Target | Basis |
|---|---|---|---|
| NFR-SYNC-1 | PGlite cold start (web) | ≤ 800 ms p95 (200–800 ms observed); WASM init ≤ 200 ms | PEM research doc |
| NFR-SYNC-2 | Server→client delta latency | < 100 ms p95 at 1k clients (requires FR-SYNC-018) | FRF RFC §07 targets |
| NFR-SYNC-3 | Client apply throughput | ≥ 5k simple row ops/s into PGlite/pglite-oxide (single-connection budget honored) | pglite-oxide ~1.1–1.6× native latency |
| NFR-SYNC-4 | Per-event authz overhead | < 5 ms per Keto check p95 (cached); circuit breaker to fail-closed unavailable | flint-forge META plan targets |
| NFR-EXT-1 | WASM invocation cold start | ~0.5 ms server (ProxyPre); instance footprint ~300 KB–1 MB; 10K+ tenants/host | flint-forge sandboxing research |
| NFR-EXT-2 | Pulley (iOS) throughput | within 2–10× of Cranelift for skill-class workloads; fuel budgets tightened accordingly | wasmtime Pulley docs |
| NFR-AGENT-1 | A2UI render budget | ≤ 16 ms initial / ≤ 8 ms streaming per surface update | UAR quality gates |
| NFR-WEB-1 | Web bundle budget | PGlite ~3.5 MB gz + sync client accounted in the budget; 4 GB WASM heap ceiling respected (HNSW ~180 MB/100k vectors) | PGlite field guide |

**Security invariants.**

| ID | Requirement |
|---|---|
| NFR-SEC-1 | **Fail-closed everywhere (INV-3):** auth, signature, and availability failures deny; no silent fallback to less-checked paths (FRF fabric source, PES creates, UAR Cedar, router privacy gate). |
| NFR-SEC-2 | **Secrets never sync (INV-4)** — structural (enqueue-time filter), not conventional. |
| NFR-SEC-3 | RLS is a backstop, never the primary gate: RLS is not evaluated during WAL replication; tenancy is enforced at bucket assignment + per-event re-check. |
| NFR-SEC-4 | Parameterized-only rule surface + identifier allowlists (CVE-2026-40906 lesson). |
| NFR-SEC-5 | `service_role` keys never ship to clients; `flint_pk_` publishable keys + `agent`-role delegation tokens are the only client credentials; structured prefixes enable secret-scanning. |
| NFR-SEC-6 | Extension supply chain: signing + capability manifests + curated registry are launch requirements (36% public-skill injection rate). |
| NFR-SEC-7 | No JWTs, tenant IDs, or PII-bearing subjects in logs (flint-forge CI gate parity). |
| NFR-SEC-8 | Admin/registry write planes (Kiln control plane, package publishing) on separate listeners + separate Cedar + signing-key custody in KMS — the platform's highest-value attack targets. |

**Offline behavior.**

| ID | Requirement |
|---|---|
| NFR-OFF-1 | All reads and queueable writes work fully offline on every client surface; sync is an enhancement (§2.1). |
| NFR-OFF-2 | Durable agent loop: a crash mid-agent resumes from the pending-actions queue on next launch. |
| NFR-OFF-3 | iOS background: sockets die; resync-on-resume + doc-VV resume + push-notification wake cover it; P2P is foreground-only. |
| NFR-OFF-4 | Yanked packages remain runnable from cache; revoked *access* stops data flow within one invalidation window (these compose: local-first ownership + server-side authority). |
| NFR-OFF-5 | Thin-client fallback: a server-only mode (juit-pgproxy-style pooled Postgres-over-WS) exists for clients that should not run PGlite (the LobeChat lesson). |

---

## 6. Changes Required in the KnowMe Builder Skill Package

This section is the "what do I add to THIS project" answer: concrete new and modified files in `hybrid-mobile-architecture-src`. Everything listed becomes part of the skill package that AI harnesses consume; everything version-bearing enters `versions.toml` so `audit.sh doc-consistency` keeps authority docs honest (the repo's own anti-drift gate — brief: knowme-builder-skill-inventory §4.11).

### 6.1 New scaffolding scripts (`scripts/`)

| File | Purpose | Key behavior |
|---|---|---|
| `scripts/scaffold-sync.sh <project-dir> [--targets web,tauri,flutter]` | Add the PSyncV2 sync plane to an existing scaffolded project | Emits `infra/sync/` (sync-rules.toml + gateway config.toml + compose override for pes-server), client wiring per target: web (`entity-sync-core` + `prometheusSync` extension + four-phase boot + SyncChip), Tauri (`gen_ui_sync` crate wired to pglite-oxide + redb op-log), Flutter (frb2 bridge surface + Riverpod sync providers with `retry: (_, __) => null`). Emits augmented-table migration SQL (`_local_*` columns + sync trigger). Refuses to emit a tenantless sync rule (FR-SYNC-009 gate) |
| `scripts/scaffold-extension.sh <ext-name> --kind skill\|ui\|settings [--lang rust\|ts\|py]` | Generate a WASM component skeleton | cargo-component project targeting `wasm32-wasip2` against the flint WIT package; `wit-bindgen` glue + flint-skill-style guest SDK; `SKILL.md` (kind=skill); A2UI catalog fragment (kind=ui); settings schema (kind=settings); `flint-component.json` pre-filled; Cedar policy stub; fuel/epoch budget defaults; `// TJ-ARCH-MOB-001 compliant` header |
| `scripts/add-pglite.sh <target: web\|tauri>` | Add the embedded-Postgres data layer to an existing surface | Web: PGlite 0.4.4 + idb/OPFS detection + SharedWorker multi-tab + `__migrations` runner + lookup-bundle fetcher. Tauri: pglite-oxide 0.5.1 + `PgliteServer`→sqlx pool=1 + lifecycle contract glue (`OnceCell::get_or_try_init`, `tauri-plugin-single-instance`, advisory-lock data dir) |
| `scripts/package-component.sh <dir> [--registry oci://…] [--sign did\|cosign]` | Build, sign, assemble, publish an FCP package | `cargo component build --release`, digest set computation (sha256 + BLAKE3 + IPFS CID), manifest validation (schema, no `$ref` in settings, capability/privacy-class presence), signature (did:prometheus Ed25519 or cosign keyless), OCI assembly + `wkg`-compatible push, git release-log entry (signed tag) via gitoxide, iroh-blobs mirror ticket emission |
| `scripts/add-settings-schema.sh <feature-name> [--scopes user,machine,secret]` | Add a settings schema + registration glue to a feature | Emits `settings.schema.json` (VS Code subset), Rust `schemars` types, Zod v4 schema, bucket registration rows, RJSF form bindings |
| `scripts/sync-conformance.sh <project-dir>` | Run the PSyncV2 conformance suite | Spins the docker-compose topology (Postgres + gateway), runs the PowerSync-style test-client suite (snapshot integrity, resume, checksum mismatch, create semantics, poison quarantine, double-authz negatives) |

### 6.2 Modified scripts

| File | Change |
|---|---|
| `scripts/check-env.sh` | Add checks/installs: `rustup target add wasm32-wasip2`; `cargo-component` (pinned); `wkg` (wasm-pkg-tools); `gitoxide` CLI (`gix`) optional; `iroh` CLI optional; Kubo ≥0.39 (docs note only, server-side); `oras` for registry inspection. All pinned in `versions.toml` |
| `scripts/audit.sh` | New modes: `sync` (SyncTransport impl exists per enabled surface; boot-order invariant; FFI-provider retry rule; no `web_socket_channel` in `mobile/`; no tenantless sync rule), `extension` (FCP manifest validates; signature present; capability manifest ∩ Cedar stub; fuel/epoch budgets declared), `packaging` (release-log append-only; digests verify). `doc-consistency` extended to the seven new reference docs |
| `scripts/scaffold-rust-core.sh` | Add two crates to the layered workspace behind feature flags: `gen_ui_sync` (L2; `pes-sdk-rust` + `frf-store-redb` + `frf-crdt`; implements `SyncTransport`) and `gen_ui_plugins` (L2; wasmtime host, Pulley/Cranelift cfg matrix, Cedar embedded, StoreLimits/fuel/epoch). Refresh the commented FRF pin block to add `pes-*` crates once PES publishes (currently path/git refs — registry cadence is an open dependency, OD-13). Keep default scaffold wasm-safe and offline-resolvable |
| `scripts/new-feature.sh` | Add `--synced` flag: emits the feature plus SDL entity registration (`entity-graph-sdl` IR), bucket membership declaration, and augmented-table migration |
| `scripts/scaffold-tauri.sh` | Add `--with-sync` wiring to `gen_ui_sync` + pglite-oxide backend + SyncChip component |
| `scripts/scaffold-flutter.sh` | Add `--with-sync` wiring: frb2 sync surface + `entity_graph_flutter` transport registration + SyncChip widget |
| `scripts/add-project-skills.sh` | Include the six new project-local skills (§6.4) in the emitted set (all six harness dirs, copies not symlinks, per repo convention) |

### 6.3 New and modified reference documents (`references/`, `docs/`)

| File | Content | Status |
|---|---|---|
| `references/sync/protocol.md` | **PSyncV2 specification**: wire frames (MessagePack schemas), channel multiplexing (bucket/doc), snapshot/delta/ack/resume, create semantics, offline queue state machine, poison/DLQ, dual-JWT + HMAC WS upgrade, per-event authz re-check, conformance-suite requirements | NEW |
| `references/sync/server.md` | Gateway operations: pes-server deployment as FRF edge module, sync-rules DSL authoring, CDC topology (one slot + fan-out, `entity/changes/<tenant_id>` convention), slot hygiene, push-vs-poll tuning, fail-closed runbook | NEW |
| `references/sync/client-web.md` | PGlite attach: four-phase boot, augmented tables, `_operation_queue`, SharedWorker multi-tab, OPFS/IdbFs matrix, iOS Safari constraints, SyncChip | NEW |
| `references/sync/client-tauri.md` | pglite-oxide attach via `gen_ui_sync`/`pes-sdk-rust`; lifecycle contract; redb op-log; why not `frf-ffi` | NEW |
| `references/sync/client-flutter.md` | frb2 bridge doctrine (invariant-compliant; the pure-Dart decision record); typed event streams; SQLite+sqlite-vec applier; Riverpod retry trap | NEW |
| `references/wasm/extensions.md` | Component model doctrine: flint WIT family (`flint:host@0.1.0` / `flint:client@0.1.0` / skill world), runtime matrix (Cranelift/Pulley/jco/Extism), capability manifests + Cedar, resource limits, guest SDKs, iOS 2.5.2 policy, librefang-ABI legacy notice, UAR `uar:skill` convergence path | NEW |
| `references/packaging/fcp.md` | The FCP standard: OCI layout + media types, manifest schema, release-log format, transports (OCI/iroh/Kubo/S3/fs), digest translation, offline install, yank/revocation, update policy | NEW |
| `references/settings/model.md` | Settings model: JSON Schema subset, scopes + sync semantics, secrets-as-references, LWW-per-key + schema migrations, org-managed defaults, rendering (RJSF/shadcn), agent introspection via MCP | NEW |
| `references/transports/edge.md` | Edge transports: WebRTC adapter design (`webrtc-rs/rtc` vs str0m, signaling via FRF SignalService, mesh limits ~20–30, TURN budgeting, flutter_webrtc), iroh convergence (`FlintAdapter` over `StorageProvider`), BLE/platform-P2P, **LoRa beacon-only doctrine** (233B/1kbps, VV/checkpoint gossip, never bulk sync) | NEW |
| `references/arch-standard.md` | **MODIFY**: add decision sections — sync plane (PES-over-FRF, PSyncV2, write-path ownership), extension plane (WIT components everywhere), distribution plane (FCP), agent vocabulary (AG-UI + Google A2UI external, ContentBlock canonical), the Dart-protocol decision, the DB-matrix rationale + SurrealDB gate. Each cites this master plan |
| `references/rust/patterns.md` | **MODIFY**: add `gen_ui_sync`/`gen_ui_plugins` crate patterns (op-log lifecycle, WASM host safety, Cedar embedding), Pulley cfg guidance | MODIFY |
| `references/flutter/patterns.md` | **MODIFY**: sync provider patterns (stream providers over frb2 sync events, SyncChip states, offline-queue UI) | MODIFY |
| `references/tauri/patterns.md` | **MODIFY**: PEM-over-PSyncV2 transport registration; settings service wiring; SyncChip | MODIFY |
| `CLAUDE.md`, `AGENTS.md`, `SKILL.md` | **MODIFY**: new command reference (§6.1 scripts), new trigger terms (`psyncv2`, `sync rules`, `wasm component`, `flint component package`, `fcp`, `settings schema`, `iroh`, `wkg`, `a2ui catalog`), pointers to the new references | MODIFY |
| `docs/corrections-2026-07-16.md` (A2UI note) | **MODIFY**: supersede the open question with the OD-1 decision record once the owner rules | MODIFY |

### 6.4 New project-local skills (`templates/project-skills/`)

Six additions to the 15-skill emitted set (copied into `.claude/skills/`, `.opencode/skills/`, `.agents/skills/`, `.kimi/skills/`, `.kimi-code/skills/` per repo convention):

| Skill | Content summary |
|---|---|
| `sync-doctrine` | The invariants (INV-1…7): tenant predicates, additive migrations, four-phase boot, fail-closed, secrets never sync, one engine per concern; the write-path-ownership rationale; Electric-is-read-only warning |
| `pes-gateway-ops` | Authoring sync-rules TOML safely (parameterized-only, allowlist, validator), slot hygiene, conformance testing, dual-JWT/HMAC token flow, DLQ triage |
| `wasm-component-authoring` | Build/test/sign a flint component: cargo-component workflow, WIT world selection, capability minimization, fuel/epoch budgeting, Cedar stubs, guest SDK usage |
| `fcp-packaging` | Package/publish/mirror: `package-component.sh` workflow, release-log etiquette (signed tags, yank discipline), transport selection, offline install verification |
| `settings-schema-design` | Scope selection (`user` vs `machine` vs `secret`), schema-version migrations, org defaults, secrets-as-references, RJSF rendering |
| `edge-transports` | When to reach for WebRTC (small rooms/LAN), iroh (sovereign P2P), BLE (phone-adjacent), LoRa (beacon-only field scenarios); TURN budgeting; iOS background reality |

### 6.5 Template additions (`assets/templates/`)

| Path | Content |
|---|---|
| `assets/templates/sync/sync-rules.toml.tmpl` | Annotated bucket DSL starter (parameter queries, data queries, tenant predicate — with a lint comment that tenantless rules fail CI) |
| `assets/templates/sync/pes-gateway.config.toml.tmpl` | Gateway config (JWT/JWKS, slot/publication names, channel conventions, poll→push tuning, metrics ports) |
| `assets/templates/sync/compose.sync.yaml.tmpl` | Postgres 18 + pes-server + (optional) FRF gateway overlay for `deploy/compose.yaml` |
| `assets/templates/sync/offline-queue.sql.tmpl` | `_operation_queue` + `_local_*` augmented-table + sync-trigger DDL per dialect (pg / sqlite) |
| `assets/templates/sync/SyncChip.{tsx,dart}.tmpl` | The sync-status UI component (states: offline/hydrating/syncing/ready/pending-count/dead-letter) |
| `assets/templates/wasm-component/` | cargo-component skeleton: `Cargo.toml` (cdylib, wasm32-wasip2), `wit/` world ref, guest glue, capability manifest, Cedar stub, `clippy` config |
| `assets/templates/fcp/flint-component.json.tmpl` | The manifest with all required keys + digest/signature placeholders |
| `assets/templates/fcp/release-log.README.tmpl` | Release-log repo conventions (signed tags, yank entries, mirror setup) |
| `assets/templates/settings/settings.schema.json.tmpl` | VS Code-subset schema with scope annotations and one `secret` example |
| `assets/templates/a2ui/catalog-fragment.json.tmpl` | A2UI catalog fragment (component schema + `renderers {react, flutter, htmx}` + package overrides) |

### 6.6 Version and metadata updates

**`versions.toml` — new pins:**

```toml
[sync]
pes = "0.1.0"                # prometheus-entity-sync; PSyncV2 target 0.2.0
frf_rev = "9ba04ae6ce41be796ae149609414b17a0d0d376b"  # flint-realtime-fabric
loro = "1.13"                # matches frf-crdt 1.13.1
pg_walstream = "0.6"
pglite = "0.4.4"             # web embedded Postgres (Apache-2.0)

[wasm]
wasmtime = "46"              # matches flint-forge fke-runtime
cargo_component = "0.21.x"
wkg = "latest"               # bytecodealliance/wasm-pkg-tools
wasm_target = "wasm32-wasip2"
jco = "1.24.x"
extism_cli = "1.6.2"

[edge]
iroh = "1.0.0-rc"            # pin; wrap behind internal trait (0.x churn)
iroh_blobs_prod = "0.35"     # per crates.io production caveat
gix = "0.55"
flutter_webrtc = "1.4.1"
webrtc_rs = "0.x-pinned"     # pre-1.0 semver caution
str0m = "0.21.0"             # matches FRF
kubo = ">=0.39"              # Provide Sweep default
```

**Marketplace/registry metadata (MODIFY):** `SKILL.md` frontmatter (trigger terms += the §6.3 list), `plugin.json`, `marketplace.json`, `.claude-plugin/{plugin,marketplace}.json`, `.agents/plugins/` listing — all gain the sync/extension/packaging capability statements. `site/` Docusaurus docs gain a section per new reference (the public docs pipeline must regenerate, not hand-edit HTML per repo rules).

**Governance:** `AGENT_BASE_RULES.md` needs no change (Rule 12 already prefers MCP, A2UI/AG-UI, WASM, PostgreSQL-compatible storage, IPFS-compatible distribution — this plan is that rule's implementation). New OpenSpec changes enter `openspec/changes/` per repo convention (one per phase in §7, following the c106/c109 precedent). `.prometheus/` session logs and wiki updates commit with the work (standing authorization).

### 6.7 What this package must NOT grow

- **No sync engine implementation in the skill repo itself** — the engine lives in PES/FRF/`gen_ui_core` scaffolds; this package teaches and scaffolds it (the repo is a skill package, not an application).
- **No second protocol vocabulary** — scaffolds emit AG-UI/A2UI alignment; they must not re-invent wire formats.
- **No pure-Dart sync client template** — explicitly blocked by the Dart decision (OD-2c); `scaffold-sync.sh` emits the frb2 bridge only.
- **No Electric-primary path** — recorded as fallback (FR-SYNC-020, Won't-this-phase).

---

## 7. Project Plan

Seven phases. Sequencing respects hard dependencies (Phase 0 gates everything); within phases, the layered workspace (L0 traits → L2 impls → leaves) is designed for parallel worktrees (brief: knowme-builder-skill-inventory §3.6). Effort figures are rough senior-engineer estimates for scope as specified — treat as planning baselines, not commitments.

Development-philosophy constraints honored throughout: **features first, clippy-driven inner loop** (`cargo clippy` only, never alternating `cargo check`; `bacon clippy` continuous), trait seams land in `gen_ui_types`-equivalent L0 crates first so crates develop concurrently, tests come after features are complete and exercised end-to-end (3–5 behavior tests per feature at public boundaries, `insta` snapshots preferred, one integration binary per crate), two failed attempts on the same test → stop and report.

### Phase 0 — Security & consolidation foundations (2–3 weeks)

**Goal:** close the defects that gate any production sync topology; land the decision records.

| Item | Detail |
|---|---|
| FRF `SyncService` authentication | bearer extraction + identity verify + tenant-equality, copied from `grpc_service.rs` (FR-SYNC-001) |
| `/ws/v1/sync` WS route | JSON/MessagePack-framed WS driving the same sync use-case (precedent: `/ws/v1/signal` p23-c003) |
| `WatchEntityType` RPC (OQ-FRF-1) | unblocks Forge `FabricChangeSource` (currently fails closed) |
| Durable CRDT stores by default | wire `SurrealCrdtStore` (or redb) — in-memory defaults banned in production wiring |
| ADRs | gateway consolidation (OD-2), Dart strategy (OD-2c), A2UI naming (OD-1), envelope-vs-columnar (OD-4) |

- **Entry:** owner signs off on this plan's §9 recommendations (or records alternates).
- **Exit (machine-verifiable):** unauthenticated SyncService call → UNAUTHENTICATED; browser completes a sync cycle over `/ws/v1/sync`; Forge fabric source streams events end-to-end; gateway restarts lose no CRDT state; four ADRs merged.
- **Depends on:** nothing. **Blocks:** Phases 1–6.
- **Effort:** 2–3 wks (1 senior engineer, FRF-focused).

### Phase 1 — PSyncV2 core + web client (4–6 weeks)

**Goal:** the unified protocol, the offline write queue, and the first production client (web PGlite).

| Item | Detail |
|---|---|
| `pes-protocol` v2 | channel multiplexing (bucket/doc), `Create`, resume with per-doc VVs, queue ACKs, poison codes |
| Gateway evolution | push/broadcast in `pes-oplog` (kill the 50 ms poll), double-authz unchanged, doc-channel server merges, durable store default |
| Client queue (web) | `_operation_queue` in PGlite + state machine + DLQ + idempotent ops; PEM replay reconciliation (one queue, not two) |
| TS client evolution | `@prometheus-ags/entity-sync-core` → PSyncV2; `entity-sync-pglite` applier with client-side Loro merge (frf-wasm or loro-crdt) |
| Conformance suite | PowerSync-test-client-style suite + CI (FR-SYNC-003…) |
| Dual-JWT | flint-gate sync-token minting; HMAC one-time WS tokens |

- **Entry:** Phase 0 exit. **Exit:** two-browser-tab bidirectional sync with per-user isolation (the PES umbrella criterion); offline create → reconnect → convergence demo; conformance suite green in CI; injection negatives (CVE-2026-40906 class) rejected.
- **Depends on:** Phase 0. **Blocks:** Phases 2, 3, 4.
- **Effort:** 4–6 wks (2 engineers: protocol/server, web client).

### Phase 2 — Native clients: Tauri + Flutter (4–6 weeks)

**Goal:** `pes-sdk-rust` completed once, consumed twice (Tauri native, Flutter via frb2).

| Item | Detail |
|---|---|
| `pes-sdk-rust` | complete the 1-line stub: WS+MessagePack client, reconnect/backoff, proactive JWT refresh, resume from acked LSN/doc VV |
| `gen_ui_sync` crate | `SyncTransport` impl over pes-sdk-rust + redb op-log + frf-crdt; pglite-oxide applier (sqlx); SQLite+sqlite-vec applier (mobile dialect) |
| Tauri wiring | `gen_ui_sync` in Tauri backend; SyncChip; `entity-sync-tauri` becomes real (or is superseded by gen_ui_sync — record in ADR) |
| Flutter wiring | frb2 surface (typed streams; retry:null providers); `entity_graph_flutter` transport registration; SyncChip widget |
| Multi-surface demo | one entity type synced across web + desktop + mobile with offline edits on each |

- **Entry:** Phase 1 exit. **Exit:** the three-surface demo passes with airplane-mode segments on mobile and desktop; `grep web_socket_channel mobile/` empty; clippy `-D warnings` clean; 3–5 public-boundary behavior tests per crate.
- **Depends on:** Phase 1. **Blocks:** Phase 3 (settings buckets ride the same client stack).
- **Effort:** 4–6 wks (2 engineers: Rust core, Flutter surface) — parallelizable with Phase 3 if staffing allows.

### Phase 3 — Settings plane (3–4 weeks)

**Goal:** VS Code-style settings schemas with synced client/server storage.

| Item | Detail |
|---|---|
| Settings service | `(extension_id, scope, key)` tables per surface; scope semantics; LWW-per-key; schema-version migrations |
| Sync integration | per-user settings bucket; org-managed defaults bucket (application scope); enqueue-time secret filter (INV-4) |
| Schema tooling | manifest schema linter (no `$ref`), schemars emission, Zod v4 emission, RJSF + shadcn renderer set |
| Agent introspection | MCP read/write tools with Cedar gates |
| Docs + skill | `references/settings/model.md`, `settings-schema-design` project skill, `add-settings-schema.sh` |

- **Entry:** Phase 1 exit (buckets exist). **Exit:** FR-SETTINGS-001…007 acceptance criteria green; the config-DB (`providers`, `model_prefs`, `app_settings`) migrated onto the model without data loss; secret-fuzz test clean.
- **Depends on:** Phase 1. **Blocks:** Phase 4 (component settings registration).
- **Effort:** 3–4 wks (1–2 engineers).

### Phase 4 — Extension plane (5–7 weeks)

**Goal:** WASM components running on all four placements with the three component kinds.

| Item | Detail |
|---|---|
| `flint:client@0.1.0` WIT | interface-shape parity with `flint:host@0.1.0`; local bindings |
| `gen_ui_plugins` host | wasmtime Cranelift/Pulley cfg matrix; fuel/epoch/StoreLimits; Cedar embedded; capability linker |
| Browser lane | jco-transpile path + Extism fallback; cross-origin isolation; worker+SAB bridging |
| Component kinds | skill registration into `gen_ui_agent`; A2UI catalog merge (fail-closed); settings registration (Phase 3 service) |
| Convergence | `uar:skill@0.1.0` → flint skill world mapping; librefang deprecation ADR |
| Tooling | `scaffold-extension.sh`, `wasm-component-authoring` skill, `references/wasm/extensions.md` |

- **Entry:** Phases 1, 3 exit. **Exit:** one real component (e.g. a markdown ContentBlock skill with settings + A2UI fragment) runs on web/desktop/iOS-sim/server with identical manifest; capability-negative tests pass; fuel-limit trap tests pass.
- **Depends on:** Phases 1, 3. **Blocks:** Phase 5 (you must be able to run a package to distribute it).
- **Effort:** 5–7 wks (2 engineers: Rust host, browser lane).

### Phase 5 — Distribution plane (4–5 weeks)

**Goal:** FCP end-to-end — build, sign, publish, mirror, install offline.

| Item | Detail |
|---|---|
| `package-component.sh` | build/sign/assemble/push + release-log entry (§6.1) |
| Release-log infra | gitoxide-managed per-package logs; signed tags; yank semantics; mirror tooling |
| Transport mirrors | iroh-blobs ticket emission (pinned prod line); Kubo ≥0.39 mirroring with delegated routing; digest translation tooling (sha256↔CID↔BLAKE3) |
| Registry index | flint-forge JSONB + embeddings index over manifests (extends A2UI registry model); discovery API |
| Client install | resolve → verify → fetch → load → atomic registration (FR-PKG-004/008); update policy per privacy class |
| Docs + skill | `references/packaging/fcp.md`, `fcp-packaging` project skill |

- **Entry:** Phase 4 exit. **Exit:** airplane-mode install from LAN iroh ticket; yanked version refuses new install but cached copy runs; one-command publish from template to registry + log; registry-row deletion doesn't invalidate verified local packages.
- **Depends on:** Phase 4. **Effort:** 4–5 wks (1–2 engineers).

### Phase 6 — Edge transports (4–6 weeks)

**Goal:** the P2P/beacon layer — strictly after the backbone is proven.

| Item | Detail |
|---|---|
| `frf-sync-webrtc` | DataChannel sync adapter over webrtc-rs/rtc; FRF SignalService signaling; admission via gate JWTs; chunking; flutter_webrtc integration |
| iroh convergence | `FlintAdapter` (`StorageProvider` over FRF channels); sovereign-sync end-to-end wiring (un-stub the MCP/REST sync tools); privacy-class naming reconciliation |
| BLE adapter | `PeerSyncTransport` over platform P2P APIs (MultipeerConnectivity/Nearby Connections) |
| LoRa beacon PoC | ESP32 companion bridge; VV/checkpoint gossip only; field demo |
| Docs + skill | `references/transports/edge.md`, `edge-transports` project skill |

- **Entry:** Phase 2 exit (clients stable). **Exit:** two phones sync a doc over WebRTC with internet disabled (LAN); iroh-docs ticket sync between desktop and laptop; LoRa demo shows beacon → scheduled real sync; TURN fallback documented with cost model.
- **Depends on:** Phase 2. **Effort:** 4–6 wks (1–2 engineers).

### Risk register

| # | Risk | Class | Likelihood | Impact | Mitigation |
|---|---|---|---|---|---|
| R-1 | **License traps**: PowerSync service FSL-1.1-ALv2; UAR AGPL-3.0-only; Triplit AGPL; DXOS FSL; RxDB premium features | License | High (if unexamined) | High | PES is MIT and independent of PowerSync code (already established); UAR only across process boundary / MIT SDKs; CI license audit (`cargo deny` parity); no Triplit/DXOS deps |
| R-2 | str0m sovereign SFU stall (12+ phases, decode never proven, gated OFF) | Technical | High | Medium | Media stays on LiveKit-hosted; DataChannel adapter uses webrtc-rs/rtc, not the SFU path; treat str0m as stretch |
| R-3 | Pulley interpreter performance on iOS (2–10× slower; 2025 advisories) | Technical | Medium | Medium | Skill components designed coarse-grained; AOT `.cwasm` where policy allows; budget fuel tighter; benchmark gate in Phase 4 exit |
| R-4 | PGlite single-connection + resource footprint (3.5 MB gz, 200–800 ms cold start, 4 GB heap; LobeChat reversal) | Technical/Product | Medium | High | Application-layer write queue; bundle/memory budgets (NFR-WEB-1); thin-client server-only fallback mode from day one (juit-pgproxy pattern); measure real usage before expanding PGlite surface |
| R-5 | Per-event Keto authz at fan-out doesn't scale (RFC §07 hazard, no load-test evidence) | Technical | Medium | High | Subscribe-time scoping, check-cache with tuple-delete invalidation, topic partitioning; Phase 1 load test with NFR-SYNC-4 gate; circuit breaker fails closed |
| R-6 | **"Five-engine DB matrix overbuilt"** (assessment flag) | Architecture | Medium | Medium | Addressed by design (§4.1): the four relational tiers are per-surface *necessities* (each is the only viable embedded option per target), and the repository trait is the single seam — the matrix is breadth of *backends*, not breadth of *code paths*. SurrealDB (the true fifth engine) is optional, benchmark-gated, with a named fallback (sqlite-vec + FTS5 + recursive CTEs) and is never on the sync critical path. Review gate at Phase 2 exit: if SurrealDB embedded misses its benchmark, the fallback ships and SurrealDB is removed from mobile |
| R-7 | SurrealDB embedded production-readiness (3.0 regressions #6800/#5541) | Technical | Medium | Medium | Same gate as R-6; intent-level FFI contains the blast radius |
| R-8 | `uniffi-bindgen-dart` async ABI blockage | Technical | High (already true) | Low | Irrelevant under the Dart decision — Flutter uses frb2 over `pes-sdk-rust`; the UniFFI Dart binding is simply not consumed (OD-2c) |
| R-9 | iroh 0.x API churn; iroh-blobs production caveat; n0 relay/discovery sovereignty | Technical | Medium | Medium | Pin versions; wrap behind internal trait; prod line pins (0.35); run own relay/discovery; Phase 6 scope isolation |
| R-10 | Replication slot hygiene (phantom slot → disk full) | Operational | Medium | High | NFR/FR-SYNC-013 monitoring + `max_slot_wal_keep_size` policy + failover slots (PG17); ops runbook in `references/sync/server.md` |
| R-11 | iOS App Store 2.5.2 (downloaded executable code) | Policy | Medium | Medium | Bundled base components for store builds; downloadable components in enterprise/TestFlight channels; data-driven modules (A2UI/settings) unrestricted (FR-EXT-010) |
| R-12 | Skill supply-chain attacks (36% public-skill injection rate; SkillsBench 6.2/12 avg quality) | Security | High | High | Signing + capability manifests + Cedar + curated registry as launch requirements (NFR-SEC-6); verifier/critic agents pattern for review; no unsandboxed script execution from packages |
| R-13 | Public-DHT Sybil/eclipse attacks on IPFS plane | Security | Medium | Medium | Delegated routing + pinned mirrors + HTTP retrieval; integrity from digests/signatures, never from DHT lookup (FR-PKG-005) |
| R-14 | Iggy fork risk (`GQAdonis/iggy@master`, pre-1.0 upstream) | Supply | Low-Med | Medium | `LogBroker` port keeps NATS/Redpanda a compile-time swap |
| R-15 | WASI 0.3 / Component Model 1.0 churn through ~2027 | Standards | Medium | Low | Target 0.2 worlds; 0.3 behind feature flag; wasmtime version recorded in AOT cache keys |
| R-16 | Two PEM↔FRF adapter paths diverge (flint.ts vs PES) | Architecture | Medium | Medium | OD-3 decision in Phase 0 ADR; deprecation path recorded |
| R-17 | pglite-oxide fragility (0.5.1 unverified host on PGlite's moving target; required an exact `virtual-net` alpha pin) | Supply | Medium | Medium | Pin exactly; upstream-watch duty in bridge-ownership role; `rusqlite`-fallback feature documented but not primary |
| R-18 | Market thesis unvalidated (sovereign-AI premium demand) | Product | — | — | Out of scope for this document; flagged from assessment §3.7 for the owner's business review |

### Sequencing summary

```
Phase 0 (2–3w) ──┬──▶ Phase 1 (4–6w) ──┬──▶ Phase 2 (4–6w) ──▶ Phase 6 (4–6w)
                 │                     ├──▶ Phase 3 (3–4w) ──▶ Phase 4 (5–7w) ──▶ Phase 5 (4–5w)
                 │                     └── (Phases 2+3 parallel-staffable)
Serial path: ~26–37 engineer-weeks. With 2 parallel workstreams from Phase 1
onward: ~two calendar quarters to full scope (web+desktop+mobile sync,
settings, extensions, FCP distribution, edge transports).
```

---

## 8. Research Bibliography

Consolidated external sources cited by the ten briefs (all accessed 2026-07-18 unless a different date is shown), grouped by topic. Only links that appear in the briefs are included. Local-repo source paths are indexed in each brief's own appendix.

### 8.1 Local-first engines & landscape

- Electric 1.0 GA — https://electric.ax/blog/2025/03/17/electricsql-1.0-released (2025-03-17)
- Electric agent-platform pivot — https://electric.ax/ (accessed 2026-06-26); repo https://github.com/electric-sql/electric
- Electric Postgres Sync primitives — https://electric-sql.com/primitives/postgres-sync (2025-08-13)
- Electric shapes docs — https://electric-sql.com/docs/guides/shapes
- Electric write model ("read-path only") — https://electric.ax/docs/sync/guides/writes
- Electric production/authz proxy pattern — https://neon.com/guides/electric-sql
- Electric + TanStack DB — https://electric.ax/blog/2025/07/29/super-fast-apps-on-sync-with-tanstack-db (2025-07-29); https://tanstack.com/db/latest
- Electric ↔ LiveStore integration — https://electric-sql.com/docs/integrations/livestore (2026-04-20)
- electric-next announcement (write-path dropped) — electric-sql.com/blog (2024-07-17)
- Deprecated Electric Dart client — https://pub.dev/documentation/electricsql/latest/
- PowerSync v1.0 — https://powersync.com/blog/introducing-powersync-v1-0-postgres-sqlite-sync-layer (2023-11-29)
- PowerSync 2025 roadmap update — https://powersync.com/blog/2025-powersync-roadmap-update (2026-01-05)
- PowerSync service changelog — https://releases.powersync.com/announcements/powersync-service (v1.23.2, 2026-07-02)
- PowerSync Nov 2025 changelog — https://powersync.com/blog/powersync-changelog-november-2025 (2025-12-04)
- PowerSync June 2025 update (Rust client core) — https://powersync.com/blog/powersync-update-june-2025 (2025-07-07)
- PowerSync logical-replication challenges — https://powersync.com/blog/postgres-logical-replication-challenges-solutions (2024-05-08)
- PowerSync local-first talk (PostgresConf) — https://postgresconf.org/system/events/document/000/002/237/2024-04_Local-first_apps_using_logical_replication.pdf (2024-04)
- PowerSync vs Ditto — https://powersync.com/blog/ditto-vs-powersync (2025-01-28)
- PowerSync vs Electric — https://powersync.com/blog/electricsql-vs-powersync
- QueryPlane PowerSync review — https://queryplane.com/blog/powersync-offline-first-sync/ (2026-02-07)
- Zero docs — https://zero.rocicorp.dev/ ; https://zero.rocicorp.dev/docs/when-to-use ; https://zero.rocicorp.dev/docs/sync
- Zero review (marmelab) — https://marmelab.com/blog/2025/02/28/zero-sync-engine.html (2025-02-28)
- rocicorp/mono repo — https://github.com/rocicorp/mono
- LiveStore — https://github.com/livestorejs/livestore ; https://docs.livestore.dev/ ; S2 provider https://s2.dev/docs/integrations/livestore
- InstantDB architecture essay — https://www.instantdb.com/essays/architecture (2026-04-09); repo https://github.com/instantdb/instant
- Jazz — https://jazz.tools/blog/what-is-jazz (2026-04-18); repo https://github.com/garden-co/jazz
- Triplit — https://github.com/aspen-cloud/triplit
- Evolu — https://www.evolu.dev/ ; https://github.com/evoluhq/evolu
- DXOS — https://dxos.org/ ; https://github.com/dxos/dxos
- Ditto Flutter/P2P — https://www.ditto.com/blog/cross-platform-development-with-flutter-just-got-better (2025-04-01); docs https://docs.ditto.live/
- cr-sqlite — https://github.com/vlcn-io/cr-sqlite (dormant since 2024-10-25)
- RxDB — https://github.com/pubkey/rxdb
- TinyBase — https://github.com/tinyplex/tinybase
- WatermelonDB — https://github.com/Nozbe/WatermelonDB
- Supabase Realtime — https://github.com/supabase/realtime ; blog index https://supabase.com/blog/tags/realtime (Broadcast from DB 2025-04-02; Replay 2025-12-05)
- Supabase ETL/Pipelines — https://github.com/supabase/etl ; https://supabase.com/blog/introducing-supabase-pipelines (2025-12-02); https://www.definite.app/blog/supabase-etl (2026-06-12)
- Supabase architecture docs — supabase.com/docs (accessed via repo docs 2026-07-17)
- Choosing a sync engine in 2026 (practitioner) — https://johnny.sh/blog/choosing-a-sync-engine-in-2026/ (2026-03-09)
- Local-first 2026 overview — https://www.birjob.com/blog/local-first-software-2026 (2026-05-15)
- Local-First News — https://www.localfirstnews.com/2025-11-20/ (2025-11-20)
- localfirst.fm landscape — https://www.localfirst.fm/landscape/tinybase
- awesome-local-first — https://github.com/alexanderop/awesome-local-first (2025-01-06)
- youngju.dev realtime-collaboration deep dive — https://www.youngju.dev/blog/culture/2026-05-16-realtime-collaboration-engines-sync-2026-liveblocks-partykit-yjs-automerge-electricsql-replicache-zero-jazz-tools-deep-dive (2026-05-16)
- Why CRDTs are gaining ground — https://byteiota.com/local-first-software-why-crdts-are-gaining-ground/ (2026-04-08)
- Electric Cloud vs PowerSync Cloud — https://zairalabs.ai/guide/compare/electricsql-cloud-vs-powersync-cloud/ (verified 2026-06-10)
- Local-first licensing watch: PowerSync FSL — https://powersync.com/legal/fsl ; https://powersync.com/open-source ; https://powersync.com/blog/powersync-supports-fair-source (2024-08-06); powersync-service LICENSE https://github.com/powersync-ja/powersync-service ; SPDX FSL-1.1-ALv2 discussion https://github.com/spdx/license-list-XML/issues/2459

### 8.2 PGlite & embedded Postgres

- PGlite docs — https://pglite.dev/docs/about ; product page https://electric.ax/sync/pglite ; repo https://github.com/electric-sql/pglite
- PGlite sync docs — https://pglite.dev/docs/sync
- `@electric-sql/pglite` 0.4.4 — https://npmx.dev/package/@electric-sql/pglite/v/0.4.4 (2026-04-09)
- `@electric-sql/pglite-sync` releases — https://github.com/electric-sql/pglite/releases (0.6.3, 2026-06-16); usage https://www.npmjs.com/package/@electric-sql/pglite-sync
- pglite-oxide — https://docs.rs/pglite-oxide (2026-05-03 snapshot); https://github.com/f0rr0/pglite-oxide (crates.io v0.5.1, 2026-06-04)
- pglite-rust-bindings (alt experiment) — https://github.com/kshcherban/pglite-rust-bindings

### 8.3 CRDT libraries

- Loro 1.0 announcement — https://loro.dev/blog/v1.0 (2026-06-15); repo https://github.com/loro-dev/loro ; org activity https://github.com/orgs/loro-dev/repositories (Jun 2026)
- Yjs vs Automerge vs Loro 2026 comparison — https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026 (2026-04-12)
- `loro-crdt` npm — https://npmx.dev/package/loro-crdt (2026-06-21)
- Automerge 3.0 — https://automerge.org/blog/automerge-3/ ; Ink & Switch dispatch — https://www.inkandswitch.com/newsletter/dispatch-011/ (2025-05-23); repo https://github.com/automerge/automerge (crate 0.10.0, 2026-06-05)
- automerge-repo — https://automerge.org/blog/automerge-repo/
- Yjs — https://github.com/yjs/yjs ; Yrs — https://docs.rs/yrs (0.27.3, 2026-07-13); y-crdt parity table https://github.com/y-crdt/y-crdt ; y-sync archived https://github.com/y-crdt/y-sync
- Loro↔Yjs wire-protocol migration spec — https://github.com/kryptobasedev/llmtxt/blob/main/docs/specs/P1-loro-migration.md (2026-03-09)

### 8.4 Postgres CDC & replication

- pg_walstream — https://docs.rs/pg_walstream (2026-07-01)
- CDC slots/plugins deep-dive — https://pipecode.ai/blogs/postgresql-logical-replication-cdc-slots-publications (2026-06-30)
- Logical-decoding plugin comparison — https://www.stacksync.com/blog/postgresql-logical-decoding-plugins-developers-guide (2025-09-06)
- Logical replication in practice — https://queryplane.com/blog/postgres-logical-replication-in-practice/ (2026-05-05)
- Debezium/pgoutput context — https://github.com/pathwaycom/pathway/issues/186 (2026-02-06)

### 8.5 WebRTC / P2P / edge transports

- y-webrtc — https://github.com/yjs/y-webrtc
- Yjs ProseMirror P2P demo + mesh-scaling caveat — https://discuss.prosemirror.net/t/offline-peer-to-peer-collaborative-editing-using-yjs/2488 (2020-01-27)
- Tag1 "Signaling servers and y-webrtc" — https://www.tag1.com/blog/signal-y-webrtc-part2/ (2020-03-17)
- Trystero — https://github.com/dmotz/trystero ; releases https://github.com/dmotz/trystero/releases (0.23.x, 2026-03-23); site https://trystero.dev/ (2026-05-04)
- y-webrtc-trystero bridge — https://github.com/WinstonFassett/y-webrtc-trystero
- automerge-repo-network-websocket wire protocol — https://www.npmjs.com/package/@automerge/automerge-repo-network-websocket (2026-03-31)
- automerge-repo-network-peerjs — https://github.com/automerge/automerge-repo-network-peerjs
- TURN/STUN guide — http://videosdk.live/developer-hub/stun-turn-server/what-is-turn-server (2025-07-10)
- Firefox WebRTC 2025 (dcsctp rework) — https://blog.mozilla.org/webrtc/firefox-webrtc-2025/ (2026-01-13)
- webrtc-rs/rtc — https://github.com/webrtc-rs/rtc (2026-02-08); https://webrtc.rs/
- str0m — https://docs.rs/str0m (2026-07-01); review https://www.linuxlinks.com/str0m-sans-io-webrtc-implementation/ (2025-05-02)
- flutter_webrtc — https://pub.dev/packages/flutter_webrtc (1.4.1, 2026-03); https://fluttergems.dev/packages/flutter_webrtc/ (2026-05-18); GetStream fork changelog https://github.com/GetStream/webrtc-flutter/blob/main/CHANGELOG.md
- libp2p-gossipsub — https://crates.io/crates/libp2p-gossipsub (2026-03-26)
- Malachite libp2p validation — https://github.com/circlefin/malachite/discussions/1119 (2025-07-04)
- agntcy/dir v0.4.0 — https://github.com/agntcy/dir/blob/main/CHANGELOG.md (2025-10-15)
- Vac gossipsub perf program — https://roadmap.vac.dev/p2p/ift/2025q1-gossipsub-perf-improvements
- libp2p browser WebRTC — https://libp2p.io/docs/webrtc-browser-connectivity/ (2026-03-13); https://crates.io/crates/libp2p-webrtc-websys (2025-01-15)
- iroh — https://github.com/n0-computer/iroh ; https://docs.rs/iroh ; iroh-blobs https://lib.rs/crates/iroh-blobs
- iroh-docs — https://docs.rs/iroh-docs/latest/iroh_docs/ (0.95.0, 2026-01-03); https://github.com/n0-computer/iroh-docs ; https://www.iroh.computer/proto/iroh-docs ; set-reconciliation paper arXiv:2212.13567
- iroh examples (browser WASM, tauri-todos, iroh-automerge/samod) — https://lib.rs/crates/iroh-pkarr-node-discovery ; iroh-loro PR https://github.com/n0-computer/iroh-examples/pull/132 (2025-09-05)
- Distribits iroh talk — https://www.distribits.live/talks/2025/bruynooghe-iroh-p2p-quic-transport-and/ (2025-10-24)
- lora-rs — https://github.com/lora-rs/lora-rs (updated 2025-11-27); lora-packet-rs https://github.com/tago-io/lora-packet-rs (2026-05-21)
- Meshtastic presets/data rates — https://meshtastic.org/blog/why-your-mesh-should-switch-from-longfast/ (2025-04-22); Meshtasticator modem table https://meshtastic.org/docs/software/meshtasticator/discrete-event-sim/
- Meshtastic 233-byte payload cap — https://github.com/things-nyc/lwom (2025-12-19)
- BitChat-over-LoRa whitepaper — https://github.com/permissionlesstech/bitchat/issues/180 (2025-07-11)
- MeshCore vs Meshtastic — https://www.austinmesh.org/learn/meshcore-vs-meshtastic/ ; https://ryanmalloy.com/protocols/meshcore (2026-02-01)

### 8.6 WASM component model & runtimes

- WASI spec hub — https://wasi.dev/ ; WASI repo https://github.com/webassembly/wasi
- Component Model docs — https://component-model.bytecodealliance.org/
- State of WebAssembly 2026 — https://wasmhub.dev/blog/state-of-webassembly-2026 (2026-06-16)
- Uno Platform state of WASM 2025–2026 — https://platform.uno/blog/the-state-of-webassembly-2025-2026/ (2026-01)
- Fermyon "What's The State of WASI?" — https://dev.to/fermyon/whats-the-state-of-wasi-2ofl (2025-05-16)
- JavaCodeGeeks WASM 2026 — https://www.javacodegeeks.com/2026/04/webassembly-in-2026-where-it-has-landed-what-wasi-0-2-changes-and-why-java-and-kotlin-developers-should-pay-attention-now.html (2026-04-27)
- JavaCodeGeeks Component Model LEGO — https://www.javacodegeeks.com/2026/02/the-wasm-component-model-software-from-lego-bricks.html (2026-02-25)
- WASI-native tunneling (roadmap accuracy) — https://dev.to/instatunnel/no-install-no-risk-the-rise-of-webassembly-native-tunneling-16b8 (2026-04-04)
- WASI security model 2025 — https://safeguard.sh/resources/blog/webassembly-wasi-security-model-2025 (2025-11-05)
- WASI/Component Model status — https://eunomia.dev/blog/2025/02/16/wasi-and-the-webassembly-component-model-current-status/ (2025-02-28)
- Wasmtime minimal embedding — https://docs.wasmtime.dev/examples-minimal.html (2024-12-12); docs https://docs.wasmtime.dev/
- Wasmtime v29 release notes (Pulley default) — https://newreleases.io/project/github/bytecodealliance/wasmtime/release/v29.0.0 (2025-01-20)
- Pulley security hardening — https://www.systemshardening.com/articles/wasm/wasmtime-pulley-interpreter-security/ (2026-05-08)
- pulley-interpreter crate — https://lib.rs/crates/pulley-interpreter
- WAMR — https://github.com/bytecodealliance/wasm-micro-runtime
- Runtime choices for embedded wasm — https://withbighair.com/webassembly/2025/05/11/Runtime-choices.html (2025-05-11)
- Extism — https://github.com/extism/extism ; https://extism.org ; Helm HIP-0026 https://helm.sh/community/hips/hip-0026/ ; embedding example https://thejeshgn.com/2026/05/19/embedding-user-code-in-your-app-using-extism/ (2026-05-19)
- wasmCloud — https://wasmcloud.com/ ; Q1 2025 roadmap https://wasmcloud.com/community/2025-01-15-community-meeting/ ; Q2 2026 roadmap discussion https://github.com/wasmCloud/wasmCloud/discussions/5026 (2026-04-03); WIT package mgmt update https://wasmcloud.com/blog/2024-11-08-update-to-wit-package-management-in-wasmcloud/ (2024-11-08)
- microsandbox — https://github.com/microsandbox/microsandbox
- Supabase edge-runtime (Deno, not WASM) — https://github.com/supabase/edge-runtime
- Akamai acquires Fermyon — https://devclass.com/2025/12/04/akamai-acquires-fermyon/ (2025-12)
- VS Code wasm blogs — https://code.visualstudio.com/blogs/2023/06/05/vscode-wasm-wasi ; https://code.visualstudio.com/blogs/2024/05/08/wasm
- Zed "Life of an Extension" — zed.dev/blog (2024)

### 8.7 Registries, packaging & decentralized distribution

- warg registry (archived 2025-07-28) — https://github.com/bytecodealliance/registry ; warg.io
- wa.dev publishing walkthrough — https://zenn.dev/mizchi/articles/wasm-component-wadev?locale=en (2025-12-28)
- wasm-pkg-tools / wkg — https://github.com/bytecodealliance/wasm-pkg-tools
- Microsoft: distributing components via OCI — https://opensource.microsoft.com/blog/2024/09/25/distributing-webassembly-components-using-oci-registries/ (2024-09-25)
- IPFS Shipyard 2025 year in review — https://ipshipyard.com/blog/2025-shipyard-ipfs-year-in-review/ (2025-12-19)
- rust-ipfs (archived 2022-10-23) — https://github.com/rs-ipfs/rust-ipfs ; status thread https://discuss.ipfs.tech/t/status-of-rust-ipfs/18080
- IPFS DHT Sybil attack — https://arxiv.org/abs/2505.01139 (v2, 2026-04-22)
- gitoxide — https://github.com/GitoxideLabs/gitoxide (gix 0.55.0, 2026-05)
- Radicle — https://radicle.xyz ; https://github.com/radicle-dev ; FOSDEM 2026 https://fosdem.org/2026/schedule/event/TMQZTP-radicle/ (1.6.1, 2026-01-21); LWN overview https://lwn.net/Articles/966869/ (2024-03-29); ArchWiki https://wiki.archlinux.org/title/Radicle (2026-05-25)
- VS Code contribution points (settings model) — https://code.visualstudio.com/api/references/contribution-points (updated 2026-06)
- VS Code data storage — https://code.visualstudio.com/api/extension-capabilities/common-capabilities (2026-06-01)
- zod-to-json-schema deprecation — https://www.npmjs.com/package/zod-to-json-schema (notice Nov 2025); zod#5233 https://github.com/colinhacks/zod/issues/5233 (2025-09-13)
- Chrome storage.sync analysis — alibaba.com product insights (2026-02-21)
- Sync-settings-with-GitHub extension — https://github.com/YoraiLevi/sync-settings-with-github (2024-12-29)

### 8.8 Agentic UI protocols & agent harnesses

- AG-UI docs — https://docs.ag-ui.com/introduction ; repo https://github.com/ag-ui-protocol/ag-ui ; announcement https://webflow.copilotkit.ai/blog/introducing-ag-ui-the-protocol-where-agents-meet-users (2025-05-12)
- AG-UI explainer (Codecademy) — https://www.codecademy.com/article/ag-ui-agent-user-interaction-protocol (2026-01-23)
- Oracle: Agent Spec + AG-UI + A2UI — https://blogs.oracle.com/ai-and-datascience/announcing-agent-spec-for-a2ui-copilotkit-ag-ui (2026-03-12)
- Google A2UI — spec site https://a2ui.org ; open-source release https://hia2ui.com/blog/a2ui-official-public-release/ (2026-01-04); v0.9 post https://www.copilotkit.ai/blog/a2ui-whats-new-in-google-generative-ui-spec (2026-04-17)
- A2UI with ADK walkthrough — https://atamel.dev/posts/2026/03-30_a2ui_with_adk/ (2026-03-30)
- A2UI v0.9 ecosystem note — https://gentic.news/article/google-launches-a2ui-0-9-a (2026-04-19)
- A2UI security positioning — nxcode.io "A2UI v0.9 and Agent-Driven UI" (2026-07-04)
- Protocols overview (MCP/A2A/AG-UI/A2UI) — https://atamel.dev/posts/2026/03-17_agent_protocols_mcp_a2a_a2ui_agui/ (2026-03-17)
- GenUI SDK for Flutter — https://docs.flutter.dev/ai/genui (2026-05-27); VGV guide https://verygood.ventures/blog/getting-started-with-genui/ (2026-04-16); https://stackademic.com/blog/generative-ui-in-flutter-genui-and-the-a2ui-protocol (2026-06-26); freeCodeCamp guide (2025-12-23)
- MCP-UI — https://github.com/MCP-UI-Org/mcp-ui ; https://pypi.org/project/mcp-ui/ (2025-09-11)
- HTMX MCP Apps hypermedia essay — https://htmx.org/essays/mcp-apps-hypermedia/ (2026-03-18); htmx v4 beta https://htmx.org (Summer 2026 target)
- Hypermedia agent-legibility manifesto — https://github.com/stukennedy/freetheweb (2026-02-08)
- A2A — https://a2aproject.github.io/A2A/dev/specification/ ; https://neurals.ca/tech/gemini/a2a-protocol/ (2026-05-27); https://agenticcommerceprotocol.info/standards/a2a (2025-04-09); sample messages https://google.github.io/A2A/specification/sample-messages/ ; Linux Foundation donation 2025-06-23
- Vercel AI SDK UI — https://www.aihero.dev/workshops/ai-sdk-v6-crash-course/ui-message-streams~yhlcn (2025-09-09); https://insurge.io/blog/generative-ui-chatbot-ai-elements-vercel-ai-sdk-openrouter (2026-07-06); generativeui.ru AI SDK guide (2026-02-28); https://writerdock.in/blog/building-generative-ui-how-to-stream-components-with-vercel-ai-sdk-and-next-js (2026-01-02)

### 8.9 Agent Skills ecosystem

- Agent Skills standard — https://agentskills.io/specification (published 2025-12-18); Anthropic engineering post https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills (2025-10-16)
- Ecosystem report 2026 — https://agentman.ai/blog/agent-skills-ecosystem-report-2026 (2026-06-25)
- Skill manifest specification — https://geodocs.dev/ai-agents/agent-skill-manifest-specification (2026-04-28)
- SKILL.md anatomy — agentman.ai (2026-06-09); playbook https://thevccorner.com (2026-05-18)
- Skills overview — inference.sh (2026-07-10); zylos.ai research (2026-04-08)
- WebAssembly 2026 guide — https://devstarsj.github.io/webdev/2026/02/02/WebAssembly-Wasm-2026-Guide/ (2026-02-02)

### 8.10 Inference & hybrid routing

- WebLLM/browser inference 2026 — localaimaster.com (2026-06-21)
- Browser-inference benchmarks — deciphertech.io (2026-06-29)
- "Llamas on the Web" — arXiv:2605.20706
- On-device LLM inference guide — docs.octomil.com (2026-02-18)
- llama.cpp guide — everylocalai.com (2026-07-16)
- Microsoft hybrid routing pattern — https://techcommunity.microsoft.com/blog/educatordeveloperblog/hybrid-ai-agents-in-python-routing-between-foundry-local-and-microsoft-foundry/4522979 (2026-05-27)
- SitePoint hybrid cloud-local LLM guide — https://www.sitepoint.com/hybrid-cloudlocal-llm-the-complete-architecture-guide-2026/ (2026-04-22)
- unimon.co.th hybrid design guide (2026-04-30)

### 8.11 Connect/gRPC browser streaming limits

- Connect-web client/bidi streaming limitation — https://github.com/connectrpc/connect-go/discussions/254 (accessed 2026-07-18)
- Bidi streaming requires HTTP/2 — https://github.com/connectrpc/connect-go/issues/342

### 8.12 SurrealDB & misc

- SurrealDB embedded regressions — surrealdb#6800, #5541 (GitHub issues)
- Ory Kratos — ory.com/kratos

---

## 9. Open Decisions

Numbered questions the owner must decide. Each carries this plan's recommendation; Phase 0 records the rulings as ADRs.

| # | Decision | Options | Recommendation (this plan) |
|---|---|---|---|
| OD-1 | **A2UI naming adoption.** The internal gen_ui "A2UI" (27-variant event enum) collides with Google's now-standard A2UI (a2ui.org, v0.9 shipped 2026-04-17, production Flutter/React renderers). | (a) Adopt Google A2UI as the external wire format, ContentBlock stays canonical internally, one serde mapping in `gen_ui_protocol`; (b) rename the internal protocol and stay proprietary; (c) full migration to A2UI-native internals. | **(a)** — recommended in briefs (agentic-ui §1.3, §1.9) and adopted here (§4.4.4). Docs-level rename of the internal enum to "gen_ui surface events" now; code-level `GenUiEvent` rename at next protocol-major. Recorded in `docs/corrections-2026-07-16.md` successor ADR |
| OD-2 | **FRF-vs-PES sync-gateway consolidation.** PES is a standalone gateway reusing FRF crates; FRF has its own (unauthenticated, gRPC-only) CRDT SyncService. | (a) PES evolves into an FRF edge module owning `/ws/v1/sync` (bucket + doc channels); FRF SyncService becomes the doc-channel engine behind it; (b) keep two gateways; (c) fold PES into FRF wholesale. | **(a)** — one gateway surface, one CDC pipeline, one Loro (INV-7). PES's battle-tested auth/rules/gateway code is the exterior; FRF's `SyncUseCase`/CrdtStore are the doc engine interior |
| OD-2c | **Flutter sync client strategy.** PES's `v4-dart-sdk` proposal is pure-Dart (`web_socket_channel` + drift); TJ-ARCH-MOB-001 mandates all networking in Rust. | (a) complete `pes-sdk-rust` + frb2 bridge (invariant-compliant); (b) sanction a thin generated Dart protocol client as an exception. | **(a)** — resolved in favor of the invariant (§4.2.3c). Also covers the Tauri plugin's Rust client and sidesteps the blocked `uniffi-bindgen-dart` transport (R-8). One protocol implementation, three surfaces |
| OD-3 | **PEM's two FRF adapter paths.** `entity-graph-core/adapters/flint.ts` (watchEntities facade) vs PES's server-side FRF reuse + `prometheusSyncTransport`. | (a) PES buckets canonical for data sync; `flint.ts` deprecated; (b) flint.ts kept for lightweight entity events, PES for durable sync; (c) merge the facades. | **(b) with a deprecation clock** — PES buckets are canonical for anything durable; `flint.ts` may survive one release for ephemeral entity events, then deprecates. Prevents accreting conflicting sync paths (brief: entity-management §4.10) |
| OD-4 | **Envelope vs columnar sync.** PES syncs whole-row JSON into `(id, payload)` envelopes; PGlite/Electric patterns sync real columnar tables. Envelope blocks pgvector indexes and per-column SQL on synced tables. | (a) envelope everywhere (simple, schemaless); (b) columnar sync with per-table schema declarations in sync-rules (PowerSync raw-tables direction); (c) hybrid: envelope for entity payloads, columnar opt-in for vector/index-heavy tables. | **(c)** — keep the envelope default for velocity; add columnar mapping declarations (vehicle: `entity-graph-sdl` + `registerEntityFromSql`) for tables needing indexes/SQL ergonomics. Decide per entity type at registration |
| OD-5 | **WIT convergence: `uar:skill@0.1.0` vs flint worlds vs librefang ABI.** Three WASM skill ABIs exist across the fleet. | (a) converge on the flint WIT family (`flint:host`/`flint:client`/skill world); map `uar:skill` onto it; deprecate librefang raw ABI; (b) keep UAR's world separate at the process boundary; (c) keep librefang for BossFang-legacy. | **(a) with (b)'s boundary intact** — WIT/components are the decision (brief: prometheus-skill-pack §7-G4); librefang ABI is legacy (FR-EXT-011); UAR's AGPL runtime stays at a process boundary regardless, but its *guest-facing* skill world should alias the flint skill world so components are portable |
| OD-6 | **SurrealDB embedded bet.** Pinned graph-RAG spine with no verified production-readiness evidence and known 3.0 embedded regressions (#6800, #5541), on mobile RAM budgets. | (a) keep as mandatory spine; (b) optional module behind benchmark gate with named fallback; (c) drop embedded, server-only. | **(b)** — benchmark gate at Phase 2 exit; fallback = sqlite-vec + FTS5 + recursive CTEs behind the same repository traits; never on the sync critical path (§4.1.2, R-6/R-7) |
| OD-7 | **TanStack DB vs PEM overlap.** TanStack DB (2025-07, Electric co-development) is becoming the de-facto web client layer over sync engines; PEM is the owner's equivalent. | (a) stay PEM-only (repo rule already prohibits TanStack Query); (b) adopt TanStack DB as a PEM backend consumer; (c) evaluate per-app. | **(a)** — PEM is load-bearing across 15 packages and the Flutter mirror; the field guide flags the overlap as unresolved but the switching cost is unjustified now. Revisit only if PEM's maintenance falters |
| OD-8 | **Tauri strategy: in-process vs localhost sidecar.** TJ-ARCH-MOB-001 scaffolds in-process `invoke()`; UAR's documented pattern spawns Axum on an ephemeral localhost port for full SSE/EventSource compatibility. | (a) in-process everywhere (hybrid default, pattern T2); (b) localhost sidecar where SSE-in-webview is required; (c) per-surface decision with documented criteria. | **(c)** — default in-process (T1→T2 graduation per the field guide); permit the sidecar only where a surface genuinely needs EventSource in the webview (UAR's evidence: SSE compatibility, CORS, health handshake). Criteria recorded in `references/tauri/patterns.md` |
| OD-9 | **Iggy spine fork.** FRF's broker is the owner's `GQAdonis/iggy@master` fork (pre-1.0 upstream). | (a) keep the fork behind `LogBroker`; (b) swap to NATS/Redpanda; (c) upstream the fork's changes. | **(a)** — the port keeps it a compile-time swap (R-14); revisit at FRF v2 |
| OD-10 | **`did:prometheus` formalization.** The DID method is informal: inline-key or single HTTP resolver with a placeholder URL; no rotation/revocation spec; no VC implementation. | (a) write the method spec (rotation, revocation, resolver HA) before FCP goes public; (b) stay on cosign/Sigstore for public packages and keep DIDs internal. | **(a) before Phase 5 exit** — FCP's offline-verification story leans on DID signatures; the trust root cannot remain a stub (brief: flint-forge §4.5) |
| OD-11 | **iOS consumer distribution for downloadable components.** App Store 2.5.2 restricts downloaded executable code. | (a) bundled base components only for consumer store builds; (b) downloadable components via enterprise/TestFlight; (c) challenge review with a data-driven interpretation. | **(a)+(b)** — never (c). Data-driven modules (A2UI catalogs, settings schemas, HTMX templates) are unrestricted; only executable wasm is gated (FR-EXT-010, R-11) |
| OD-12 | **Settings merge semantics for shared workspaces.** LWW-per-key is settled for `user` scope; genuinely collaborative workspace config may need CRDT semantics. | (a) LWW everywhere (simplest); (b) Loro doc channels for shared workspace settings. | **(b) only when multi-writer is real** — default LWW; promote a settings document to a doc channel explicitly (§4.5.3) |
| OD-13 | **Flint/PES SDK publication cadence.** All Flint SDKs and PES crates are unpublished (path/git refs pinned by SHA); scaffolds must reference them. | (a) publish to crates.io/npm/pub.dev on the flint-forge v1.1 cadence; (b) keep SHA-pinned git deps (current approach); (c) vendor. | **(a) with (b) as the bridge** — the scaffold's commented-out, SHA-pinned block stays until v1.1 publishes; `versions.toml` tracks both the rev pin and the target registry versions (§6.6) |

---

## Appendix A — Assumptions made beyond the briefs

The following are synthesis-level assumptions I introduced; everything else traces to a brief or a spot-checked primary source.

1. **The name "PSyncV2"** for the unified protocol — the briefs specify the evolution (create semantics, offline queue, poison handling, `/ws/v1/sync`) but do not name it. Treat as a working name.
2. **The channel-multiplexing design** (one WS endpoint carrying `bucket:` and `doc:` channels) — the briefs establish the two sync semantics separately (PES buckets; FRF CRDT SyncService); unifying them behind one endpoint is my architectural synthesis.
3. **The name `flint:client@0.1.0`** for the client WIT world — the briefs recommend identical interface shapes with local bindings and separate platform interfaces, but do not name the world.
4. **The crate names `gen_ui_sync`, `gen_ui_plugins`, `frf-sync-webrtc`, and the `FlintAdapter`** — proposed names for new components; `gen_ui_plugins` was suggested in brief 1 §3.2; the others are mine.
5. **Effort estimates in §7** — the briefs contain no estimates; the 26–37 engineer-week figure is my planning baseline.
6. **Phase boundaries** — the briefs provide waves (PES waves 6–8) and milestones (A2UI M1–M8) but not an integrated program plan; the 7-phase structure is mine.
7. **The `genui:component:invoke` Cedar action names** for the client host — modeled on flint-forge's `kiln:*` actions but not specified anywhere.
8. **Settings bucket = one per user** — the settings-sync design pattern (VS Code model over buckets) is brief-supported; the exact bucket topology is my instantiation.

*(End of master plan.)*
