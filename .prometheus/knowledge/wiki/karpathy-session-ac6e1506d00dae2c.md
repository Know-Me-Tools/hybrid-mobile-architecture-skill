---
type: SessionRecord
id: karpathy-session-ac6e1506d00dae2c
title: Karpathy session ac6e1506d00d
tags:
- karpathy
- session-learning
sources:
- resource: session:54c1998e-0691-4568-b2ef-0572fcf2a584
generated:
  by: pk/1.11.0
  at: 2026-10-05T18:54:24.372203+00:00
created_at: 2026-10-05T18:54:24.372203+00:00
updated_at: 2026-10-05T18:54:24.372203+00:00
revision: 0
---

## Delta

`prometheus doctor` shows the `karpathy-progress-memory` link is one of 86 dangling symlinks, not a one-off. It also shows Prometheus itself is unhealthy in a few places. I haven't changed anything.

**Cause of the dangling links**
- **Layout change:** the active Prometheus generation (`f58037cc…`, installed 12:16 today) lays out skills in categories (`learn/`, `rust/`, `tauri/` and so on). The links in `~/.agents/skills` were created at 12:24 with the old flat paths, so 86 of the 373 now point nowhere.
- **Skill gone:** `karpathy-progress-memory` is not in the active generation at all, in any category. Only `karpathy-tokenizer` is. So no valid target exists for that link.

**Doctor results: 3 failed, 4 warned, 11 passed**
- **`hooks.harness-adapters` (fail, 43 defects):** it looked for `./shared/harnesses/...` and `./dist/plugins/codex/...` relative to the current directory. I ran it from this repo, which doesn't have those paths, so most of these are probably false alarms from running in the wrong directory.
- **`hooks.lifecycle` (fail):** it tried to run `scripts/install-plugin-generation.js` from this repo's `scripts/`, where it doesn't exist. This is the same wrong-directory problem.
- **`execution.runtime` (fail):** `prometheus-exec doctor` reports unhealthy. This one doesn't depend on directory, and I haven't looked into it.
- **Warnings:** KBD runtime returned 404 for this project, KBD projections haven't been generated, and no discovery baselines exist.
- **`pk doctor`:** 1 failure, with 83 unsettled records in the learning queue.

None of that touches this repo's install, and the doctor offers no fix for the dangling links.

**Decision for you**
1. **Remove one link:** I move the one `karpathy-progress-memory` symlink to the backup folder and finish the install. It is dangling and nothing can resolve it today.
2. **Re-run the doctor from the Prometheus source checkout:** I'd need its path, so the 43 hook defects can be confirmed as false alarms. The 85 other dangling links stay as they are.
3. **Repair all 86 links:** re-point them to the new categorized paths. That touches Prometheus-managed state, so I'd only do it if you want.

I recommend option 1. It unblocks this install, and the other 85 links are Prometheus's to repair. If you want the doctor's verdict on a clean run too, I can also do option 2.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 54c1998e-0691-4568-b2ef-0572fcf2a584
- Captured: 2026-10-05T18:54:23.420840Z
- Project: /Users/gqadonis/Projects/references/hybrid-mobile-architecture-skill

## Changed Paths

- .claude/settings.local.json
