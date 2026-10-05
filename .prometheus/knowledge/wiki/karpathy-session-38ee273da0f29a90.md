---
type: SessionRecord
id: karpathy-session-38ee273da0f29a90
title: Karpathy session 38ee273da0f2
tags:
- karpathy
- session-learning
sources:
- resource: session:54c1998e-0691-4568-b2ef-0572fcf2a584
generated:
  by: pk/1.11.0
  at: 2026-10-05T18:57:16.735949+00:00
created_at: 2026-10-05T18:57:16.735949+00:00
updated_at: 2026-10-05T18:57:16.735949+00:00
revision: 0
---

## Delta

I repaired only 14 of the dangling symlinks, because the rest can't be fixed by re-pointing them.

**Repaired**
- `artifact-refiner`, `prometheus-artifact-refiner` and `sycophancy-correction` now point to `current/skills/imported/...` in the active Prometheus generation.
- They are fixed in the agents, claude, kimi, zed, gemini and cursor directories, and each one resolves to a real `SKILL.md`.
- The old targets are recorded in `~/.knowme-builder-backups/2026-10-05/relinked-symlinks.json`, so this can be undone.

**Not repaired**
- **Scale:** the actual count is about 457 dangling Prometheus links across seven harness directories, not the 85 I first counted. About 443 still remain after the 14 repairs.
- **Cause:** the new Prometheus generation (built at 12:27 today) dropped about 63 skills, including `refine-*`, `better-*`, `impeccable`, `expo-*`, `ui-ux-pro-max`, `karpathy-progress-memory`, `kbd-loop` and the `rust-*` ones. They don't exist anywhere in the active generation. The links break because the skills were removed, not because the paths moved.
- **Where they survive:** the previous generation (`26bdb347…`, built at 12:03 today) still has them.
- **Other broken links:** 24 more are broken for other reasons and I haven't touched them. `kbd-handoff` points into the `prometheus-skill-system` checkout, and `prometheus-sync-*` points into `~/.cowork/...`.

I stopped there because there's no safe automatic repair for the rest.
- **Pointing at the previous generation:** this would revive skills the new generation dropped, and Prometheus can garbage-collect that generation.
- **Copying the skills out of the previous generation:** this would create an unmanaged copy that Prometheus doesn't know about.
- **Removing the dangling links:** this is harmless, since they resolve to nothing today. But Prometheus will likely recreate them on its next sync.

**Decision for you**
1. Leave them. They're harmless noise, and the missing skills are Prometheus's call to restore.
2. Remove them. I'd back up the 443 links first, but Prometheus may recreate them.
3. Ask Prometheus why it dropped them. It's worth finding out whether this was intentional or a bad generation. If it wasn't intentional, rolling back to the `previous` generation would restore everything at once, but that is a Prometheus operation I shouldn't run without you asking for it.

I'd go with option 3 first, because if the drop was a mistake, options 1 and 2 only hide it.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 54c1998e-0691-4568-b2ef-0572fcf2a584
- Captured: 2026-10-05T18:57:15.969817Z
- Project: /Users/gqadonis/Projects/references/hybrid-mobile-architecture-skill

## Changed Paths

- .claude/settings.local.json
