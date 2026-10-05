---
type: SessionRecord
id: karpathy-session-daa5faaef642f897
title: Karpathy session daa5faaef642
tags:
- karpathy
- session-learning
sources:
- resource: session:54c1998e-0691-4568-b2ef-0572fcf2a584
generated:
  by: pk/1.11.0
  at: 2026-10-05T19:02:28.214617+00:00
created_at: 2026-10-05T19:02:28.214617+00:00
updated_at: 2026-10-05T19:02:28.214617+00:00
revision: 0
---

## Delta

The rollback is done and holding. The Prometheus `current` symlink points at the 1.11.2 generation again, and it was still there after the doctor run. The doctor went from 3 failures to 2, and `execution.runtime` now passes.

**What caused it**
- The Claude plugin cache still has a stale `1.7.0` copy of `prometheus-skill-pack` next to `1.11.2`, both touched at 12:14. Its hooks hard-code bundle `4cbc51fa…`. When the runtime can't resolve that bundle, they run `bootstrap-hook-runtime.sh`, which builds and activates a generation from the 1.7.0 payload.
- The generation that replaced the 1.11.2 one had exactly that bundle ID. It was built at 12:16:48, two minutes after the cache refresh, and it flipped the symlink without updating Prometheus's own `pointers/`. That mismatch is why the pointers still said 1.11.2.
- I can't tell which session fired the hook. This is a strong circumstantial match, not proof. I didn't run any Prometheus install myself.

**What I changed**
- **Pointers:** `current` is now `26bdb347…` (1.11.2) and `previous` is `ff17bca0…`, matching Prometheus's own pointer files. The old values are saved in `~/.knowme-builder-backups/2026-10-05/prometheus-pointers-before-rollback.txt`.
- **My earlier repair:** I restored the 14 symlinks I'd re-pointed to their original targets, because the categorized paths don't exist in the 1.11.2 layout.
- **Links:** the 1.7.0 activation had also re-pointed about 140 links per directory to categorized paths, which made them dangle after the rollback. I re-pointed 834 links across six directories to the flat paths. The old targets are in `relinked-flat-symlinks.json`.
- **Result:** dangling links are down from about 77 per directory to 7. Those 7 are `kbd-handoff`, `sync-*` and `prometheus-sync-*`, which point at other checkouts and were never part of this issue.

**Still open**
- **`hooks.lifecycle` (fail):** a stray `shared/scripts/lib/__pycache__/agent_identity.cpython-312.pyc` sits in the generation payload and isn't in the manifest. Deleting it would fix the check, but it edits a signed immutable generation, so I left it.
- **`hooks.harness-adapters` (fail):** "fixed hook runtime differs from its generation receipt". The 1.7.0 bootstrap probably overwrote `runtime/v1`. Re-running the 1.11.2 installer, `prometheus-skill-system/scripts/install-plugin-generation.js`, should fix it, but I haven't run it.
- **Warnings:** the plugin source has uncommitted changes (the other session's work), KBD returns 404, and there are no discovery baselines. None of these relate to this issue.
- **The 1.7.0 cache dir:** I haven't removed it, so the same hook can fire again from any session still running it and undo the rollback. Removing it would make that session's hooks exit with `NOT_ACTIVATED`.

**Decision for you:** how should I proceed?
1. **Remove the stale 1.7.0 cache dir.** I'd move it to the backup folder, not delete it. This is the only step that prevents a repeat.
2. **Re-run the 1.11.2 `install-plugin-generation.js`** from the checkout to fix the two remaining doctor failures.
3. **Leave both.** The rollback holds until something fires a 1.7.0 hook again.

I recommend 1 first and then 2. If you'd rather not touch live Claude sessions, close any old ones before I do it.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 54c1998e-0691-4568-b2ef-0572fcf2a584
- Captured: 2026-10-05T19:02:27.621797Z
- Project: /Users/gqadonis/Projects/references/hybrid-mobile-architecture-skill

## Changed Paths

- .claude/settings.local.json
