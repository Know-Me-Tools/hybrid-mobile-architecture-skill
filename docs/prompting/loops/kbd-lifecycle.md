---
sidebar_position: 2
title: KBD lifecycle
description: A canonical Prometheus KBD lifecycle for assess, analyze, spec, plan, execute, apply, verify, retain, and recover loops.
---

# KBD lifecycle

KBD is the control loop for Prometheus work. It keeps the agent from jumping
from a vague request to sprawling implementation by forcing assessment,
analysis, specification, planning, bounded execution, verification, and retained
learning.

## Stage sequence

```text
/kbd-init
→ /kbd-new-phase <phase-id>
→ /kbd-assess <phase-id>
→ /kbd-analyze <phase-id>
→ /kbd-spec <phase-id>
→ /kbd-plan <phase-id>
→ /kbd-execute <phase-id>
→ /kbd-apply <change-id>
→ /kbd-verify <phase-id>
→ /kbd-reflect <phase-id>
```

Do not skip forward because implementation seems obvious. If the phase already
has an active waypoint, continue the recorded state rather than creating a
parallel plan.

## Stage gates

| Stage | Exit evidence |
|---|---|
| init | repository has KBD/OpenSpec directories and command routing. |
| new phase | phase directory, goals, prior context, and waypoint exist. |
| assess | user goal, constraints, non-goals, risks, and missing information are recorded. |
| analyze | source research, local-code findings, official-source facts, and contradictions are recorded. |
| spec | OpenSpec changes contain requirements and scenario deltas. |
| plan | changes are ordered with dependencies, tasks, and verification gates. |
| execute | execution dispatch selects the backend and first change. |
| apply | one OpenSpec task advances at a time with before/after hooks. |
| verify | evidence is compared against requirements by a critic. |
| reflect | retained lessons and process improvements are recorded. |

## Canonical status and handoff

Use the Prometheus control plane as the source of truth:

```bash
prometheus kbd status --json
prometheus kbd audit
prometheus kbd watch
```

`current-waypoint.json`, `progress.json`, `position.json`, and reminders are
read-only compatibility projections. Never edit them to change lifecycle,
ownership, or work position. OpenSpec requirements remain durable review
artifacts, while state transitions use typed `prometheus kbd` commands.

Resume prompt:

```text
Run `prometheus kbd status --json`, then inspect the active OpenSpec task and git
status. Claim the mutation lease before writing. Continue only the exact
committed revision and task. Do not regenerate assessment, analysis, spec, or
plan unless an explicit plan revision supersedes it.
```

## Recovery for missing handoffs

If a compatibility projection or handoff export is missing:

```text
1. Run `prometheus kbd status --json`.
2. Run `prometheus kbd audit --since <known-revision-or-event>`.
3. Inspect the active OpenSpec task and git status.
4. Regenerate compatibility projections from canonical event replay.
5. Never reconstruct authority by editing JSON files.
```

If a projection disagrees with canonical status, pause and audit:

```text
prometheus kbd pause --reason "compatibility projection mismatch"
prometheus kbd audit
prometheus kbd migrate --check
```

## End-to-end phase example

```text
/kbd-new-phase build-detailed-prompting-guide
/kbd-assess build-detailed-prompting-guide
/kbd-analyze build-detailed-prompting-guide
/kbd-spec build-detailed-prompting-guide
/kbd-plan build-detailed-prompting-guide
/kbd-execute build-detailed-prompting-guide
/kbd-apply prompting-guide-foundation
/kbd-apply prompting-guide-harness-loops
/kbd-apply prompting-guide-scenario-recipes
/kbd-apply prompting-guide-agent-orchestration
/kbd-apply prompting-guide-publication-gates
/kbd-verify build-detailed-prompting-guide
/kbd-reflect build-detailed-prompting-guide
```

Each `/kbd-apply` handles one unchecked task at a time:

```text
begin task
→ edit files
→ run nearest validator
→ record evidence
→ end task
```

## Failure branches

| Failure | Response |
|---|---|
| Validator fails | Fix the implementation or docs, rerun the same validator, and record the failed command. |
| User changes requirements | Update assessment/spec/plan only where the requirement changes; keep completed evidence. |
| Missing tool | Record the gap, use an installed equivalent only if it preserves the requirement, or stop. |
| Source conflict | Prefer official/current source; label local observation separately. |
| Repeated blocker | Stop after two repeated failures and ask for a decision or create a skill-improvement task. |

## Completion rule

KBD completion requires:

- all OpenSpec tasks checked;
- strict OpenSpec validation;
- content/app/deployment validators for the changed surface;
- public-boundary evidence;
- critic pass;
- retained project memory;
- clean commit/push when requested.
