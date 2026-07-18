---
sidebar_position: 1
title: Codex playbook
description: Run Prometheus application-building loops in Codex with explicit authority, project skills, bounded goals, evidence, and handoffs.
---

# Codex playbook

Codex is the best default harness for repository-centered Prometheus work when
the task needs local file edits, tool-controlled verification, plugin discovery,
parallel-but-owned work, and a durable written handoff. Treat Codex as an
engineering operator: give it a concrete outcome, authority boundaries, and the
public evidence that will prove the work.

## Verified source map

This playbook is current as of `2026-07-18`. The machine-readable harness record
is `docs/prompting/data/harnesses/codex.json`.

| Behavior | Source |
|---|---|
| Skills are reusable instruction packages that can be discovered and invoked by Codex. | [OpenAI Codex skills documentation](https://developers.openai.com/codex/build-skills), accessed 2026-07-18 |
| `AGENTS.md`, project skill directories, goals, plugin search, commentary/final channels, and git directives are available in this repository's installed Codex desktop environment. | Local observation, recorded in `docs/prompting/data/harnesses/codex.json` |

If a behavior is not visible in the current Codex environment, label it
unavailable and route through a different harness or a manual command. Do not
invent a plugin, MCP server, permission mode, or publishing capability.

## Installation and version checks

Start every Codex phase by confirming the repository context and configured
tooling:

```text
Read AGENTS.md and CLAUDE.md in full.
Report the repository path, branch, dirty files, active sandbox/approval policy,
available relevant skills, and the exact verification commands you will run.
Do not edit files until that inventory is complete.
```

For this repository, the minimum useful check is:

```bash
pwd
git status --short --branch
rg --files -g 'AGENTS.md' -g 'CLAUDE.md' -g '.codex/config.toml' -g '.agents/skills/**/SKILL.md'
```

Use `tool_search` before claiming a plugin or connector is absent. If a named
plugin is not installed and a recommended installation exists, ask through the
plugin installation flow rather than faking the capability.

## Instruction discovery

Codex must follow the nearest applicable instructions in this order:

1. system and developer instructions from the running Codex environment;
2. repository `AGENTS.md`;
3. referenced project standards such as `CLAUDE.md`, architecture documents, and
   OpenSpec or KBD phase files;
4. activated skill `SKILL.md` files, read in full before using the skill;
5. user prompt authority for the current task.

Copyable discovery prompt:

```text
Before doing implementation, discover the active instruction stack:

- read AGENTS.md and CLAUDE.md;
- list relevant project-local skills under .agents/skills;
- read only the SKILL.md files needed for this task;
- inspect current KBD/OpenSpec waypoint files if a phase is active;
- summarize authority boundaries and verification gates in 10 lines or fewer.
```

## Skills and plugins

Use project-local skills for repeatable Prometheus work instead of ad hoc
instructions. In this repository, Codex reads `.agents/skills/`; `.codex/skills/`
may also exist for compatibility with other installations, but `.agents/skills/`
is the project-local source to verify first.

Common routing:

| Need | Codex action |
|---|---|
| Build or revise app architecture | Use `orchestrate-prometheus-application` and KBD phase artifacts. |
| Prove a hybrid app works | Use `hybrid-runtime-verification`. |
| Build branded documentation | Use `build-branded-docusaurus`. |
| Preserve durable lessons | Use `karpathy-progress-memory`. |
| Fix UI fidelity | Use `reference-ui-fidelity`, `hybrid-design-tokens`, and surface-specific UI skills. |
| Create missing repeatable knowledge | Use `skill-creator` only after the gap repeats or blocks a phase. |

Plugin prompt:

```text
Use plugin/tool discovery for any requested external connector. If the connector
is unavailable, report the missing capability and continue only with local
repository work that does not require it.
```

## MCP configuration

Codex project MCP configuration is repository-owned when present. In this
repository, inspect `.codex/config.toml` and the active tool list before assuming
Dart, Flutter, shadcn, browser, GitHub, or web-search tools are callable.

MCP usage rule:

```text
Before using an MCP-dependent workflow, list the actual callable tools or run the
project's MCP doctor command. If the expected server is absent, record the gap and
continue with local commands only where safe.
```

## Permissions and authority

Codex can often read broadly and run local verification, but external writes
remain separate authority. Keep these boundaries explicit:

- local file edits inside the requested repository are allowed for implementation
  tasks;
- commits and pushes require user authorization unless already granted in the
  active request;
- deleting branches, worktrees, remotes, data, or published artifacts requires
  exact target confirmation unless the plan already grants it;
- plugin installation, email/calendar actions, cloud publication, and GitHub PR
  changes are external-state actions and need matching tool authority;
- private wiki logs are never published as raw documentation.

Authority prompt:

```text
State what you are authorized to change, what you will only inspect, and what
requires another explicit instruction. Then implement only inside that boundary.
```

## Planning, bounded tasks, and goals

Use Codex goals only when the user explicitly asks to persist toward an outcome.
For KBD phases, the KBD waypoint files are the source of truth; do not generate a
new plan over an active execution state.

Good bounded implementation prompt:

```text
Execute the next KBD task only.

Inputs:
- phase: build-detailed-prompting-guide
- change: prompting-guide-harness-loops
- task: the next unchecked item in openspec/changes/<change>/tasks.md

Rules:
- read .kbd-orchestrator/position-reminder.txt first;
- use the KBD apply driver to begin and end the task;
- update docs and validators together;
- run the smallest relevant verification;
- stop after the task is checked and summarize evidence.
```

For non-KBD work:

```text
Break this into 3-7 bounded steps. Keep one step in progress at a time. After
each implementation step, run the nearest public-boundary or content validator.
Do not call the work complete until a separate critic checks the original
requirements against the evidence.
```

## Evidence capture

Completion requires evidence at the boundary the user cares about:

- docs: schema validation, sanitization, link/build result, served route if
  publication is claimed;
- app UI: screenshot or browser inspection plus console/runtime logs;
- CLI/package: command output and clean checkout proof;
- deployment: rendered manifests, image digests, SBOM/provenance references, and
  smoke-test output;
- skill: scratch-project activation and verification transcript.

Codex evidence prompt:

```text
For every claim in the final answer, attach the evidence type:
command output, changed file, generated artifact, screenshot, deployed URL, or
explicitly labeled unverified assumption. If evidence is missing, do not claim
completion.
```

## Interruption and resume

Codex tasks may span context compaction or user interruptions. The durable resume
path is repository state, not hidden chat memory.

Keep these files current during KBD work:

- `.kbd-orchestrator/current-waypoint.json`
- `.kbd-orchestrator/position-reminder.txt`
- `.kbd-orchestrator/phases/<phase>/progress.json`
- `openspec/changes/<change>/tasks.md`
- the reviewed project memory wiki for retained lessons

Resume prompt:

```text
Resume from repository state, not memory. First read
.kbd-orchestrator/position-reminder.txt, current-waypoint.json, the active
OpenSpec tasks.md, and git status. Continue only the next unchecked task.
```

## Handoff examples

### Handoff to another Codex task

```text
You are taking over phase build-detailed-prompting-guide.

Read first:
- AGENTS.md
- .kbd-orchestrator/position-reminder.txt
- .kbd-orchestrator/current-waypoint.json
- openspec/changes/<active-change>/tasks.md

Continue exactly one unchecked KBD task. Preserve .prometheus records, run the
nearest validator, and stop with a compact evidence summary.
```

### Handoff from Codex to Claude Code or OpenCode

```text
Repository state is authoritative.

Current phase:
- phase: <phase-id>
- active change: <change-id>
- next unchecked task: <task-id and title>

Do not trust the conversation alone. Read the KBD waypoint files, OpenSpec task
list, and changed files. Continue with your harness-native skills and return
evidence as committed files plus command output.
```

## Critic pass

After Codex produces an implementation, run an independent critic:

```text
Act as the critic, not the producer.

Compare the original request, KBD/OpenSpec requirements, changed files, and
verification output. Identify:
- missing requested scenarios or harnesses;
- unsupported capability claims;
- stale model or source facts;
- missing public-boundary proof;
- private content leakage;
- incomplete Karpathy/KBD retention.

Return PASS only if every requirement has evidence.
```

The producer may fix critic findings, but the corrected work still needs the
same validator or public-boundary proof.
