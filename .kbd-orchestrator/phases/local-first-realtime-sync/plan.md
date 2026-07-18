# PLAN: local-first-realtime-sync

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-07-18
OpenSpec available: YES
Changes to implement: 6

Planning inputs: `assessment.md` (this phase), master plan §6 (skill-package work program) and §9 open decisions, c106 decision log (**binding pivot: ElectricSQL is OUT, FRF is the realtime substrate** — no new Electric work; the C-005 Electric consumer stays as legacy/fallback code only), ten research briefs.

Scope thesis: this phase delivers the **skill package's local-first product** (reference docs, skills, scaffold behavior) plus **app vertical slices in knowme-poc that run on today's frozen seams** (`SyncTransport`, `LocalStore`, PEM transports). It does NOT build the PSyncV2 gateway, FRF auth fixes, or the WASM/FCP/settings planes (master-plan Phases 0/1/3–5 — upstream repos or later phases).

---

## CHANGE LIST (ordered)

1. **c120-sync-doctrine-refs**: Author the sync doctrine — ADRs + reference docs that every other change cites.
   - Scope: docs (references/sync/*, CLAUDE.md index, ADRs)
   - Depends on: NONE
   - Recommended agent: Claude Code
   - Est. complexity: M
   - Complexity score: High (design authority for the whole phase)
   - Model class: frontier
   - Customer value: HIGH
   - Details: Write `references/sync/doctrine.md` (invariants INV-1…7, four-phase boot, write-queue state machine, fail-closed rules, thin-client fallback, secrets-never-sync), `references/sync/partial-replication.md` (user-scoped buckets on the `SyncTransport` seam; **lookup/metatype currency design** — versioned bundles with ETag/304 re-validation + change notification; **pre-/post-onboarding one-time load semantics** as explicit startup-orchestrator stages), `references/sync/peer-crdt.md` (**the goal-5 design the master plan lacks**: profile vault as Loro doc, privacy-class structural exclusion from server sync, WebRTC DataChannel device-to-device including browser instances, Loro-not-Yjs wire, Rust-owned networking on native surfaces + JS shim boundary on web), and `references/sync/client-rag.md` (per-tier vector matrix — pgvector-in-PGlite web, pglite-oxide desktop, sqlite-vec mobile, 384-dim standard; the chat-thread RAG retrieval loop). Ratify as short ADRs: FRF/PES lane per c106 pivot (OD-2), PES-canonical PEM adapter (OD-3), envelope-default/columnar-opt-in (OD-4), PEM-only (OD-7), Loro (ADR-001 adoption). Update CLAUDE.md reference index.

2. **c121-local-first-skills**: Four new project-local skills + activation hooks, propagated like the existing 14.
   - Scope: templates/project-skills, .claude/skills mirror, hooks
   - Depends on: c120
   - Recommended agent: Claude Code
   - Est. complexity: M
   - Complexity score: Medium
   - Model class: medium
   - Customer value: HIGH (the repo's actual product)
   - Details: `sync-doctrine` (invariants + partial replication + onboarding loads; directive "ALWAYS invoke when" descriptions), `pem-local-first` (PEM 3.x as the entity layer replacing TanStack Query; PGlite/pglite-oxide/SQLite adapters per tier; transport registration; queue-unification guidance), `client-rag` (client vector DB per tier + embedding + retrieval loop with client agents; chat-thread RAG recipes), `peer-profile-sync` (goal-5 flow: Loro vault, WebRTC pairing, privacy classes, never-server rules). Each cites the c120 references; wire into `settings.hooks.json` activation hooks and `scripts/add-project-skills.sh` propagation; mirror into `.claude/skills/`.

3. **c122-partial-replication-slice**: knowme-poc vertical slice — user-scoped replication + lookup currency + onboarding loads on the frozen seams.
   - Scope: rust (gen_ui_db sync/relational), desktop store layer, scripts/scaffold-rust-core.sh
   - Depends on: c120
   - Recommended agent: Claude Code
   - Est. complexity: L
   - Complexity score: High
   - Model class: frontier
   - Customer value: HIGH
   - Details: Implement bucket-shaped scope descriptors on `SyncTransport::start()` (user-subset + shared-lookup scopes), a transport-neutral dev loopback transport (so the slice runs and tests without the unbuilt PES gateway; FRF lane drops in later), lookup-bundle **currency**: versioned re-validation (ETag/304) + on-change re-fetch surfaced through PEM entities; extend the typestate startup orchestrator with explicit `pre_onboarding_load` and `post_onboarding_load` stages (idempotent, recorded in a local `_load_ledger` table). Propagate the pattern into `scaffold-rust-core.sh`.

4. **c123-client-rag-slice**: knowme-poc vertical slice — client-side vector search + chat-thread RAG for client agents.
   - Scope: rust (gen_ui_db_graph/inference), desktop (PGlite pgvector + PEM), web lane
   - Depends on: c120
   - Recommended agent: Claude Code
   - Est. complexity: L
   - Complexity score: High
   - Model class: frontier
   - Customer value: HIGH
   - Details: Enable pgvector in the PGlite web store and via pglite-oxide on desktop (384-dim per doctrine); embed chat messages on write (fastembed via FFI on desktop; web lane per c120 ADR), store agent working data as PEM entities; implement the retrieval loop (embed query → vector + BM25 → context assembly → agent prompt) exposed as a typed API the chat feature calls. Mobile: document sqlite-vec parity + scaffold stub only (full mobile client deferred — see cuts).

5. **c124-peer-profile-vault**: knowme-poc vertical slice — sensitive profile data as a Loro vault, device-to-device only.
   - Scope: desktop + web (loro-crdt, WebRTC DataChannel), rust privacy-class filter
   - Depends on: c120
   - Recommended agent: Claude Code
   - Est. complexity: L
   - Complexity score: High
   - Model class: frontier
   - Customer value: HIGH (explicit user privacy requirement)
   - Details: Profile/sensitive data lives in a Loro doc persisted locally (PGlite/pglite-oxide `crdt_state`), **structurally excluded from every server sync path** (privacy-class filter at the enqueue boundary, fail-closed). Device-to-device sync over WebRTC DataChannels between the user's devices and browser instances: pairing via short-lived offer exchange (dev signaler in the slice; FRF SignalService noted as the production lane), Loro `export_updates_since` delta exchange, chunked 16–256 KiB. This finally *uses* the `loro-crdt` dep (or removes it if the Rust-wasm lane is chosen in c120 — either way the unused-dep debt is resolved). Client agents read the vault locally; inference calls carry only momentary context, never persist server-side.

6. **c125-scaffold-audit-propagation**: Fold the slices back into the generators and gates.
   - Scope: scripts (scaffold-tauri/flutter/rust-core, audit.sh), versions.toml, templates
   - Depends on: c122, c123, c124
   - Recommended agent: Codex or Claude Code
   - Est. complexity: M
   - Complexity score: Medium
   - Model class: medium
   - Customer value: HIGH for the skill package (it IS the product)
   - Details: scaffold-tauri.sh generates the RAG + vault wiring (no more dead deps); scaffold-flutter.sh generates the SQLite `LocalStore` + sqlite-vec stubs and un-stubs the bridge sync surface signatures; audit.sh gains checks: secrets/privacy-class never in sync queue, no TanStack Query (existing), declared-but-unused sync deps fail WARNING tier, vector store present when chat feature present; versions.toml `[sync]` pin block (loro, pglite, pglite-oxide, sqlite-vec, webrtc deps).

## EXECUTION ROUND ORDER

- Round 1: c120 (doctrine — everything cites it)
- Round 2 (parallel): c121, c122, c123, c124
- Round 3: c125 (propagation after slices prove the patterns)

## COMMANDS TO RUN

/opsx:new c120-sync-doctrine-refs
/opsx:new c121-local-first-skills
/opsx:new c122-partial-replication-slice
/opsx:new c123-client-rag-slice
/opsx:new c124-peer-profile-vault
/opsx:new c125-scaffold-audit-propagation

## TRADE-OFFS AND EXPLICIT CUTS (sycophancy self-check)

- **PSyncV2/PES gateway, FRF SyncService auth, `/ws/v1/sync`, spine→Postgres writer are OUT** — they live in upstream repos (PES, FRF, flint-forge) and are 10+ engineer-weeks by the master plan's own estimate. The slices run on a dev loopback transport behind the frozen `SyncTransport` seam so the PES client drops in without rework. Consequence accepted: no *production* server round-trip ships this phase.
- **Full mobile sync client deferred** — the Dart-client question (OD-2c: pes-sdk-rust+frb vs pure Dart) is blocked on upstream frb/uniffi realities; this phase ships mobile stubs + doctrine only. Goal coverage on mobile is documentation + scaffold shape, not running code.
- **WASM extension, FCP packaging, settings-schema planes** (master-plan Phases 3–5, skills `wasm-component-authoring`/`fcp-packaging`/`settings-schema-design`/`pes-gateway-ops`/`edge-transports`) are OUT — not required by the seven goals; four skills ship instead of the plan's six, scoped to what the goals need.
- **Peer vault pairing uses a dev signaler**, not FRF SignalService — production signaling is an upstream integration; the wire design (c120) specifies it so the swap is a transport change, not a redesign.
- **Risk accepted**: master plan is a PROPOSAL; if the owner later rules OD-2/OD-4 differently than the c106 pivot + recommendations ratified in c120, c122's scope descriptors may need re-shaping (seam-level, not rewrite).

PLAN COMPLETE
