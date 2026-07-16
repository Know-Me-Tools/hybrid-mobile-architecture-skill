# Execution — scaffold-full-hybrid-project

> Generated 2026-07-15 · Backend: **hybrid (multi-harness + OpenSpec)** · 12 changes / 3 waves
> Dispatch mode: multi-harness per plan (user-confirmed)

## Backend selection

`hybrid`: OpenSpec provides per-change traceability (`openspec/changes/2026-07-15-c0*/`);
external harnesses execute the code in isolated git worktrees. Each change is dispatched
to its plan-assigned harness/model, all sharing
`~/Projects/prometheus/prometheus-skill-pack`.

## Verified harness invocations

| Harness | Non-interactive command | Model flag (verified provider IDs) |
|---|---|---|
| Claude Code | (this session, or `claude -p`) | opus-4.8 / sonnet-5 |
| Codex | `/opt/homebrew/bin/codex exec -C <dir> -m <model>` | `gpt-5.6-sol` (needs codex ≥0.144; see env note) |
| OpenCode | `opencode run --dir <dir> -m <provider/model>` | `zai-coding-plan/glm-5.2`, `kimi-for-coding/k2p6`, `minimax/MiniMax-M3`, `qwen/*` |
| Kimi Code CLI | `kimi` (or via opencode `kimi-for-coding/k2p6`) | `k2p6` |

## Worktree isolation

Each Wave-1 change runs in its own git worktree under
`.kbd-orchestrator/dispatch/worktrees/<change-id>` on branch `exec/<change-id>`,
branched from the commit where **C-001 is merged** (Wave-1 depends on the frozen
`gen_ui_types` seams). C-008 and C-009 branch from current `main` (no C-001 dependency).

## Dispatch order

```
STEP 1 (now):   C-001 [claude/opus-4.8, in-session]  ── blocking
                C-008 [kimi k2p6, worktree]           ── parallel, no dep
                C-009 [claude/sonnet-5, worktree]     ── parallel, no dep
STEP 2 (gate):  Review + freeze gen_ui_types seams from C-001; merge C-001 to main
STEP 3 (fan):   C-002 [claude/sonnet-5] then C-003..C-007 dispatched to worktrees:
                  C-003 codex/gpt-5.6 · C-004 claude/sonnet-5 · C-005 claude/opus-4.8
                  C-006 claude/sonnet-5 · C-007 opencode/glm-5.2
STEP 4 (surf):  C-010 claude/sonnet-5 ∥ C-011 codex/gpt-5.6  → C-012 claude/opus-4.8
```

## Per-change QA gate

After each change → DONE: artifact-refiner validation against constraints.md. Doc-only
changes (C-008) and small changes skip QA per skill rules. PASS → `/opsx:verify` →
`/opsx:archive`. FAIL → BLOCKED + refine.

## Task execution

Per-change tasks are walked by `/kbd-apply` (fires `task:before`/`task:after` +
position signals). Bare `/opsx:apply` is NOT used (no KBD awareness).

## Dispatch driver

`.kbd-orchestrator/dispatch/dispatch.sh <change-id> <harness> <model>` — creates the
worktree, seeds the per-change prompt (preamble + change pointer), invokes the harness
non-interactively, logs to `.kbd-orchestrator/dispatch/logs/<change-id>.log`, and expects
`<change-id>.done.md` on completion.

## Current step

STEP 1 in progress: C-001 executing in-session (Opus 4.8); C-008/C-009 ready to dispatch.

## Environment fix (2026-07-15) — codex CLI upgrade

The plan's Codex/GPT-5.6 lanes (C-003, C-011) required a codex upgrade:
- PATH had a stale `~/.cargo/bin/codex` (0.0.0, dev build) shadowing a broken brew cask.
- The old npm/fnm codex (`0.2.0-alpha.2`) rejected `gpt-5.6-sol` ("requires a newer CLI")
  and `gpt-5.6` ("not supported on ChatGPT account").
- Fixed: `brew upgrade --cask codex` → **0.144.4** at `/opt/homebrew/bin/codex`; removed
  the stale `/usr/local/bin/codex` fnm symlink. `~/.cargo/bin/codex` (0.0.0) left in place
  (user's binary) — dispatch calls brew codex by absolute path via `CODEX_BIN`.
- VERIFIED: `gpt-5.6-sol` returns SMOKE_OK on 0.144.4, ChatGPT auth.
- Note: codex reports a "skills context budget 2%" cap when 800+ global skills are present;
  dispatched codex should be pointed at the prometheus-skill-pack specifically.

Model IDs corrected: codex `gpt-5.6-sol` · opencode `zai-coding-plan/glm-5.2`,
`kimi-for-coding/k2p6`, `minimax/MiniMax-M3`. opencode GLM-5.2 verified (SMOKE_OK).
