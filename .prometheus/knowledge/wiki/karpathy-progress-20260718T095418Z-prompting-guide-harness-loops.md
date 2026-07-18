---
id: karpathy-progress-20260718T095418Z-prompting-guide-harness-loops
title: Prompting guide harness and loop playbooks verified
type: karpathy_progress
tags:
  - karpathy-progress
  - prompting-guide
  - harnesses
  - kbd
  - verified
created: 2026-07-18T09:54:18Z
updated: 2026-07-18T09:54:18Z
---

# Prompting guide harness and loop playbooks verified

## Intent

Continue the `build-detailed-prompting-guide` KBD phase through the
`prompting-guide-harness-loops` change instead of regenerating the already
completed plan.

## Decisions

- Kept the existing KBD plan/execution state authoritative.
- Added six harness playbooks for Codex, Claude Code, OpenCode, Kimi Code CLI,
  Google Antigravity, and Zed.
- Added executable loop guides for Feynman learning, KBD lifecycle,
  Karpathy/PMPO retention, producer/critic autonomy, and a connected sanitized
  transcript.
- Strengthened the prompting validator to enforce harness source dates, required
  sections, page presence, copyable blocks, and loop fields.
- Labeled Antigravity CLI as not locally installed; retained it as official-source
  documented rather than locally exercised.

## Evidence

- `npm --prefix site run validate:prompting`
- `npm --prefix site run sanitize`
- `npm --prefix site run check:model-routing`
- `npm --prefix site run build`
- Local installed checks found Codex, Claude Code, OpenCode, Kimi Code CLI, and
  Zed; Antigravity CLI was not found in this environment.

## Reusable lesson

Prompting guide content should be validated as product documentation, not merely
written as prose. Harness pages need machine-readable metadata plus page-level
checks for official sources, dates, required sections, and copyable prompts.

## Next waypoint

Continue with the next KBD change after `prompting-guide-harness-loops` completes:
`/kbd-apply prompting-guide-scenario-recipes`.
