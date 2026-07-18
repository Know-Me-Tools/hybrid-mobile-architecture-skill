---
id: karpathy-progress-20260718T102556Z-prompting-guide-agent-orchestration
title: Prompting guide agent orchestration verified
type: karpathy_progress
tags:
  - karpathy-progress
  - prompting-guide
  - agent-orchestration
  - kbd
  - verified
created: 2026-07-18T10:25:56Z
updated: 2026-07-18T10:25:56Z
---

# Prompting guide agent orchestration verified

## Intent

Complete the `prompting-guide-agent-orchestration` KBD change by adding the
native-agent case study, skill-versus-agent decision guide, and orchestration
skill updates.

## Decisions

- Used the OpenAI-compatible proxy reference as an architecture case study only.
- Classified proxy evidence as verified-current, verified-historical,
  operator-provided, inferred, stale, or unsupported.
- Excluded stale model-catalog and unsupported subscription-auth instructions
  from public operational guidance.
- Extended `orchestrate-prometheus-application` through progressively disclosed
  references instead of duplicating the scenario corpus or model registry inside
  `SKILL.md`.
- Synchronized the skill into all six project harness skill directories and
  added parity validation.
- Added a deterministic scratch exercise for one known scenario and one
  composite scenario.

## Evidence

- `npm --prefix site run validate:skill-parity`
- `npm --prefix site run test:orchestration-skill`
- `npm --prefix site run validate:prompting`
- `npm --prefix site run test:prompting-fixtures`
- `npm --prefix site run sanitize`
- `npm --prefix site run check:model-routing`
- `npm --prefix site run build`
- `npx @fission-ai/openspec validate prompting-guide-agent-orchestration --strict --json`

## Reusable lesson

Native-agent examples must separate stable architecture lessons from stale
operational facts. Skills should route to references and registries, not become
large duplicated catalogs.

## Next waypoint

Continue with `/kbd-apply prompting-guide-publication-gates`.
