---
type: SessionRecord
id: karpathy-session-99ebb733bda128d4
title: Karpathy session 99ebb733bda1
tags:
- karpathy
- session-learning
sources:
- session:93f1e507-988a-4ecb-aaa9-a9ba164d1673
timestamp: 2026-08-20T13:01:45.262936+00:00
created_at: 2026-08-20T13:01:45.262936+00:00
updated_at: 2026-08-20T13:01:45.262936+00:00
revision: 0
---

## Delta

Done and pushed. All three corrected across 8 files, and I re-checked each new claim against the repo rather than trusting the edit:

**1. `plugin.json` `skills` array** → now points at `builder.manifest.json` `skills[]` + `templates/activation-manifest.json`, with a note that `plugin.json` is generated. Verified: `plugin.json` has no `skills` key.

**2. "5 mirrors"** → now 6 harness dirs + `templates/project-skills/`, via `sync-harness-skills.sh` (not `add-project-skills.sh`), with `--check` for drift. Verified all 7 paths exist and match the script's `HARNESS_DIRS`. Worth noting: the `05` paragraph asserting "5 mirrors" already *listed six paths* and omitted `.kimi/` — it was internally inconsistent, now fixed.

**3. Root `marketplace.json`** → now names `.claude-plugin/marketplace.json` as the harness manifest, and describes the root file correctly as the registry descriptor. Verified: `.claude-plugin/marketplace.json` has `name`/`version`/`plugins[1]`; root `marketplace.json` has `schema_version`/`skill`. The corrected text explicitly flags this as the common misreading, since it's what broke `verify-skill-manifest.sh` on its first run.

I also fixed one thing beyond the three, in the same area: [05.1](docs/05.1-phase-v0.2.0-launch-prompt.md:61) instructed bumping the version to `0.2.0`. Since that launch prompt is what seeds future agents, leaving it would reproduce the exact conflict you resolved earlier — it now states the package is on the `2.0.0-alpha.N` line and that "v0.2.0" is the phase codename.

Docs only; no skill, script, or manifest changes. `doc-consistency`, `check-skill-contracts.mjs`, and `verify-skill-manifest.sh` all pass.

One loose end from before, unchanged: the phase's `reflect_complete` is still `false` — `/kbd-reflect` hasn't run for `v0.2.0-hma-companion-skills`.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 93f1e507-988a-4ecb-aaa9-a9ba164d1673
- Captured: 2026-08-20T13:01:43.667795Z
- Project: /Users/gqadonis/Projects/hybrid-mobile-architecture-src

## Changed Paths

- No changed paths detected.
