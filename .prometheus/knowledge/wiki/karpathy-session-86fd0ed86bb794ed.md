---
type: SessionRecord
id: karpathy-session-86fd0ed86bb794ed
title: Karpathy session 86fd0ed86bb7
tags:
- karpathy
- session-learning
sources:
- session:efb57ccd-0b32-4b48-a194-82de0c0b7d18
timestamp: 2026-08-24T08:19:24.740238+00:00
created_at: 2026-08-24T08:19:24.740238+00:00
updated_at: 2026-08-24T08:19:24.740238+00:00
revision: 0
---

## Delta

Completed kbd-apply — change-drift-404-harness-completeness (9/9 tasks, verified + archived)
Completed kbd-apply — change-drift-405-reinstall-verify (8/8 tasks, verified + archived)

**Phase `openspec-mirror-drift-cleanup` is complete — 6/6.** All on `origin/main` at `019c3fe`, tree clean.

## Both changes arrived pre-checked. I re-verified anyway.

That's this phase's own lesson from c401 — a checked box is not evidence — and it paid off twice.

**c404's gate is real.** I broke the working tree deliberately and restored it:

| Case | Result |
|---|---|
| healthy tree | passes, 14 targets |
| `.cursor/skills` emptied | `required target source tree is empty: cursor` |
| `.cursor/skills` removed | `required target source tree is missing: cursor` |
| policy omitted | `must declare sourceTreeLifecycle as required or install-only` |

It distinguishes empty from missing, names the target, and is wired into both install paths — not test-only. This is exactly the `.windsurf/skills` silent loss that motivated the change.

**c405's payoff verified live.** With `CLAUDE_PLUGIN_ROOT` unset, the *installed* preflight reports `status: ok`, gateway `:4000`, two distinct judge models, no config defects. The resolver bug that silently made every review same-model — while I misreported it eight times as an expired credential — is dead in the installed artifact, not just in source.

## Two real defects found by verifying

**Four stale submodule pin records.** `skill-system.json` records each commit a second time in `imports[].commit`, and the distribution test asserts it matches the gitlink. Four were stale — **one of them mine**: advancing PEM to 3.0.3 moved the gitlink but not the record. The other three came from the parallel convergence work. Fixed by deriving each from `git ls-tree` rather than typing them.

This is a live instance of the class c404 exists to prevent, in a location it doesn't cover: the lifecycle gate guards *tree presence*, but nothing guards *pin record currency* except a test someone has to run. Worth a follow-up.

**c405's criterion 2.4 was false when written.** It claimed `origin/main` contained c400–c404 on 2026-08-23, but c404 was still open then — remote had zero c404 files when I checked. Corrected, and now genuinely true.

## One correction to my own method

My first adversarial run threw `path argument must be of type string`, and I briefly read that as the gate failing. It was my bug — I called `readSkillSystem()` without its `sourceRoot`. Recorded in the design notes, because a crash-shaped throw is easy to mistake for a working guard.

Worth flagging: I did **not** re-run `update-skill-pack.sh`, since the behavior it supports was verified directly. If anything touches the resolver again, that install needs re-running rather than inferring from this record.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: efb57ccd-0b32-4b48-a194-82de0c0b7d18
- Captured: 2026-08-24T08:19:19.760413Z
- Project: /Users/gqadonis/Projects/hybrid-mobile-architecture-src

## Changed Paths

- .kbd-orchestrator/model-preflight.json
- .prometheus/knowledge/.prompt-snapshots/project/current
- .prometheus/knowledge/wiki/index.md
- .prometheus/knowledge/wiki/log.md
- .prometheus/knowledge/.prompt-snapshots/project/generations/fee037f0f977d8764015e3d12ea7ca3eb745dbc209cb42f406c6b226324479a4.json
- .prometheus/knowledge/wiki/hma-companion-consumer-integration-completion-metadata.md
- .prometheus/knowledge/wiki/karpathy-session-14f56ef2111156e8.md
- .prometheus/knowledge/wiki/karpathy-session-90208543f893da85.md
