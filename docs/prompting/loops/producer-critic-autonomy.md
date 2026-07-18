---
sidebar_position: 4
title: Producer, critic, autonomy, and generation loops
description: Use separated producer/critic roles, anti-sycophancy checks, autonomous guardrails, recovery, skill generation, and native-agent generation.
---

# Producer, critic, autonomy, and generation loops

Prometheus work should separate production from certification. The producer
builds. The critic grades against requirements and evidence. Autonomous loops
run only inside bounded authority. Repeated gaps become skills or native agents
only after the gap is real, repeatable, and verified.

## Producer and critic split

Producer prompt:

```text
You are the producer. Implement the next bounded task only.

Inputs:
- requirement: <verbatim requirement>
- active phase/change/task: <ids>
- allowed files: <paths>
- required sources: <docs or URLs>
- verification: <commands>

Return changed files and command output. Do not certify completion.
```

Critic prompt:

```text
You are the critic. Do not edit files.

Compare:
- original requirement;
- phase/spec/task requirements;
- changed files;
- verification output;
- public-boundary evidence.

Fail if anything is missing, unsupported, private, unverified, or outside
authority. Return PASS only with evidence.
```

## Cross-model anti-sycophancy

Use a different model or harness for critic work when the stakes justify it.
The critic must be rewarded for finding real defects, not agreeing with the
producer.

Anti-sycophancy prompt:

```text
Assume the implementation may be incomplete. Find the strongest evidence that it
does not meet the requirement. Do not praise effort. Cite exact missing files,
commands, docs, or behavior. If it passes, explain why each requirement has
evidence.
```

## Autonomous development loop

```text
Loop:
1. Read instructions and active waypoint.
2. Select one bounded task.
3. State authority and stop conditions.
4. Implement.
5. Run nearest validator.
6. If it fails, correct at most twice.
7. Run critic.
8. Retain evidence.
9. Advance waypoint.
```

Stop immediately when:

- authority is missing;
- the same blocker repeats twice;
- the verification target is ambiguous;
- the task would require publishing, deletion, or remote mutation not granted;
- source evidence contradicts the plan;
- private content would leak into public docs.

## Recovery loop

```text
Recover:
1. Read git status.
2. Read waypoint/progress/task files.
3. List changed files by owner and purpose.
4. Identify last passed verification.
5. Identify the next unchecked task.
6. Continue only if state is consistent.
7. Otherwise write a recovery note and stop.
```

Never recover by resetting or deleting work unless the user explicitly asks and
the exact target is known.

## Skill-generation loop

Generate or update a skill when a capability gap is repeatable:

```text
Skill trigger:
- same process gap appears in two phases; or
- missing knowledge causes a failed verification; or
- operators need to repeat the workflow in generated projects.

Skill creation:
1. Define invocation conditions.
2. Define required inputs.
3. Encode the process and stop conditions.
4. Add verification and scratch-project test.
5. Install into supported harness skill directories.
6. Retain a usage note.
```

Do not create a skill for one-off prose, unsupported technology, or unverified
model claims.

## Native-agent-generation loop

Use the native-agent creator when the missing capability needs its own runtime,
protocol surface, or long-running service.

Native-agent prompt:

```text
Create a native agent only if a skill is insufficient.

Agent purpose: <bounded product capability>
Interfaces: <CLI, MCP, ACP, AG-UI, A2A, HTTP>
Runtime: <Rust/Axum or other justified stack>
Persistence: <required store>
Security: <auth and secret boundary>
Verification:
- build;
- protocol smoke test;
- public API test;
- packaging test.
```

The OpenAI-compatible proxy case study belongs in scenario documentation: it
shows how a generator can produce an Axum service with protocol adapters,
skills, memory, and packaging. Do not copy stale auth or model catalogs from a
case study into current public guidance.

## Closure rule

The loop closes only when:

- producer evidence exists;
- critic pass exists;
- failed assumptions are recorded;
- repeated gaps are routed to skill or native-agent work;
- stop conditions were obeyed;
- public-boundary verification passed.
