# Plan — scaffold-full-hybrid-project

> Generated 2026-07-15 · Inputs: assessment.md (C-1…C-8), analysis.md (C-9…C-11, verdicts),
> decision-log.md (user: DIY-sync-via-forge, vertical-slice scope)
> Backend: OpenSpec (openspec/ detected) · 12 changes in 3 waves

## Goal restated

Scaffold and prove a full instance of the hybrid architecture: Flutter mobile + Tauri
desktop + web/WASM sharing one Rust core, demonstrating PGlite/pglite-oxide/SQLite+vec,
SurrealDB 3.2 graph RAG, PEM entity management (React adopt + Flutter build), local-first
sync (Electric read path + DIY write queue via flint-forge), startup
migrations/seeds/shapes, and Flint platform integration — as a KnowMe-class vertical
slice (Chat + entity CRUD + memory RAG + sync status).

## Wave structure (worktree concurrency)

```
WAVE 0 (serial, blocking):        C-001 ──► C-002 (spike, can start with C-001 at 80%)
WAVE 1 (6 parallel worktrees):    C-003 C-004 C-005 C-006 C-007 [C-008 C-009 anytime]
WAVE 2 (3 lanes after C-007):     C-010 (Flutter) ∥ C-011 (React) ──► C-012 (integration)
```

Wave 1 lanes conflict only at `gen_ui_types` trait boundaries — those land in C-001,
which is why it is serial and first.

---

## Changes (ordered)

### WAVE 0 — Foundation

**C-001 `2026-07-15-c001-layered-workspace`** — Rewrite `scaffold-rust-core.sh` +
`scaffold-hybrid.sh` to emit the layered workspace: `gen_ui_types` (L0, pure types +
ALL cross-crate traits: `EntityTransport`, `SyncTransport`, `Transport`, ContentBlock,
A2UI/AG-UI enums, `ViewDescriptor`/`FilterSpec`/`SortSpec`), `gen_ui_runtime`,
`gen_ui_protocol`, `gen_ui_client`, `gen_ui_mcp`, `gen_ui_db` (subfeatures), `gen_ui_agent`,
leaves (`gen_ui_ffi`, `tauri-plugin-gen-ui`, `gen_ui_wasm`), `workspace-hack` (hakari).
Profiles: dev (line-tables-only, dep opt-2, build-override opt-3), release
(**panic=unwind** — fixes the frb-breaking abort bug), wasm-release (abort, opt-z),
optional nightly `dev-fast` (Cranelift, host-only). Plus `.cargo/config.toml`,
`bacon.toml` (clippy driver + cross-target check jobs), `rust-toolchain.toml`.
*Deps: none. Size: L. Library: —*

**C-002 `2026-07-15-c002-wasm32-spike`** — Validation spike: compile `gen_ui_types` +
`gen_ui_protocol` + SurrealDB `kv-indxdb` + a fetch/EventSource transport stub to
wasm32-unknown-unknown; probe PGlite interop from `gen_ui_wasm` via wasm-bindgen;
document what works/breaks in `references/rust/wasm-targets.md`. Time-boxed; findings
feed C-004/C-005/C-007.
*Deps: C-001 (types crate). Size: S-M. Library: cand surrealdb kv-indxdb*

### WAVE 1 — Parallel worktree lanes

**C-003 `2026-07-15-c003-relational-store`** *(Lane A)* — `gen_ui_db/relational`:
sqlx with feature-gated dialects (`pg` → pglite-oxide `PgliteServer`/cloud Postgres;
`sqlite` → sqlx-sqlite + sqlite-vec loading for mobile). Migration runner (sqlx
`migrate!`/refinery, one schema source → per-dialect sets, additive-only) + **startup
orchestrator**: migrations → seed/lookup bundles (bundled assets + versioned HTTP + IPFS
CID option) → sync attach. [absorbs C-10]
*Deps: C-001. Size: L. Libraries: pglite-oxide 0.5.1, sqlx, sqlite-vec, refinery*

**C-004 `2026-07-15-c004-graph-rag-store`** *(Lane A2, own crate for compile cache)* —
`gen_ui_db/graph`: SurrealDB 3.2 embedded (kv-rocksdb native / kv-indxdb wasm). Schema:
entity/memory/RELATE tables, HNSW 384-dim + FULLTEXT BM25 indexes. Hybrid graph-RAG:
vector recall → graph expansion → BM25 lane → RRF fusion in Rust. Intent-level API:
`memory_search`, `graph_expand`, `memory_ingest` (fastembed-rs 384-dim embeddings).
*Deps: C-001. Size: M-L. Libraries: surrealdb 3.2, fastembed-rs 5.x*

**C-005 `2026-07-15-c005-sync-engine`** *(Lane B)* — `gen_ui_db/sync`: Rust Electric
shape consumer (HTTP long-poll, offset tracking, must-refetch) writing to the local
store; DIY write queue (action log table, idempotent keys, replay-with-backoff, poison
handler) flushing through flint-forge Quarry API; `SyncTransport` trait seam sized for
future PES (PSyncV1). `SyncStatus` event stream for UI chips. Web path: PGlite
`pglite-sync` configuration documented (JS side).
*Deps: C-001 (+C-002 findings). Size: L. Libraries: Electric shapes protocol, per user decision DIY-via-forge*

**C-006 `2026-07-15-c006-flint-integration`** *(Lane C)* — `gen_ui_client/flint`:
gate client (anon key boot → Kratos login → authenticated/agent JWT with `act`
delegation; token lifecycle; SSE through existing streaming.rs; `isApprovalRequired`
handling for Cedar human-in-the-loop), forge client (Quarry REST/GraphQL under RLS;
`/mcp/v1/a2ui` registered into `gen_ui_mcp::McpRegistry`; `/agents/v1` AG-UI streams →
ProtocolPipeline), FRF via `frf-sdk-rust` (Spine subscribe/ack, EntityService watch;
`frf-crdt`+`frf-store-redb` peer lane behind a feature). Git deps pinned to SHAs.
*Deps: C-001. Size: L. Libraries: flint-gate/forge/FRF (git), flint-sdk-* skills*

**C-007 `2026-07-15-c007-ffi-leaves-packaging`** *(Lane D)* — The three leaves +
publishing scaffolds: `gen_ui_ffi` (frb 2.12 surface re-exporting intent APIs +
ChangeEvent/SyncStatus/A2UI streams), `tauri-plugin-gen-ui` (commands/events/permissions
+ npm guest-js package skeleton), `gen_ui_wasm` (wasm-bindgen surface + wasm-pack +
wasm-opt pipeline per C-002 findings). Package skeletons: `@prometheus-ags/gen-ui-react`,
`@prometheus-ags/gen-ui-wasm`, pub.dev `gen_ui_flutter`/`gen_ui_widgets` structure.
[absorbs assessment C-3/C-5-packaging]
*Deps: C-001, C-002. Size: M-L. Libraries: flutter_rust_bridge 2.12, tauri 2.x*

**C-008 `2026-07-15-c008-docs-refs-correction`** *(Lane E, independent)* — Fix
`docs/pglite-oxide-tauri-hybrid.md` + CLAUDE.md (pglite-oxide = WASM-runtime, desktop
only; mobile = SQLite+sqlite-vec; per-target matrix). Update
`references/flutter/patterns.md` to Riverpod 3.3 (unified Ref, **retry opt-out on FFI
providers**, Mutations API), `references/rust/patterns.md` to SurrealDB 3.2 (HNSW,
FULLTEXT) + workspace layout. Rewrite `references/*/testing.md` to features-first
(snapshot/insta, boundary-only, no internal mocks). New `references/rust/compile-speed.md`
+ `references/ui-skills.md`. [absorbs C-6+C-9]
*Deps: none. Size: M.*

**C-009 `2026-07-15-c009-project-skills`** *(Lane F, independent)* — Author the 5
project-local skill templates emitted by scaffolds (`content-block-ui`,
`hybrid-design-tokens`, `tauri-ui-review`, `flutter-golden-ui`, `a11y-gate`) with
directive descriptions + UserPromptSubmit activation hook; wire external skill refs
(frontend-design, shadcn MCP, theme-factory, vercel packs, ui-ux-pro-max, flutter/skills,
VGV goldens). [was C-7]
*Deps: none. Size: M.*

### WAVE 2 — Surfaces + integration

**C-010 `2026-07-15-c010-flutter-surface`** — `scaffold-flutter.sh` v2 + example mobile
app: `gen_ui_flutter` plugin (frb bindings, XCFramework/.so build scripts),
**`prometheus_entity_management` Dart package** (provider-families-as-normalization,
`@riverpod` CRUD controller w/ dirty-path edit buffers + optimistic rollback, ChangeEvent
bridge → `ref.invalidate`, freezed ViewDescriptor mirrors), `gen_ui_widgets` ContentBlock
set (shadcn_flutter), Riverpod 3.3.2 throughout with FFI retry opt-outs.
*Deps: C-003/004/005/007. Size: XL. Libraries: riverpod 3.3.2, PEM design §1.5*

**C-011 `2026-07-15-c011-react-surface`** — `scaffold-tauri.sh` v2 + example
desktop/web app: React 19 + Vite 8 + Tailwind 4 + shadcn; **PEM 3.0.0-alpha.0** wired
(`registerEntityFromSql` from the shared DDL, `registerEntityTransport` → forge Quarry +
tenant-scoped Electric adapter, `startLocalFirstGraph` + PGlite persistence on web,
tauri-plugin-gen-ui invoke on desktop), `@flint/react` A2UI surfaces fed by core-produced
streams, `@prometheus-ags/gen-ui-react` ContentBlock components.
*Deps: C-005/006/007. Size: XL. Libraries: PEM 3.0.0-alpha.0 (git), @flint/react (git)*

**C-012 `2026-07-15-c012-vertical-slice`** — End-to-end example ("KnowMe-slice"): Chat
tile (streaming ContentBlocks, local GGUF or gate-proxied cloud), entity CRUD (projects/
notes via PEM both surfaces), memory/graph-RAG panel (ingest → hybrid search), sync
status chip (SyncStatus stream), startup flow demo (first-run migrations → seeds →
shapes) on **all four targets** (iOS sim, Android, macOS Tauri, web). `audit.sh` extended
to verify layer contracts. Behavior tests per testing philosophy: 3–5 per feature at API
boundaries, snapshot-based.
*Deps: C-010, C-011. Size: L.*

---

## Harness / provider / model assignment (objective, per task)

Selection principles (applied, not vibes):
1. **Skill-activation reliability** — Claude Code has native Skill-tool + hook activation
   for the shared skill pack; weight it for skill-critical work (Rust patterns, Flutter,
   skill authoring).
2. **Frontier reasoning** (Opus 4.8, GPT-5.6) reserved for architecture-defining or
   distributed-correctness work where a wrong seam is expensive.
3. **Cost-efficient capable models** (GLM 5.2, Qwen 3.7, Kimi K2.6) for mechanical,
   patterned, or documentation lanes — per performance.md model-selection strategy.
4. **Long-context models** (Kimi K2.7) where the task is digesting large existing
   codebases more than novel synthesis.
5. All harnesses share `~/Projects/prometheus/prometheus-skill-pack`.

| Change | Harness · Model | Rationale | Key skills |
|---|---|---|---|
| C-001 | **Claude Code · Opus 4.8** | Architecture-defining; every later lane depends on the trait seams; deepest skill hooks | rust/workspace-structure, clean-architecture, rust-patterns |
| C-002 | **Claude Code · Sonnet 5** | Fast iterate-debug loop on cfg/dep failures; strong at toolchain forensics | librefang-wasm-skill, rust/async-patterns |
| C-003 | **Codex · GPT-5.6** | Long methodical backend build on well-established sqlx/migration patterns; low novelty, high volume | rust/error-handling, postgres-patterns |
| C-004 | **Claude Code · Sonnet 5** | SurrealDB 3.x is new territory (HNSW/FULLTEXT syntax) — doc-adherence + surreal-memory precedent in ecosystem | rust/async-patterns, llm-wiki |
| C-005 | **Claude Code · Opus 4.8** | Distributed correctness (offsets, idempotent replay, poison) — subtle-bug cost is highest here | rust/actor-model, rust/async-patterns |
| C-006 | **Claude Code · Sonnet 5** (Kimi K2.7 sub-lane for API digestion) | flint-sdk-* skills exist in-pack; K2.7's long context digests 3 repos' APIs into integration notes first | flint/flint-sdk-ts, flint-sdk-dart |
| C-007 | **OpenCode · GLM 5.2** (escalate frb quirks to Sonnet 5) | Mechanical glue on documented patterns (frb codegen, tauri plugin skeleton, package manifests) — cost-efficient | flutter/flutter-rust-ffi, tauri/tauri-react-vite |
| C-008 | **Kimi Code CLI · K2.6** | Documentation rewrite; long-context read + faithful edit; cheapest adequate tier | documentation/* |
| C-009 | **Claude Code · Sonnet 5** | Skill authoring is Claude-native (SKILL.md conventions, activation-hook patterns) | create-skill, hookify-rules |
| C-010 | **Claude Code · Sonnet 5** | Riverpod 3 nuances (retry opt-outs, Mutations) + frb streaming contract; flutter skills strongest here | flutter/flutter-rust-ffi, dart-flutter-patterns |
| C-011 | **Codex · GPT-5.6** | Frontend depth on React 19/Vite 8/shadcn; PEM wiring is TS-heavy integration | react/prometheus-entity-skills, react-vite-stack |
| C-012 | **Claude Code · Opus 4.8** | Cross-platform integration debugging + orchestration across all prior lanes | bdd-lifecycle-loop, e2e-testing |

Concurrency yield: Wave 1 runs 5 code lanes on 4 different harness/model rows
simultaneously (C-003 Codex, C-004+C-006 Claude Sonnet, C-005 Claude Opus, C-007
OpenCode, C-008 Kimi) — no two heavy lanes contend for the same provider quota.

## Execution notes

- Each Wave-1 change gets its own git worktree; conflicts limited to `gen_ui_types`
  (frozen after C-001 review — changes to it require cross-lane sign-off).
- Loop discipline per CLAUDE.md: `bacon clippy` inner loop; features first, 3–5 boundary
  tests at completion; two failed test-fix attempts → stop and report.
- OpenSpec: each change gets `openspec/changes/<id>/proposal.md` (created by this plan);
  tasks tracked per-change in `tasks.md` at execute time via `/opsx:ff` or
  `/openspec-continue-change`.
- Constraints: scripts/ changes must stay backward-compatible (WARNING tier);
  plugin.json/marketplace.json need version bumps when scaffold outputs change.

## First change to apply

**C-001** (`/opsx:ff 2026-07-15-c001-layered-workspace` or `/kbd-execute`).
C-008/C-009 may start immediately in parallel (no deps).
