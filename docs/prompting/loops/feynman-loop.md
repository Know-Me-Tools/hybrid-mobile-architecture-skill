---
sidebar_position: 1
title: Feynman learning loop
description: A repeatable explain, grade, gap, re-study, transfer, and retain loop for Prometheus application work.
---

# Feynman learning loop

Use the Feynman loop before architecture decisions, unfamiliar platform work, or
skill creation. The goal is not a polished essay. The goal is to expose what the
agent does not understand before it writes code or instructions that look
confident but fail in practice.

## Invocation

```text
Run a Feynman loop before planning.

Topic: <the architecture, API, harness, deployment target, or UI system>
Decision to unblock: <what we must decide>
Sources available: <docs, source files, official URLs, examples>
Output:
1. Explain the concept plainly.
2. State the assumptions.
3. Grade the explanation with the rubric.
4. List gaps and contradictions.
5. Re-study only the gaps using primary sources.
6. Transfer the corrected understanding into implementation rules.
7. Record retained lessons and the next KBD waypoint.
```

## Grade rubric

Score each category from 0 to 2.

| Category | 0 | 1 | 2 |
|---|---|---|---|
| Plain explanation | Jargon or vague claims. | Mostly clear but incomplete. | Clear enough for a new engineer to repeat. |
| Source grounding | No source or memory-only. | Mixed source quality. | Primary/local source evidence for important claims. |
| Failure awareness | Ignores likely failure modes. | Mentions generic risks. | Names concrete failure modes and mitigations. |
| Transferability | Does not affect the plan. | Produces broad advice. | Produces exact rules, files, commands, or tests. |
| Verification | No proof path. | Mentions checks. | Defines observable public-boundary evidence. |

Minimum pass: 8/10 with no 0 in source grounding or verification.

## Failure branch

If the loop fails:

```text
The Feynman loop did not pass.

Failed categories: <list>
Blocking gaps: <list>
Next action:
- research only the gaps;
- update source citations;
- rerun the explanation;
- do not implement until the minimum score passes.
```

If the same gap repeats twice, create or update a skill candidate instead of
forcing the current agent to improvise. Repeated gaps are system-learning
signals.

## Closure evidence

The loop closes only when it produces:

- a scored explanation;
- source links or local source paths for the important claims;
- a short list of implementation rules;
- the public-boundary evidence required later;
- the next KBD waypoint or OpenSpec task.

Closure prompt:

```text
Close the Feynman loop by writing:
- final score;
- corrected explanation;
- rules that change implementation;
- evidence that will prove success;
- next waypoint.
```

## Example: web, desktop, and mobile persistence

Prompt:

```text
Explain why the KnowMe reference app should use client-side PGlite with
Prometheus Entity Management and Zustand on web, pglite-oxide/shared Rust for
desktop, and Flutter providers over direct UI persistence on mobile. Grade the
explanation, find gaps, and transfer the result into implementation rules.
```

Expected transfer:

- React components call hooks, hooks use stores, stores use Prometheus Entity
  Management over PGlite-backed persistence.
- Tauri commands delegate persistence to the shared Rust layer and pglite-oxide
  where configured.
- Flutter screens call Riverpod providers; domain/data layers own note,
  conversation, and sync behavior.
- No TanStack Query is introduced for Prometheus-owned entity state.
- Verification must create, reload, and return to multiple conversations.

## Next waypoint rule

Every Feynman loop must end by naming the next execution step:

```text
Next waypoint: /kbd-<stage> <phase-or-change>
Next task: <one bounded task>
Stop condition: <observable evidence>
```

Without a next waypoint, the loop is learning theater rather than operational
learning.
