---
sidebar_position: 5
title: Google Antigravity playbook
description: Use Google Antigravity with workspace/global skills, plugins, hooks, MCP, artifacts, approvals, version checks, and handoffs.
---

# Google Antigravity playbook

Use Google Antigravity when the work benefits from its workspace-oriented agent
environment, artifact surfaces, and SDK/CLI integrations. Treat Antigravity as a
capability-checked harness: verify the installed version and enabled features
before relying on a specific skill, plugin, hook, MCP server, or artifact action.

## Verified source map

This playbook is current as of `2026-07-18`. The machine-readable harness record
is `docs/prompting/data/harnesses/antigravity.json`.

| Behavior | Source |
|---|---|
| Antigravity documents workspace/global usage and core agent concepts. | [Antigravity docs home](https://antigravity.google/docs/home), accessed 2026-07-18 |
| Antigravity CLI features document command-line capability boundaries. | [Antigravity CLI features](https://antigravity.google/docs/cli/features), accessed 2026-07-18 |
| Antigravity artifacts document retained output and review surfaces. | [Antigravity artifacts](https://antigravity.google/docs/artifacts), accessed 2026-07-18 |

## Installation and version checks

```bash
antigravity --version
pwd
git status --short --branch
rg --files -g 'AGENTS.md' -g 'CLAUDE.md' -g '.antigravity/**' -g '.mcp.json'
```

If the installed CLI or SDK does not expose a documented feature, record the
version gap and avoid relying on that feature for completion evidence.

## Instruction discovery

Antigravity may combine workspace rules, global rules, and project skills. Start
by asking the active harness to show what it can see:

```text
List the workspace rules, global rules, project skills, plugins, hooks, MCP
servers, artifact destinations, and approval policy visible in this Antigravity
session. Then read the project instructions and only the skills required for the
current phase.
```

## Skills, plugins, and hooks

Use workspace skills for project-specific Prometheus rules and global skills for
general patterns. Plugins should be explicit dependencies in the phase prompt,
not assumed background capability.

Skill/plugin prompt:

```text
Use the project Prometheus skill if installed. If a required plugin or skill is
missing, report it as a capability gap and continue only with safe local work.
Do not replace a missing skill with invented instructions.
```

Hook prompt:

```text
Use hooks only for evidence capture, formatting/check enforcement, or safety
stops. Do not use hooks to bypass approvals or mutate requirements.
```

## MCP and SDK/CLI distinction

Keep CLI and SDK capabilities separate. A feature documented for the SDK is not
automatically available in the CLI, and a workspace UI artifact is not proof that
a command-line deployment succeeded.

MCP prompt:

```text
Verify MCP tools in the active Antigravity surface. Mark CLI-only, SDK-only, and
UI-artifact-only capabilities separately. Use each only where verified.
```

## Approvals and authority

Recommended authority split:

- local inspection and validation: allowed;
- local repository writes: allowed only inside the requested scope;
- artifact publication, repository pushes, cloud actions, and plugin
  installation: approval required;
- destructive cleanup: exact target and explicit user approval required.

Approval prompt:

```text
Before acting, classify each operation by approval need. Stop before any
publication, external write, or destructive action that is not explicitly
authorized.
```

## Artifacts and evidence

Antigravity artifacts are useful review objects, but they must be tied to
repository evidence:

- artifact URL or identifier;
- source files changed;
- command output;
- screenshot or rendered route when visual;
- KBD/OpenSpec task transition;
- sanitization result for public documentation.

Evidence prompt:

```text
For every artifact, record the source files and command that produced it. Do not
claim completion from an artifact preview unless the underlying public boundary
also runs.
```

## Handoff

Antigravity to another harness:

```text
Continue from repository state.

Artifact evidence: <artifact ids or screenshots>
Source changes: <files>
Commands run: <outputs>
Active phase/change/task: <ids>
Missing Antigravity-only capabilities: <if any>

Read the KBD waypoint and OpenSpec task list before continuing.
```

## Completion rule

Antigravity work is complete only when the installed capability surface was
verified, approvals were respected, artifacts are tied to source and command
evidence, and a public-boundary check passed.
