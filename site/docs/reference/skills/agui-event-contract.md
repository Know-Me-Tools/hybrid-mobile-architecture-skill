---
title: agui-event-contract
sidebar_label: agui-event-contract
sidebar_position: 25
description: "Define or audit the AG-UI event stream between Universal Agent Runtime and application clients. Use for agent event envelopes, SSE resume, run correlation, tool approval state, cancellation, event persistence, or unknown-event compatibility."
---

# agui-event-contract

**Category:** Agent UI contracts

## What it is for

Define or audit the AG-UI event stream between Universal Agent Runtime and application clients. Use for agent event envelopes, SSE resume, run correlation, tool approval state, cancellation, event persistence, or unknown-event compatibility.

## Why it is designed this way

Streaming clients reconnect, duplicate messages, and observe partial failure. A versioned, replayable AG-UI envelope makes event application deterministic instead of inferring run state from prose or connection lifetime.

## Common use cases

- Expose UAR events over SSE
- Resume a run from Last-Event-ID
- Test duplicate, out-of-order, unknown, denied, or cancelled events

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/agui-event-contract <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

It does not define visual components; use a2ui-surface-contract or content-block-ui for rendering.

## Canonical operating contract

AG-UI is the runtime-to-application event boundary. UAR emits authoritative run
events; clients maintain projections.

## Envelope

Require protocol version, event ID, run ID, sequence, timestamp, event type,
typed payload, and optional causal parent. Event IDs are stable across retries.

## Semantics

- Apply events idempotently and in sequence.
- Resume streams with the last committed event ID.
- Represent approval, denial, cancellation, timeout, and failure explicitly.
- Keep tool inputs and outputs redacted according to policy.
- Preserve unknown event types without treating them as success.
- Never infer completion from prose.

Test disconnect/reconnect, duplicate and out-of-order events, restart recovery,
slow consumers, cancellation races, unknown versions, and projection replay.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`skills/agui-event-contract/SKILL.md`; generated scaffold and harness copies
must never be edited independently.
