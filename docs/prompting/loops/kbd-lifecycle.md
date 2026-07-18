---
sidebar_position: 2
title: KBD lifecycle
description: A file-backed KBD lifecycle for assess, analyze, spec, plan, execute, apply, verify, retain, and recover loops.
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

## Waypoint and handoff files

Use repository files as the source of truth:

- `.kbd-orchestrator/current-waypoint.json`
- `.kbd-orchestrator/position-reminder.txt`
- `.kbd-orchestrator/phases/<phase>/progress.json`
- `.kbd-orchestrator/phases/<phase>/handoffs/*.handoff.json`
- `openspec/changes/<change>/tasks.md`
- `openspec/changes/<change>/specs/**/spec.md`

Resume prompt:

```text
Read the position reminder first. Then read the current waypoint, phase
progress, active OpenSpec tasks, and git status. Continue the next unchecked task
only. Do not regenerate assessment, analysis, spec, or plan unless the waypoint
is missing or invalid.
```

## Recovery for missing handoffs

If a handoff file is missing but the phase files exist:

```text
Recover KBD state from:
1. current-waypoint.json
2. phase progress.json
3. openspec/changes/*/tasks.md
4. git status and changed files
5. latest reviewed memory entry

Recreate only the missing handoff summary. Do not rewrite completed phase
artifacts unless they are internally inconsistent.
```

If the waypoint and progress disagree, stop and create a recovery note:

```text
KBD state conflict:
- waypoint says: <state>
- progress says: <state>
- tasks say: <state>
- safest next action: <one repair>
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
