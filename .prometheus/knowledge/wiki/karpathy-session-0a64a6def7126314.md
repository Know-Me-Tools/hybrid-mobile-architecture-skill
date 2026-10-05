---
type: SessionRecord
id: karpathy-session-0a64a6def7126314
title: Karpathy session 0a64a6def712
tags:
- karpathy
- session-learning
sources:
- resource: session:54c1998e-0691-4568-b2ef-0572fcf2a584
generated:
  by: pk/1.11.0
  at: 2026-10-05T18:53:44.551152+00:00
created_at: 2026-10-05T18:53:44.551152+00:00
updated_at: 2026-10-05T18:53:44.551152+00:00
revision: 0
---

## Delta

The install is only partly done. It stopped on a conflict I don't want to settle on my own.

**Done**
- **Claude Code:** the `knowme-builder` marketplace and `hybrid-mobile-architecture@knowme-builder` 2.0.0-alpha.4 are installed and enabled.
- **Codex:** the same marketplace and plugin are installed and enabled.
- **Checks before installing:** the skill mirrors, harness sync and skill contracts passed. That covers all 36 skills and 108 eval cases.
- **Backups:** I moved the stale v1.0.0 copies of `hybrid-mobile-architecture` out of the way (the installer refuses to overwrite them). I did the same for `karpathy-progress-memory` in the MiniMax directory. They are in `~/.knowme-builder-backups/2026-10-05/`.

**Not done**
- **Skills:** the installer died partway through copying skills into `~/.agents/skills`. `a11y-gate` landed, but `sync-doctrine` and others did not.
- **Other harnesses:** the OpenCode, Kimi, MiniMax and Zed installs and the OpenCode plugin did not run.
- **CLI:** the `knowme-builder` CLI was not built or installed. `which knowme-builder` finds nothing.
- **Receipt:** I don't know whether the ownership receipt was written. I didn't check, and the installer fails before writing it in some paths.

**The conflict**
- **Path:** `~/.agents/skills/karpathy-progress-memory` is a symlink into the Prometheus skill system, at `~/.prometheus/plugins/prometheus-skill-pack/current/skills/karpathy-progress-memory`. That target doesn't exist, so the link is dangling and the installer's `mkdir` fails on it.
- **Cause:** both this repo and `prometheus-skill-pack` ship a skill called `karpathy-progress-memory`.
- **Why I stopped:** removing the link would touch another package's managed state. It may be recreated the next time the Prometheus tooling runs.
- **Also stale:** `~/.codex/skills/karpathy-progress-memory` differs from this repo's copy.

**Decision for you:** how should I handle the `karpathy-progress-memory` name collision?
1. Remove the dangling symlink (backed up first) and finish the install. Prometheus may recreate it.
2. Run `prometheus doctor --json` first to see why its link is dangling, then decide.
3. Skip `karpathy-progress-memory` for the shared `~/.agents` directory. That would need a change to the installer.

I'd start with option 2, then option 1.

There is also an older plugin, `hybrid-mobile-architecture@knowme-hybrid-architecture` 1.1.0, still enabled in Claude and Codex from `~/Projects/know-me/hybrid-mobile-architecture-skill`. It will load next to the new one. I left it alone. Tell me if you want it uninstalled.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 54c1998e-0691-4568-b2ef-0572fcf2a584
- Captured: 2026-10-05T18:53:43.859644Z
- Project: /Users/gqadonis/Projects/references/hybrid-mobile-architecture-skill

## Changed Paths

- .claude/settings.local.json
