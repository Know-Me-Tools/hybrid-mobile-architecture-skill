---
type: SessionRecord
id: karpathy-session-2ffd3e68effb99c0
title: Karpathy session 2ffd3e68effb
tags:
- karpathy
- session-learning
sources:
- resource: session:54c1998e-0691-4568-b2ef-0572fcf2a584
generated:
  by: pk/1.11.0
  at: 2026-10-05T20:33:49.286954+00:00
created_at: 2026-10-05T20:33:49.286954+00:00
updated_at: 2026-10-05T20:33:49.286954+00:00
revision: 0
---

## Delta

I filed the issue: https://github.com/Prometheus-AGS/prometheus-skill-system/issues/160

- **Repo:** `Prometheus-AGS/prometheus-skill-system`. It's public and has issues enabled. I searched first and found no similar issue.
- **Title:** "Stale cached plugin hook re-activates an older generation; hooks write bytecode into the signed payload".
- **Contents:** it covers both problems from the draft. The first is the stale 1.7.0 cached plugin rebuilding an older generation, with the timeline and evidence. The second is hooks writing `__pycache__` into the signed payload. It includes the suggested fixes.
- **Cleanup:** I left out the "draft only" line, and the body has no absolute local paths. The local file in `~/.knowme-builder-backups/2026-10-05/` is unchanged.

I didn't add labels, an assignee or a link to a PR.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 54c1998e-0691-4568-b2ef-0572fcf2a584
- Captured: 2026-10-05T20:33:48.541043Z
- Project: /Users/gqadonis/Projects/references/hybrid-mobile-architecture-skill

## Changed Paths

- .claude/settings.local.json
