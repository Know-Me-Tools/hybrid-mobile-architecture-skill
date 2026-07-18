# ASSESSMENT: local-first-realtime-sync

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-07-18
Codebase baseline: Skill-package repo (scaffolds + references + templates) plus the built `apps/knowme-poc` reference app (17-crate Rust workspace, Tauri/React desktop, Flutter mobile) with a working Electric-era read-sync engine and PEM+PGlite entity wiring — but no bucket-based partial replication, no CRDT path, no peer transport, and no local-first skills or reference docs.
Cross-tool progress: none recorded for this phase (fresh phase); `c106-sync-local-first` OpenSpec change remains `in_progress` from phase-codegen-and-ci-verification.

Inputs digested: `docs/knowme-local-first-realtime-master-plan.md` (1,586 lines, PROPOSAL status, OD-1…OD-13 open), all 10 `docs/research/*.md` briefs, full repo inventory, and spot-checks of `apps/knowme-poc` source.

---

## IMPLEMENTATION STATUS

Mapped against the seven phase goals and the master plan's target architecture.

- **Local store per target (PGlite web / pglite-oxide desktop / SQLite mobile)**: PARTIAL — Desktop/web are real: `scaffold-tauri.sh` generates a PGlite entity runtime (`PGlite.create('idb://gen-ui')`, transports, persistence adapter), `gen_ui_db::relational` has the `PgliteStore` OnceCell singleton over pglite-oxide 0.5.1, and `apps/knowme-poc/desktop/src/features/entities/stores/entityRuntime.ts` wires it live. Mobile is stubs: no SQLite `LocalStore` implementation generated, no sqlite-vec scaffolding; Flutter bridge sync functions are commented placeholders returning `SyncStatus.offline()`.
- **PEM 3.x as entity layer (replacing TanStack Query)**: PARTIAL — PEM `3.0.0-alpha.0` is installed and wired with `createPGlitePersistenceAdapter`, `registerEntityTransport`, `startLocalFirstGraph`; `audit.sh` enforces "PEM present + TanStack Query absent" and the repo rule already prohibits TanStack Query (master plan OD-7 confirms PEM-only). Missing: the `prometheusSyncTransport` bridge to any sync engine (transports are plain PGlite CRUD), ListQuery support (transports ignore filters/sorts — pre-C-104 note in code), and reconciliation of PEM's pending-action replay queue with a sync `_operation_queue` ("one queue, not two").
- **Sync engine — read path**: PARTIAL — C-005/C-106 shipped a real Electric HTTP shape consumer (long-poll `/v1/shape`, handle/offset, 409 rotation), DIY write queue with the PENDING→IN_FLIGHT→SYNCED/RETRYABLE/FATAL state machine, `SyncTransport` seam frozen in `gen_ui_types::sync` (doc-comment reserves a future PES client), and a `WriteSink` over Flint forge/Quarry. The decision log records the **Electric→FRF/PES pivot**, but nothing PES/PSyncV2 exists client-side, and upstream PSyncV2 pieces are stubs (`pes-sdk-rust` = 1 line, FRF `SyncService` unauthenticated, no `/ws/v1/sync` route, no spine→Postgres write-back).
- **Partial replication (goal 2: user-scoped buckets + synced lookup/metatype data)**: MISSING (buckets) / PARTIAL (lookups) — No bucket/sync-rules machinery anywhere client- or scaffold-side. The plan's answer is PES TOML sync rules (parameterized queries keyed on JWT `sub`, tenancy at bucket-assignment time). Lookup bundles are the strong half: `gen_ui_db::relational` already implements bundled/HTTP/IPFS CID-verified seed sources with ETag/304 (C-003), and boot-order INV-5 (migrations → seed/lookup → sync attach) is implemented as a typestate orchestrator. What's absent is the *changing metatype data* story — lookups are fetch-on-boot, with no re-sync/invalidations design.
- **AI chat local-first (goal 3: local threads + client vector DB + client RAG)**: PARTIAL — Durable conversations persist as PEM entities in PGlite (desktop/web) per `references/tauri/patterns.md`; Rust-side vector search exists (`gen_ui_db_graph`: SurrealDB HNSW 384-dim cosine + BM25, fastembed all-MiniLM-L6-v2 on-device embedder). Missing: pgvector-in-PGlite on web (no JS-side vector story at all), sqlite-vec on mobile (documented, not scaffolded), and — notably — **the master plan itself has no FR covering a client-side RAG retrieval loop over chat threads**; ingredients are specified, the pipeline is not.
- **Client-side agent data (goal 4)**: PARTIAL — PMPO loop runs embedded in `gen_ui_core`; memory/entity-graph persists in SurrealDB via FFI. Missing: durable agent-loop state riding PEM pending actions (plan NFR-OFF-2 "crash mid-agent resumes on next launch"), Loro doc channel for live run state, provenance fields on ContentBlock (FR-AGENT-002).
- **Sensitive profile data, peer-only CRDT sync (goal 5)**: MISSING — Zero WebRTC code, scripts, or reference text in the repo. `loro-crdt` npm dep is installed but never imported; the Rust `peer-crdt` feature's `frf-crdt`/`frf-store-redb` git deps are **commented out**; the PoC's `infra/knowme-sync.sql` explicitly uses LWW-not-CRDT. Worse, this is also **the master plan's weakest section**: PSyncV2 doc channels are server-merged by definition (FR-SYNC-010), so nothing on the sync plane satisfies "never touches the server"; the ingredients (`PrivacyClass::Local` structural exclusion — which lives in the *skill-pack substrate*, not this repo — `PeerSyncTransport`, `frf-sync-webrtc`) are named but never composed into a profile-data flow, and no FR binds profile data to the peer-only path. Browser participation is contradictory in the plan (iroh "browsers can't join gossip" vs "WASM/browser support demonstrated").
- **One-time data loads pre/post-onboarding (goal 6)**: PARTIAL — Seed/lookup bundle machinery and first-boot snapshot hydration exist (see partial replication above), but neither repo nor plan distinguishes pre-onboarding vs post-onboarding (preference-driven) loads; no onboarding-specific design exists anywhere.
- **Skills (the phase's primary deliverable class)**: MISSING — Neither `templates/project-skills/` (14 skills) nor `.claude/skills/` contains any skill for local-first sync, PEM usage, PGlite/pglite-oxide, CRDT, WebRTC/peer sync, client-side vector search/RAG, or sync-aware agents. The only realtime mention is one profile name inside `deploy-hybrid-agentic-stack`. (The `entity-realtime-*` skills visible in sessions come from the user's global harness/skill-pack, not this repo.) The plan §6.4 specifies six new skills (`sync-doctrine`, `pes-gateway-ops`, `wasm-component-authoring`, `fcp-packaging`, `settings-schema-design`, `edge-transports`); research briefs add a Tauri pglite-oxide local-first skill and PES's unwritten `v4-entity-sync-skill`.
- **Reference docs**: MISSING — No `references/sync/*`, `references/transports/*`, or any local-first/CRDT reference doc. Plan §6 specifies 9 new reference docs + 6 modifications. PEM guidance today is a few paragraphs inside `references/tauri/patterns.md`.
- **Scaffold scripts**: MISSING — None of the six proposed scripts (`scaffold-sync.sh`, `add-pglite.sh`, `scaffold-extension.sh`, `package-component.sh`, `add-settings-schema.sh`, `sync-conformance.sh`) exist; 7 existing scripts need modification per plan §6.

## CROSS-TOOL PROGRESS

- `2026-07-15-c106-sync-local-first`: in_progress (recorded under phase-codegen-and-ci-verification) — Electric read-path + write-queue landed; the FRF/PES pivot is decided in the decision log but unimplemented.
- This phase: NONE — no cross-tool activity recorded yet.

## SPEC GAP SUMMARY

1. **Goal 5 has no composed design anywhere** — peer-only CRDT sync of sensitive profile data (including browser instances) is absent from repo AND unspecified in the master plan (its doc channels are server-merged). The spec stage must author this flow: `PrivacyClass::Local`-equivalent structural exclusion + Loro over a `PeerSyncTransport` (WebRTC DataChannel for browser reach; iroh for native), signaling via FRF SignalService, admission bound to gate JWTs.
2. **Changing lookup/metatype data**: lookup bundles are one-shot fetch; goal 2 requires them to *stay current*. Needs either a versioned re-fetch/notify design or a read-only shared bucket.
3. **Client-side RAG over chat threads**: no FR in the plan, no code in the repo — the retrieval loop (embed → pgvector/sqlite-vec query → context assembly → agent) must be specified per surface.
4. **Onboarding loads**: pre- vs post-onboarding distinction undesigned in both plan and repo.
5. **PEM↔sync bridge**: `prometheusSyncTransport`, ListQuery support, and queue unification are specified in the plan but absent in PEM wiring here.
6. **Mobile tier**: SQLite+sqlite-vec `LocalStore` and Flutter bridge sync surface are stubs; Dart-sync-client question (pes-sdk-rust+frb vs pure Dart) is an unresolved conflict across briefs (TJ-ARCH-MOB-001 says Rust).
7. **Skills/references/scripts**: the entire §6 skill-package work program is unstarted — this is the repo's core deliverable as a *skill package*.
8. **Unused-dependency debt**: `loro-crdt` and `@electric-sql/pglite-sync` installed but unused (scaffold + PoC); `frf-crdt`/`frf-store-redb` commented out. These misrepresent capability and violate the minimal-code discipline; wire them or drop them per the chosen scope.
9. **Upstream blockers outside this repo**: FRF SyncService unauthenticated, `/ws/v1/sync` absent, `pes-sdk-rust` stub, spine→Postgres writer absent. Any spec choosing PSyncV2-now must either scope upstream work in, or target the existing Electric+write-queue engine and keep the frozen `SyncTransport` seam so PES drops in later.
10. **Open decisions OD-1…OD-13** in the master plan await owner ruling; at minimum OD-2/OD-2c/OD-3/OD-4/OD-6/OD-7 (sync gateway, Flutter client, PEM adapter path, envelope vs columnar, SurrealDB gate, PEM-only) gate this phase's spec.

## BUILD HEALTH

- build check: PASS (qualified) — `cargo check --workspace --exclude gen_ui_ffi` on `apps/knowme-poc/rust` finishes clean; full-workspace check FAILS on `gen_ui_ffi` with E0583, the known cold-worktree condition (flutter_rust_bridge codegen must run before check — `flutter_rust_bridge_codegen generate` regenerates the missing `frb_generated` module; see CI memory). Not a code regression.
- desktop TS / Flutter analyze: UNKNOWN — not run this assessment (previous phase CI recorded green at its close).
- known violations: unused deps (`loro-crdt`, `@electric-sql/pglite-sync`) — see gap 8; NONE otherwise observed.
- test coverage: PARTIAL — sync engine (C-005/C-106) carries behavior tests per prior phase records; nothing covering the seven goals' new surface (none exists yet).

## CONSTRAINT CHECK

- AGENTS.md / AGENT_BASE_RULES violations: NONE observed in existing code. Forward constraint: goal 5 must keep networking in Rust `gen_ui_core` (Rule 9 / TJ-ARCH-MOB-001) — a pure-JS y-webrtc/Yjs path on web would violate the invariant and also conflict with the Loro-not-Yjs wire decision (ADR-001); browser WebRTC will need the wasm lane or a JS shim under Rust control, decided at spec time.
- constraints.md: present; no violations found.
- Repo mandate compliance: TanStack Query absent ✓; PEM 3.x mandated and wired ✓; Flat 2.0 / layering untouched by this phase so far.

## GOAL PROGRESS

1. Assess plan + research to determine skills → **MET by this assessment** (skill list derived: 6 plan skills + Tauri local-first + PEM-sync recipes; see spec inputs).
2. Partial replication + synced lookup data → **NOT MET** (buckets missing; lookups fetch-once only).
3. Chat threads + client vector DB + client RAG → **PARTIAL** (threads yes on desktop/web; vectors Rust-only; RAG loop unspecified).
4. Client-side agent data → **PARTIAL** (embedded loop + SurrealDB memory; no durable resume/doc-channel state).
5. Peer-only CRDT sync of sensitive data → **NOT MET** (greenfield; also unspecified upstream — spec must author it).
6. One-time onboarding loads → **PARTIAL** (seed machinery exists; onboarding semantics undesigned).
7. PEM replacing TanStack Query with PGlite → **PARTIAL** (wired and enforced; sync bridge + ListQuery + queue unification missing).

## RISKS / CONCERNS FOR ANALYZE+SPEC (sycophancy self-check: friction surfaced)

- The master plan is a **PROPOSAL** estimating 26–37 engineer-weeks across 7 phases; this KBD phase cannot absorb that. The spec must cut a vertical slice: (a) the six-plus skills and reference docs (the repo's actual product), (b) scaffold/script updates, (c) app-side vertical slices per goal that run on what exists today (Electric engine + frozen seams) rather than on unbuilt upstream (PSyncV2, FRF auth).
- Appendix A of the plan concedes PSyncV2, crate names, phase boundaries, and effort are the author's synthesis, not brief-verified — treat them as inputs, not commitments.
- Goal 5 is the highest-novelty item and currently has no safe design anywhere; do not let it default to "later" (it is the user's explicit privacy requirement) but also do not put profile data on server-merged doc channels.
- Deferred-decision debt: proceeding to execute without OD-2/OD-3/OD-4 rulings risks building the wrong client seam twice.

ASSESSMENT COMPLETE
