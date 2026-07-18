---
sidebar_position: 2
title: Claude Code playbook
description: Run Prometheus KBD loops in Claude Code with CLAUDE.md, skills, hooks, subagents, headless automation, budgets, evidence, and handoffs.
---

# Claude Code playbook

Use Claude Code when the work benefits from strong repository context,
headless/streaming automation, hooks, and subagent-style decomposition. The
failure mode to avoid is an unbounded autonomous loop that edits until output
looks plausible but never proves the public boundary.

## Verified source map

This playbook is current as of `2026-07-18`. The machine-readable harness record
is `docs/prompting/data/harnesses/claude-code.json`.

| Behavior | Source |
|---|---|
| Claude Code settings configure permissions, hooks, environment, and project behavior. | [Claude Code settings](https://docs.anthropic.com/en/docs/claude-code/settings), accessed 2026-07-18 |
| Claude Code SDK/headless usage can be streamed and bounded by caller-owned automation. | [Claude Code SDK](https://docs.anthropic.com/en/docs/claude-code/sdk), accessed 2026-07-18 |

## Installation and version checks

Run these checks before a long loop:

```bash
claude --version
pwd
git status --short --branch
rg --files -g 'CLAUDE.md' -g '.claude/**' -g '.mcp.json' -g 'AGENTS.md'
```

If `claude --version` is unavailable, do not write Claude-specific setup as
verified. Document the desired configuration and run the phase in another
installed harness.

## Instruction discovery

Claude Code should start from `CLAUDE.md`, then project settings, then
task-specific skills. In this repository, `AGENTS.md` also contains canonical
cross-harness rules, so Claude Code prompts should explicitly include it when a
Prometheus phase must be portable.

Discovery prompt:

```text
Read CLAUDE.md and AGENTS.md. Inspect .claude/settings* and .mcp.json if present.
Then read only the SKILL.md files required for this task. Summarize:
- active phase or task;
- allowed writes;
- commands that prove success;
- stop conditions;
- evidence to retain.
```

## Skills, plugins, hooks, and subagents

Claude Code skills belong in the project skill directory for the repository.
Hooks are useful for enforcing command logging, formatting checks, KBD waypoint
updates, and safety stops. Subagents are useful only when ownership is explicit.

Subagent prompt:

```text
Create at most one subagent for the bounded research or verification task below.
The subagent owns only the named files or read-only question. It must not revert
or overwrite concurrent edits. It must return evidence, not claims.
```

Hook rule:

```text
Use hooks to capture evidence and stop unsafe actions. Do not use hooks to hide
failed verification, mutate requirements, or auto-approve destructive commands.
```

## MCP configuration

Use project MCP configuration when present and verify tool visibility before
relying on it:

```text
List available MCP tools relevant to the task. If the expected server is absent,
record the missing dependency and use local commands only where safe.
```

For this architecture package, likely MCP surfaces include Dart/Flutter, shadcn,
filesystem, web research, and repository tooling. Treat each as installed only
after the active Claude Code session shows it.

## Permissions

Claude Code permissions should distinguish read, local-write, external-write,
and destructive actions.

Recommended policy:

- allow read-only inspection and local verification commands;
- ask for network publication, package publishing, branch deletion, remote
  mutation, and plugin installation;
- deny broad destructive filesystem operations and credential exposure;
- require exact targets for cleanup commands.

Permission prompt:

```text
Before implementation, classify each action as read-only, local write, external
write, or destructive. Proceed only with actions authorized by the current task.
Stop before publication or deletion unless explicitly authorized.
```

## Headless and streaming loops

Headless Claude Code is appropriate for repeatable KBD phases and CI-style
review loops. It must have explicit budgets and a terminal condition.

Headless loop contract:

```text
Objective: <one observable outcome>
Budget: <minutes>, <max attempts>, <max files or scope>
Inputs: <phase files, specs, source paths>
Allowed writes: <exact directories>
Verification: <commands and public boundary>
Stop when:
- verification passes;
- the same blocker repeats twice;
- required authority is missing;
- the budget expires.
Retention:
- write a summarized Karpathy record;
- do not publish raw transcript or private logs.
```

## Evidence capture

Capture evidence through hooks, CLI output, generated reports, screenshots,
rendered docs routes, or public-boundary tests. The final answer should map each
claim to evidence.

Critic prompt:

```text
Review the producer's work against the original requirement and evidence. Fail
the work if any requested surface, validation command, publication step, source
date, or retention artifact is missing. Do not accept "implemented" as evidence.
```

## Continuation and resume

Claude Code loops must resume from files, not chat memory:

```text
Resume by reading the phase waypoint, OpenSpec task list, git status, and recent
project memory summary. Continue the next unchecked task only. If state is
ambiguous, report the ambiguity and stop instead of creating a parallel plan.
```

## Handoff examples

### Codex to Claude Code

```text
You are continuing a Prometheus KBD phase from Codex.

Read:
- CLAUDE.md
- AGENTS.md
- .kbd-orchestrator/current-waypoint.json
- .kbd-orchestrator/position-reminder.txt
- openspec/changes/<active-change>/tasks.md

Run one bounded task. Use Claude Code skills/hooks where configured. Return
changed files, verification output, and blockers.
```

### Claude Code to another harness

```text
Repository state is authoritative. The active phase is <phase-id>, change
<change-id>, task <task-id>. The completed evidence is <commands/artifacts>.
The next task is <next unchecked item>. Do not rely on the transcript; inspect
the files and continue from the waypoint.
```

## Completion rule

Claude Code may produce the implementation, but it should not self-certify.
Require a separate critic pass plus the public-boundary command before marking a
Prometheus phase task complete.
