---
type: SessionRecord
id: karpathy-session-d4e96d251a4e3111
title: Karpathy session d4e96d251a4e
tags:
- karpathy
- session-learning
sources:
- session:efb57ccd-0b32-4b48-a194-82de0c0b7d18
timestamp: 2026-08-22T18:43:43.797340+00:00
created_at: 2026-08-22T18:43:43.797340+00:00
updated_at: 2026-08-22T18:43:43.797340+00:00
revision: 0
---

## Delta

Completed kbd-apply — 2026-08-22-c301-simulated-consumer-proof (9/9 tasks, verified + archived)

## What shipped

Two scripts on branch `kbd/c301-simulated-consumer-proof`, commits `19b4136` and `48b1d05`:

- **`scripts/test-consumer-install.sh`** — clones the package to scratch and exercises the documented contract there: 4 install conditions, registry *resolution* (not file existence) for all 6 v0.2.0 skills, and mirror coverage for all **35** declared skills.
- **`scripts/test-fixtures/consumer-install-negative.sh`** — a positive control plus 5 fixtures, each failing for its own named reason.

**Path isolation is proven, not asserted.** I broke the source tree deliberately — added an undeclared skill, deleted a harness mirror — and its own gate went red while the consumer proof still passed. A green result cannot come from the local checkout.

## The review found that my test harness had the exact defect it exists to catch

The sharpest finding of the phase so far: **the negative suite scored 5/5 against a six-line stub that read no input and always exited 1.** Every assertion demanded a non-zero exit, so a proof incapable of ever passing looked perfect. There was no positive control. I reproduced it, added the control as the first assertion, and re-tested — the suite now aborts with "the fixtures below would be meaningless."

Two more CRITICALs, both real:

- **`--ref` failures were swallowed.** `--ref totally-bogus-ref` reported PASS while validating the default branch and printing the bogus ref as though checked out. That's precisely the release-verification path **c305 depends on**.
- **`CONSUMER_INSTALL_REUSE_CLONE` was unvalidated** — pointing it at the live source tree produced PASS *and still printed "clone is path-isolated."* The isolation check only inspected the destination, so it could never catch it.

All seven findings reproduced and are fixed. One nice side effect: widening mirror coverage to all 35 skills immediately flagged `hybrid-mobile-architecture` — which turned out to be **correct behavior**, since `sync-harness-skills.sh:10` documents the package skill as intentionally unmirrored. I excluded it rather than reporting design as drift.

## What this does *not* claim

Passing this does not show `prometheus-companion` can consume the package — that repo is still a two-commit scaffold. It shows a *generic* consumer following the documented contract can. G1″ stays on the Companion's roadmap, and the reflection should keep that distinction rather than letting c301 stand in for it.

## Housekeeping

I removed a stale zero-byte `.git/index.lock` left by the interrupted `git add` — verified no live git process first.

**Progress: 2 of 6.** `c302`–`c304` remain independent, each opening with a decision:

- **c302** — define "replay the evidence" mechanically, or amend the skill body (may become docs-only)
- **c303** — gate the tray templates, or delete them
- **c304** — build `prom-hook-dispatch`, or drop it

Next: `/kbd-apply hma-companion-consumer-integration 2026-08-22-c302-refiner-verify-replay`

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: efb57ccd-0b32-4b48-a194-82de0c0b7d18
- Captured: 2026-08-22T18:43:34.013375Z
- Project: /Users/gqadonis/Projects/hybrid-mobile-architecture-src

## Changed Paths

- No changed paths detected.
