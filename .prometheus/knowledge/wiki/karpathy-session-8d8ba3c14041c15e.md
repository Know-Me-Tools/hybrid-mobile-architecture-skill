---
type: SessionRecord
id: karpathy-session-8d8ba3c14041c15e
title: Karpathy session 8d8ba3c14041
tags:
- karpathy
- session-learning
sources:
- session:93f1e507-988a-4ecb-aaa9-a9ba164d1673
timestamp: 2026-08-20T12:57:20.468681+00:00
created_at: 2026-08-20T12:57:20.468681+00:00
updated_at: 2026-08-20T12:57:20.468681+00:00
revision: 0
---

## Delta

Done and pushed. All six §0 blocks now carry the frontmatter as shipped, verified byte-for-byte against `skills/<name>/SKILL.md`, plus a note stating the validator's rule (exactly `name` + `description`, single-line, ≤1024 chars) and that the trigger vocabulary moved into `description`.

Docs only — no skill, script, or manifest changes. `doc-consistency`, `check-skill-contracts.mjs`, and `verify-skill-manifest.sh` all still pass.

While in there I found **three other stale claims** in the same specs that I did *not* touch, since you scoped this to frontmatter:

| Claim | Where | Reality |
|---|---|---|
| "Added to the `plugin.json` `skills` array" | DoD in specs [01](docs/01-connected-skill-packages.md:357), [04](docs/04-skill-refiner-loop.md:334), [06](docs/06-tauri-tray-app-spec.md:375), [08](docs/08-auto-skill-package-integration.md:570), plus [05](docs/05-hma-pmp-companion-architecture.md:1000) and [05.1](docs/05.1-phase-v0.2.0-launch-prompt.md:107) | No such array; the registry is `builder.manifest.json` `skills[]` |
| "+ 5 mirrors" / "the 5 per-harness directories" | header + DoD of all six specs, and [05](docs/05-hma-pmp-companion-architecture.md:986) | 6 harness dirs + `templates/project-skills/` |
| "Valid `marketplace.json` at the repo root" with `plugins`/`skills[]` | [01 §4](docs/01-connected-skill-packages.md:206), [05](docs/05-hma-pmp-companion-architecture.md:958) | Root `marketplace.json` is a registry descriptor; the harness manifest is `.claude-plugin/marketplace.json` — the exact thing that made my first verifier fail |

The third is the most likely to bite: it's the same wrong assumption that broke `verify-skill-manifest.sh` on its first run. Want me to correct these too?

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 93f1e507-988a-4ecb-aaa9-a9ba164d1673
- Captured: 2026-08-20T12:57:18.842065Z
- Project: /Users/gqadonis/Projects/hybrid-mobile-architecture-src

## Changed Paths

- No changed paths detected.
