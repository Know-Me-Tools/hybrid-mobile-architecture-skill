---
type: SessionRecord
id: karpathy-session-71cd94a865986160
title: Karpathy session 71cd94a86598
tags:
- karpathy
- session-learning
sources:
- resource: session:54c1998e-0691-4568-b2ef-0572fcf2a584
generated:
  by: pk/1.11.0
  at: 2026-10-05T18:55:35.562608+00:00
created_at: 2026-10-05T18:55:35.562608+00:00
updated_at: 2026-10-05T18:55:35.562608+00:00
revision: 0
---

## Delta

All six harnesses are now installed, and the installer, `knowme-builder manifest check` and the plugin lists all report 2.0.0-alpha.4.

| Harness | Install | Verified |
|---|---|---|
| Claude Code | `knowme-builder` marketplace and plugin | enabled in `claude plugin list` |
| Codex | `knowme-builder` marketplace and plugin | installed and enabled in `codex plugin list` |
| OpenCode | 36 skills in `~/.config/opencode/skills`, plus the advisory plugin | 36 of 36 match the repo |
| Kimi Code | 36 skills in `~/.kimi-code/skills` | 36 of 36 match |
| MiniMax Code | 36 skills in `~/.minimax/skills` | 36 of 36 match |
| Zed | reads `~/.agents/skills`, which has no separate directory (the 0/36 I got earlier was a wrong path guess) | 36 of 36 match there |
| `knowme-builder` CLI | release build, installed to `~/.cargo/bin` | reports 2.0.0-alpha.4; `manifest check` passes |

- **Receipt:** it was written at `~/.local/state/knowme-builder/install.json` and lists all six harnesses.
- **Backups:** in `~/.knowme-builder-backups/2026-10-05/` I put the stale v1 `hybrid-mobile-architecture` copies from the agents, opencode and kimi directories. I also put the stale `karpathy-progress-memory` copy from MiniMax and the dangling `karpathy-progress-memory` symlinks from agents and kimi. Nothing was deleted.
- **Codex re-run:** re-running the full installer fails at the Codex step with "not configured as a Git marketplace". The Codex marketplace was registered from a local path, and the installer's update path expects Git. I installed the other harnesses one at a time to get around it. Registering from the Git URL, or fixing that update path, would make re-runs work.
- **Old v1.1.0 plugin:** `hybrid-mobile-architecture@knowme-hybrid-architecture`, from `~/Projects/know-me/...`, is still enabled in Claude and Codex next to the new one. I haven't touched it.
- **Other dangling links:** the other 85 dangling Prometheus symlinks in `~/.agents/skills` are still there. Running `prometheus doctor` from the Prometheus checkout would show whether its 43 hook defects were just from running it in the wrong directory.
- **Restart:** restart Claude Code, Codex and the other tools so they pick up the new skills.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 54c1998e-0691-4568-b2ef-0572fcf2a584
- Captured: 2026-10-05T18:55:34.709859Z
- Project: /Users/gqadonis/Projects/references/hybrid-mobile-architecture-skill

## Changed Paths

- .claude/settings.local.json
