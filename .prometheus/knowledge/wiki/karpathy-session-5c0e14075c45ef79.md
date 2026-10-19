---
type: SessionRecord
id: karpathy-session-5c0e14075c45ef79
title: Karpathy session 5c0e14075c45
tags:
- karpathy
- session-learning
sources:
- resource: session:9c7d0c46-27d3-49e6-a98a-f2bbffc19305
generated:
  by: pk/1.11.0
  at: 2026-10-19T10:42:28.324350+00:00
created_at: 2026-10-19T10:42:28.324350+00:00
updated_at: 2026-10-19T10:42:28.324350+00:00
revision: 0
---

## Delta

The skill package is now installed globally on this machine, at the current `main` (`0025711`).

| Harness | Status |
|---|---|
| Claude Code | Plugin updated from 2.0.0-alpha.4 to 2.0.0-alpha.5. All 36 skills match the repo. **Restart Claude Code to load it.** |
| Codex | Plugin at 2.0.0-alpha.5. All 36 skills match the repo. |
| OpenCode | 35 skills current in `~/.agents/skills` and `~/.config/opencode/skills`. The plugin, commands and activation manifest are current, with the manifest now at alpha.5. |
| Kimi Code | 35 skills current in `~/.agents/skills` and `~/.kimi-code/skills`. |
| Zed | 35 skills current in `~/.agents/skills`. |
| MiniMax Code | 35 skills current in `~/.minimax/skills`. |
| DeepSeek Harness | 35 skills current in `~/.dsh/skills`. |

The copy-based harnesses each have 35 of the 36 skills. As you chose, `karpathy-progress-memory` stays as the Prometheus version in the shared folders. This package's version of that skill is only in Claude Code and Codex.

Two loose ends:
- **Release tag:** `v2.0.0-alpha.5` is not tagged yet. The installs don't need it, since both marketplaces track `main`. It matters for anyone pinning a tag, so say the word and I'll push it.
- **Session logs:** three `.prometheus` log files have changed and aren't committed yet; they'll go in with the next commit.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 9c7d0c46-27d3-49e6-a98a-f2bbffc19305
- Captured: 2026-10-19T10:42:13.150804Z
- Project: /Users/gqadonis/Projects/hybrid-mobile-architecture-src

## Changed Paths

- No changed paths detected.
