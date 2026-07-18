---
sidebar_position: 3
title: OpenCode playbook
description: Use OpenCode project skills, agents, permissions, commands, MCP, ACP, evidence capture, and handoff for Prometheus application phases.
---

# OpenCode playbook

Use OpenCode when you want a repository-native CLI workflow with project skills,
named agents, command shortcuts, explicit permission policy, and MCP wiring in
tracked configuration. OpenCode is a strong fit for producer/critic separation
because agents can be configured with different instructions and tool authority.

## Verified source map

This playbook is current as of `2026-07-18`. The machine-readable harness record
is `docs/prompting/data/harnesses/opencode.json`.

| Behavior | Source |
|---|---|
| Project skills are a first-class OpenCode capability. | [OpenCode skills](https://opencode.ai/docs/skills/), accessed 2026-07-18 |
| Named agents can separate roles and permission profiles. | [OpenCode agents](https://opencode.ai/docs/agents/), accessed 2026-07-18 |
| MCP servers are configured as part of OpenCode integration. | [OpenCode MCP servers](https://opencode.ai/docs/mcp-servers/), accessed 2026-07-18 |

## Installation and version checks

```bash
opencode --version
pwd
git status --short --branch
rg --files -g 'opencode.json' -g '.opencode/**' -g 'AGENTS.md'
```

If OpenCode is not installed, keep the page as implementation guidance and run
the phase in an installed harness. Do not label OpenCode-specific command output
as verified unless it actually ran.

## Instruction discovery

OpenCode should read project rules and its own configuration first:

```text
Read AGENTS.md, opencode.json, .opencode/commands, and the required
.opencode/skills/*/SKILL.md files. Summarize:
- active OpenSpec/KBD change;
- producer agent and critic agent;
- allow/ask/deny permissions;
- MCP servers available;
- commands that prove success.
```

## Skills and commands

Put repeatable Prometheus workflows in `.opencode/skills/` and slash-command
style shortcuts in `.opencode/commands/`. Keep command files thin: they should
route to KBD/OpenSpec or a skill, not duplicate requirements.

Prompt for command hygiene:

```text
When adding an OpenCode command, make it a route to the canonical skill or KBD
phase. Do not fork instructions across commands, docs, and skills.
```

## Named producer and critic agents

Use two agent roles for non-trivial changes:

| Agent | Purpose | Authority |
|---|---|---|
| producer | Implements the bounded task. | Local edits inside named files/directories. |
| critic | Compares output to requirements and evidence. | Read-only inspection and validation commands. |

Producer prompt:

```text
You are the producer agent. Implement only the next unchecked KBD task. Stay in
the allowed files. Run the nearest validator. Return changed files and command
output; do not certify completion.
```

Critic prompt:

```text
You are the critic agent. Do not edit files. Compare requirements, changed files,
and evidence. Fail the task if public-boundary proof, source citations, stop
conditions, or retention records are missing.
```

## Permissions

Use OpenCode allow/ask/deny policy to make authority visible:

- allow: read commands, formatters, local validators, and bounded file writes;
- ask: package installation, network research, GitHub changes, publishing,
  branch cleanup, and image pushes;
- deny: broad destructive commands, credential printing, and direct production
  deployment commands.

Permission prompt:

```text
Before executing, list which operations are allow, ask, and deny for this phase.
If a required operation is ask/deny, stop and request explicit direction instead
of widening authority.
```

## MCP and ACP

OpenCode MCP servers should be declared in project configuration and verified by
the running harness. ACP should be treated as a handoff/interoperability surface:
the ACP agent may not have the same skills, tools, or permissions as the
OpenCode native agent.

MCP/ACP prompt:

```text
Verify MCP server availability before tool-dependent work. If handing off to an
ACP agent, restate the task, allowed files, source documents, verification
commands, and stop conditions inside the handoff.
```

## Evidence capture

Retain:

- OpenCode command and agent summaries;
- validator output;
- rendered route or app evidence where relevant;
- KBD waypoint/task transitions;
- source URLs and access dates for researched facts.

Evidence prompt:

```text
Return evidence as file paths and command output. Any claim without evidence
must be labeled unverified and left out of completion criteria.
```

## Handoff

OpenCode handoff to another harness:

```text
Continue from repository state:
- phase: <phase-id>
- change: <change-id>
- next task: <task-id>
- producer evidence: <files and commands>
- critic findings: <pass/fail list>

Read AGENTS.md, the active KBD waypoint, and OpenSpec tasks before acting.
```

## Completion rule

OpenCode work is complete only after the producer finishes, the critic passes,
and the relevant public boundary has been exercised. A named agent's summary is
not enough by itself.
