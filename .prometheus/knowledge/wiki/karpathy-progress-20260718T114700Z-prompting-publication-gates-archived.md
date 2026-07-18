---
id: karpathy-progress-20260718T114700Z-prompting-publication-gates-archived
title: "Prompting publication gates archived through kbd-apply"
tags:
  - karpathy-progress
  - kbd
  - openspec
  - prompting-guide
  - github-pages
created: 2026-07-18T11:47:00Z
---

# Prompting publication gates archived through kbd-apply

## Intent

Run `/kbd-apply prompting-guide-publication-gates` after the phase was already
implemented, verified, reflected, committed, and published, then continue
autonomously through any remaining KBD/OpenSpec closure work.

## Observations

- `openspec/changes/prompting-guide-publication-gates/tasks.md` already showed all
  14 tasks complete.
- `.kbd-orchestrator/phases/build-detailed-prompting-guide/progress.json` already
  showed 5/5 changes complete and the phase reflected.
- The KBD apply driver reported `14 14 0` and `verify: PASS`.
- The first archive attempt exposed the OpenSpec interactive confirmation prompt.
  Re-running archive with `--yes` applied the spec deltas non-interactively.

## Result

OpenSpec archived `prompting-guide-publication-gates` as
`openspec/changes/archive/2026-07-18-prompting-guide-publication-gates/` and
created durable specs:

- `openspec/specs/prompting-guide-verification/spec.md`
- `openspec/specs/prompting-site-publication/spec.md`

KBD state now records the publication-gates change as archived while preserving
the phase-level completion.

## Verification

- `openspec validate prompting-guide-foundation --strict`
- `openspec validate prompting-guide-harness-loops --strict`
- `openspec validate prompting-guide-scenario-recipes --strict`
- `openspec validate prompting-guide-agent-orchestration --strict`
- `openspec validate prompting-guide-verification --type spec --strict`
- `openspec validate prompting-site-publication --type spec --strict`
- `npm run validate:prompting`
- `npm run validate:built`

`openspec validate --changes --strict` still fails on unrelated historical active
changes outside this prompting-guide closure. That failure is not publication-gate
scope evidence.

## Reusable lesson

When using `/kbd-apply` against an already-complete OpenSpec change, run the driver
progress and verify subcommands first. If all tasks are complete, finish with
`openspec archive <change> --yes` in non-interactive harnesses so the durable spec
state is created without a blocked prompt.
