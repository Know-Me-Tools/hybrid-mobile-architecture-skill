---
type: Reference
id: frf-phase-36-sfu-ice-fix-paused-with-no-local-changes-authored
title: FRF phase-36 SFU ICE fix paused with no local changes authored
tags:
- flint-realtime-fabric
- sovereign-sfu
- ice-debugging
- ci-logs
- kbd-orchestrator
- hybrid-mobile-architecture
links:
- hybrid-codegen-and-ci-verification-phase-opened
sources:
- stdin
- manual:flint-realtime-fabric/phase-36-sovereign-sfu-ice-linux-fix
timestamp: 2026-07-16T18:47:43.916615+00:00
created_at: 2026-07-16T18:47:43.916615+00:00
updated_at: 2026-07-16T18:47:43.916615+00:00
revision: 0
---

## Context

- **Project:** `flint-realtime-fabric`
- **Phase:** `phase-36-sovereign-sfu-ice-linux-fix`
- **KBD root:** `$HOME/Projects/prometheus/flint-realtime-fabric`
- **Captured:** `2026-07-16T18:44:58Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

## Phase goals

Phase 36 follows phase-35, which proved the sovereign SFU stack builds, boots, and runs a two-browser decode test end-to-end on `ubuntu-latest` CI (`run 29057452278`). The remaining blocker is ICE completion: the decode probe reached `ice=checking remoteCandidates=1` but stalled at `framesDecoded=0`.

The phase goal is to make sovereign SFU decode complete on real Linux and then flip `SFU_MODE=sovereign` only after observing a genuine `framesDecoded > 0`.

### G1: fix gateway log capture in CI

Required exit state:

- Next CI run produces a populated `gateway.log` artifact with non-zero bytes.
- `gateway.log` contains str0m candidate negotiation lines.

Candidate fixes:

- Copy `/tmp/p29-gateway.log` to `$GITHUB_WORKSPACE/gateway.log` inside `scripts/run-media-decode.sh` **before** the `EXIT` trap runs `docker compose down -v`.
- Or skip in-script teardown when `CI=true`, allowing the workflow's `Collect gateway logs` step to read a live container.

### G2: diagnose Linux ICE stall from str0m logs

Required exit state:

- A CI run with the log-capture fix produces a gateway log.
- The root cause of `ice=checking` on Linux is identified.

Expected candidate state:

- Gateway local candidates: `localCandidates=5`
  - Expected types include host at `172.17.0.1`, possibly mDNS, and TURN relay.
- Playwright browser remote candidates: `remoteCandidates=1`
  - Browser runs in a bridge-network container.

The gateway log should show:

- Which candidate types were exchanged.
- Whether the candidate pair was attempted.
- Why no candidate pair completed.

### G3: fix Linux candidate pairing

Required exit state:

- ICE completes on `ubuntu-latest`.
- Evidence appears as `ice=connected` in the decode probe output and/or gateway log.

## Session outcome

No changes were authored or committed in `flint-realtime-fabric` during this session.

Only read-only actions were performed in the FRF repository:

- `git pull`
- `grep`
- File reads to verify the Electric-related claim

The actual FRF-related code changes from the pivot work were made in `hybrid-mobile-architecture-src`, already committed and merged via PR #6 as part of the [Hybrid codegen and CI verification phase opened](/hybrid-codegen-and-ci-verification-phase-opened.md) line of work.

## Dirty FRF working tree items

Two uncommitted FRF items were observed, but they were not authored in this session and should not be committed without owner confirmation.

### `.kbd-orchestrator/memory-outbox.jsonl`

- Diff: **21 lines deleted, zero added**.
- Interpreted as a KBD tooling queue being drained by FRF's own tooling.
- Entries reference `phase-19`, predating this session.
- File was already dirty before any work was performed in FRF.
- Committing this could destroy pending or transient queue state.

### `openspec/changes/archive/2026-07-09-p36-c001-ice-fix-and-log-capture/`

- Untracked archived OpenSpec change.
- Date: `2026-07-09`.
- Appears to belong to the phase-36 SFU decode work already in flight from another session.

## Commit decision

Do **not** commit the observed FRF dirty state without explicit instruction.

Rationale:

- The dirty files were not authored in this session.
- The branch `sovereign-sfu-decode-proof` is mid-phase-36 and 14 commits ahead of `main`.
- FRF's `CLAUDE.md` requires halting at phase boundaries for explicit approval.
- Committing a KBD memory-outbox drain could incorrectly remove another session's pending work.

## Landed pivot work outside FRF

The FRF pivot work on the hybrid-mobile side is already landed via PR #6. It included:

- FRF-based `infra/`.
- README pointing at FRF's own Compose setup.
- Pin to FRF revision `9ba04ae`.
- `knowme-sync.sql` with publication setup.
- `REPLICA IDENTITY FULL`.
- Rewritten C-106 task list.
- Decision-log entry explaining why Electric was dropped.

No related pivot work remains uncommitted in FRF.

## Outstanding non-code action

Enabling `frf-sdk-rust` in CI still requires a secret/admin action:

- FRF is under `Prometheus-AGS`.
- The CI repo is under `Know-Me-Tools`.
- CI needs either a cross-org deploy key or a PAT.
- This must be handled by a repository admin.

## Suggested next actions

- Confirm whether anything should be committed in FRF; default is to leave the dirty items untouched.
- Otherwise continue C-106 T5b/T6b work:
  - `impl SyncTransport`
  - `LocalStore`
  - The engine still has no body.
- Note: local `main` in the skill repo still has stray commit `01c7f4a` to rewind.

# Citations

1. stdin
2. manual:flint-realtime-fabric/phase-36-sovereign-sfu-ice-linux-fix
