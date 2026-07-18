---
sidebar_position: 4
title: Kimi Code CLI playbook
description: Use Kimi Code CLI with verified config, skills, hooks, MCP, plan/auto modes, ACP, step limits, evidence, resume, and handoff.
---

# Kimi Code CLI playbook

Use Kimi Code CLI for long-context planning, CLI-centered implementation, and
ACP-compatible handoff when the installed environment exposes the required
configuration and tools. The repository treats Kimi support as useful but
environment-sensitive: verify the installed config paths and available tools
before depending on them.

## Verified source map

This playbook is current as of `2026-07-18`. The machine-readable harness record
is `docs/prompting/data/harnesses/kimi-code-cli.json`.

| Behavior | Source |
|---|---|
| Kimi command reference documents CLI modes and command operation. | [Kimi command reference](https://www.kimi.com/code/docs/en/kimi-code-cli/reference/kimi-command.html), accessed 2026-07-18 |
| Kimi slash-command reference documents command workflows. | [Kimi slash commands](https://www.kimi.com/code/docs/en/kimi-code-cli/reference/slash-commands.html), accessed 2026-07-18 |
| This repository expects project-local Kimi skills/config but requires per-machine verification. | Local observation, recorded in `docs/prompting/data/harnesses/kimi-code-cli.json` |

## Installation and version checks

```bash
kimi --version
pwd
git status --short --branch
rg --files -g '.kimi-code/**' -g '.kimi/**' -g 'AGENTS.md'
```

Then ask Kimi to report its visible tools:

```text
List the MCP tools, skills, hooks, slash commands, and project instruction files
you can see in this repository. Mark anything expected but missing as
UNVERIFIED.
```

## Instruction discovery

Kimi should read project rules first, then its config surface:

```text
Read AGENTS.md and any Kimi project configuration in this repository. Inspect the
configured skills directory and read the required SKILL.md files in full before
acting. Summarize the active phase, tool visibility, authority boundary, step
limit, and verification commands.
```

If the installed Kimi build uses a different config path than the repository
templates, update the setup docs or record the mismatch before implementation.

## Skills, plugins, hooks, and MCP

Use Kimi project skills for Prometheus loops when visible to the installed CLI.
Hooks and plugins must be treated as installed-environment features, not assumed
from documentation alone.

MCP prompt:

```text
Before invoking MCP-dependent actions, show the actual MCP servers/tools visible
to Kimi. If the expected server is missing, continue only with local file and CLI
work that does not require that server.
```

Skill prompt:

```text
Use the project-local Prometheus skill for this phase if Kimi can see it. Read
the skill instructions in full. If Kimi cannot see the skill, follow the
repository KBD/OpenSpec files manually and record the installation gap.
```

## Plan, auto, and non-interactive modes

Use modes deliberately:

| Mode | Use for | Stop condition |
|---|---|---|
| plan | Feynman learning, KBD assess/analyze/spec/plan, risk review. | Decision-complete plan with evidence requirements. |
| auto | Bounded implementation after authority is explicit. | Public-boundary verification or repeated blocker. |
| non-interactive | Scriptable validation or review loops. | Exit code plus retained output. |

Auto-mode prompt:

```text
Run in auto mode only for this bounded task:
- allowed files: <paths>
- max steps: <number>
- max retries per failing command: 2
- required verification: <command>
- stop if external authority is required.
```

## ACP and handoff

When using ACP, assume the receiving agent has a different tool surface. Handoffs
must be self-contained and file-based.

ACP handoff:

```text
Continue from repository state, not chat memory.

Phase: <phase-id>
Change: <change-id>
Next task: <task-id>
Allowed writes: <paths>
Required skills: <skills>
Verification: <commands>
Stop conditions: <conditions>
Evidence retained: <files and outputs>
```

## Evidence, resume, and recovery

Evidence to retain:

- exact Kimi command or prompt used;
- step limit and mode;
- changed files;
- verification output;
- KBD waypoint transition;
- unverified config/tool gaps.

Resume prompt:

```text
Read current waypoint, OpenSpec task list, git status, and the latest retained
evidence. Continue the next unchecked task only. Do not start a replacement plan.
```

Recovery rule:

```text
If Kimi cannot see expected skills, hooks, or MCP tools, record the mismatch and
either repair configuration explicitly or run the phase in Codex/OpenCode/Claude
Code. Do not silently downgrade the process.
```

## Completion rule

Kimi output completes a task only when the step limit was respected, the public
boundary was verified, unverified environment assumptions were labeled, and a
separate critic reviewed the evidence.
