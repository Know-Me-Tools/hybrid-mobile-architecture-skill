# Execution — phase-codegen-and-ci-verification

> Generated 2026-07-15 · Backend: **hybrid (multi-harness + OpenSpec)** · 10 changes / 3 waves
> Dispatch mode: multi-harness per plan (prior-phase precedent, user-confirmed pattern)

## Backend selection

`hybrid`: OpenSpec (`openspec/changes/2026-07-15-c1*/`) provides per-change
traceability; the dispatch harness (`.kbd-orchestrator/dispatch/dispatch.sh`) runs
each change with claude/codex in an isolated git worktree, per the plan's harness
assignments. No opencode lanes this phase (prior scorecard: 0/2).

## Dispatch order (per plan.md)

```
W0 (serial):  C-101 bootstrap-pillars ──► C-102 poc-scaffold-first-codegen
W1 (app-sequential + 2 parallel lanes after C-102):
              C-103 chat ─► C-104 memory ─► C-105 local-model ─► C-106 sync
              C-107 whisper (parallel, own crate)   C-110 CI (parallel)
W2:           C-108 mcp+agent ─► C-109 settings+mobile-model
```

## Per-change QA gate

No artifact-refiner configured in this environment (consistent with the prior phase).
QA = manual: read done-marker, diff changed files, independently re-run
`cargo check`/`clippy`/`dart analyze`/`flutter test`/`audit.sh`/on-target builds rather
than trusting lane self-reports. Merge only on a green independent gate.

## Task execution

Per-change tasks walked via `/kbd-apply` semantics (position signals + hook firing),
executed inline by the orchestrating session since dispatched agents work in isolated
worktrees per plan.md.

## Current step

C-101 (bootstrap-pillars) executing in-session — the environment upgrade must happen
in THIS shell (not an isolated worktree) since it changes the host toolchain.
