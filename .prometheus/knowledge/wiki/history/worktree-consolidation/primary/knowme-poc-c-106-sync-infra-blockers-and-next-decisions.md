<!-- source=primary; branch=main-pre-consolidation; original_sha256=af83ed553f5fc33faa588f1464fe2a1f8048fe56704b37c432f6d872f69dad24 -->
---
type: Reference
id: knowme-poc-c-106-sync-infra-blockers-and-next-decisions
title: KnowMe PoC C-106 sync infra blockers and next decisions
tags:
- hybrid-mobile-architecture
- knowme-poc
- local-first-sync
- electric-sql
- docker-auth
- codegen
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-phase-goals-and-c-105-research-wait-state
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T18:15:25.669757+00:00
created_at: 2026-07-16T18:15:25.669757+00:00
updated_at: 2026-07-16T18:15:25.669757+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src/.claude/worktrees/pensive-greider-2e206c`
- **Captured:** `2026-07-16T18:05:47Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This session continues the PoC-first codegen/CI phase documented in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and the subsequent C-105 research wait state in [KnowMe PoC phase goals and C-105 research wait state](/knowme-poc-phase-goals-and-c-105-research-wait-state.md).

## Revised phase objective

The phase end result is a **working proof-of-concept app**, not just pipeline verification. Codegen and CI checks are supporting proof points.

### Primary goal

Build a PoC app in `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical capability set:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web from one Rust core

Feature subset is to be selected via web research on showcase-app best practices and 2026 on-device AI feasibility.

### Supporting goals

The PoC should prove the original codegen/CI scope:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## C-106 application status

`kbd-apply` was completed for `2026-07-15-c106-sync-local-first`, but only **3 of 11 tasks** were completed before halting on blockers. The work was not archived.

- **PR:** [Know-Me-Tools/hybrid-mobile-architecture-skill#5](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/pull/5)
- **Scope landed:** infrastructure tasks `T1`–`T3`
- **State:** stopped intentionally instead of forcing completion because two blockers require user decision/action.

## Blocker 1: sync engine has no implementors

`SyncEngine::new(cfg, store, sink)` cannot currently be called because the two required seams have no implementations.

Evidence from workspace search:

- `impl LocalStore` returns **zero hits** across the workspace.
- `impl WriteSink` returns **zero hits** across the workspace.
- Neither trait is referenced outside `gen_ui_db::sync` itself.

Current C-005/C-106 sync infrastructure provides a skeleton only:

- Shape consumer
- Write queue
- Idempotent keys
- Backoff
- Poison handling
- Status broadcast

The plan's C-106 entry describes "Electric read-path + DIY write queue" as if the seams already existed, but they do not. The remaining work was rescoped as:

- `T3b`: implement `LocalStore`
- `T3c`: implement `WriteSink`

These are now the bulk of C-106 rather than simple wiring.

### Required decision: write target

The plan routes writes through the "forge Quarry API", but no forge exists in `infra/`. The demo Postgres database is directly reachable.

Decision needed:

1. **Add forge/Quarry API** and route writes through it, matching the plan.
2. **Point `WriteSink` directly at Postgres** and label that architecture honestly as a demo/direct-DB path.
3. **Use fallback path:** invoke the plan's decision-2 fallback: prove `SyncStatus` + write queue via boundary tests and label the shape lane honestly rather than spending C-106 on full seam implementation.

## Blocker 2: Docker host authentication is broken

The live demo stack could not be verified because Docker pulls fail on the host.

Observed failures:

- `docker pull hello-world` fails with: `authentication required - incorrect username or password`
- `docker info` shows no logged-in Docker user

Conclusion: this is a stale host credential/login issue, not a compose configuration problem. Running `docker login` should unblock T7 live-demo verification.

## Git correction required on local main

A mistaken `cd` into the main checkout caused the C-106 commit to land directly on local `main` instead of a branch.

Correction already performed:

- The commit was moved onto `claude/c106-sync-infra`.
- PR #5 builds on that branch.

Remaining local cleanup:

- Local `main` still contains the unpushed C-106 commit.
- Reset was not run because it is destructive.
- To clean local `main` after confirming no unrelated local work is needed:

```bash
git -C ~/Projects/hybrid-mobile-architecture-src reset --hard origin/main
```

No work should be lost because the C-106 changes are on `claude/c106-sync-infra` and in PR #5.

## Infrastructure landed

The landed infrastructure includes:

- Electric `1.7.7`, pinned by multi-arch digest.
- Postgres `18-alpine`.
- Docker image details verified against:
  - Docker Hub API
  - Electric's own dev configuration
- Required Electric/Postgres WAL settings use Electric's documented `wal_level=logical` requirements.
- Schema uses UUID primary keys and soft deletes because the Electric shape contract requires them, not as a stylistic preference.

## Open next actions

1. Fix Docker auth on the host with `docker login` and rerun stack verification.
2. Decide the C-106 write target:
   - add forge/Quarry API,
   - write directly to Postgres and label accordingly,
   - or use the decision-2 fallback.
3. Implement `LocalStore` and `WriteSink` seams if continuing the full local-first sync path.
4. Continue T7 live demo once Docker pulls work.
5. Track still-open PR #4.
6. Coordinate with the concurrent session on C-105 tasks `T9`–`T12`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification