---
sidebar_position: 6
title: Zed playbook
description: Use Zed native agents, ACP external agents, and terminal threads with clear permissions, MCP/skills boundaries, review, evidence, and handoff.
---

# Zed playbook

Use Zed when you want agent work close to the editor, code review, terminal
threads, or ACP-backed external agents. The key rule is to distinguish the three
paths: Zed native Agent Panel, ACP external agents, and terminal CLI threads do
not necessarily share the same tools, permissions, skills, or memory.

## Verified source map

This playbook is current as of `2026-07-18`. The machine-readable harness record
is `docs/prompting/data/harnesses/zed.json`.

| Behavior | Source |
|---|---|
| Zed documents the native AI/agent surface. | [Zed AI overview](https://zed.dev/docs/ai/overview), accessed 2026-07-18 |
| Zed supports external agents. | [Zed external agents](https://zed.dev/docs/ai/external-agents), accessed 2026-07-18 |
| Zed documents MCP configuration. | [Zed MCP](https://zed.dev/docs/ai/mcp), accessed 2026-07-18 |
| ACP defines an agent-client protocol for external agent integration. | [Agent Client Protocol](https://zed.dev/acp), accessed 2026-07-18 |

## Installation and version checks

```bash
zed --version
pwd
git status --short --branch
rg --files -g 'AGENTS.md' -g '.zed/**' -g '.mcp.json' -g '.agents/skills/**/SKILL.md'
```

If the work is in a terminal thread, also check the CLI tool driving the thread:

```bash
codex --version || true
claude --version || true
opencode --version || true
kimi --version || true
```

## Choose one Zed path

| Path | Use when | Evidence |
|---|---|---|
| Native Agent Panel | Editor-integrated edits, review, and context from open files. | Changed files, Zed review notes, command output. |
| ACP external agent | You need an external agent implementation with Zed UI mediation. | ACP transcript summary, changed files, command output. |
| Terminal thread | You need a CLI harness such as Codex, Claude Code, OpenCode, or Kimi. | CLI transcript summary, changed files, command output. |

Selection prompt:

```text
Pick exactly one Zed execution path for this task: native Agent Panel, ACP
external agent, or terminal thread. State which tools and permissions are
available in that path and which capabilities are unavailable.
```

## Instruction discovery

All paths must use repository files as authority:

```text
Read AGENTS.md and the active KBD/OpenSpec files. If using an ACP or terminal
agent, also read that harness's project instructions and skills. Summarize the
active task, allowed writes, verification command, and handoff files.
```

## Skills and MCP

Zed native MCP settings and an external agent's MCP settings are separate. A
terminal-thread CLI has its own tool discovery rules. Verify before use:

```text
Show which MCP servers and skills are visible in the selected Zed path. If a
required skill is not visible, either switch paths explicitly or use repository
files manually and record the gap.
```

## Permissions

Use narrow permissions:

- native editor edits: current repository and task scope only;
- terminal commands: read and validation commands first, writes only after
  planning;
- ACP external agent: explicit allowed files and stop conditions;
- external publication: separate approval;
- destructive cleanup: exact target and explicit approval.

Permission prompt:

```text
Classify operations by Zed path. Do not assume an ACP or terminal agent inherits
native Zed permissions. Stop before external writes or destructive operations.
```

## Review and evidence

Zed is strong for code review, but review comments are not verification. Pair
review with public-boundary evidence.

Evidence prompt:

```text
Return:
- selected Zed path;
- changed files;
- review findings;
- commands run;
- public-boundary result;
- unresolved capability gaps.
```

## Thread handoff

Handoff from Zed to another harness:

```text
Selected Zed path: <native | ACP | terminal>
Active phase/change/task: <ids>
Files changed: <paths>
Review findings: <summary>
Commands run: <outputs>
Next unchecked task: <task>
Capability gaps: <if any>

Continue from repository state and KBD waypoint files.
```

## Completion rule

Zed work is complete only when the selected path is explicit, tool/permission
limits are clear, public-boundary evidence exists, and another review pass checks
the work against the original requirements.
