---
title: axum-agent-gateway
sidebar_label: axum-agent-gateway
sidebar_position: 22
description: "Implement or audit an Axum boundary between an application and Universal Agent Runtime. Use for agent HTTP or SSE routes, verified identity, tenant derivation, Cedar authorization, cancellation, idempotency, event streaming, or UAR service integration."
---

# axum-agent-gateway

**Category:** Runtime and service boundaries

## What it is for

Implement or audit an Axum boundary between an application and Universal Agent Runtime. Use for agent HTTP or SSE routes, verified identity, tenant derivation, Cedar authorization, cancellation, idempotency, event streaming, or UAR service integration.

## Why it is designed this way

The browser must not become an agent runtime or authorization boundary. The Axum gateway derives verified identity, applies policy, submits bounded UAR commands, and streams typed results through a server-controlled boundary.

## Common use cases

- Add authenticated run and cancellation endpoints
- Stream AG-UI/A2UI events from UAR to a web client
- Enforce tenant derivation, idempotency, policy denial, and slow-consumer behavior

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/axum-agent-gateway <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Do not expose raw MCP execution, caller-selected tenants, or provider routing through the gateway.

## Canonical operating contract

The gateway authenticates and governs application requests; UAR remains the
agent runtime authority.

## Request sequence

1. Validate request shape and size.
2. Resolve `VerifiedSession` from server-side validation.
3. Derive tenant, actor, and allowed persona from the verified session.
4. Authorize the action and resource with the project policy engine.
5. Submit an idempotent run command to UAR with bounded budgets.
6. Stream typed AG-UI/A2UI events with correlation and resume IDs.
7. Propagate disconnect or explicit cancel to UAR.
8. Persist an immutable, redacted outcome.

Never accept caller-selected tenants, trusted roles, provider routes, or raw
tool permissions. Never execute an MCP transport directly.

## Tests

Cover forged/expired/wrong-audience credentials, cross-tenant access,
idempotent retries, cancellation, slow consumers, unknown events, policy
denial, and restart/resume from the last event ID.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`skills/axum-agent-gateway/SKILL.md`; generated scaffold and harness copies
must never be edited independently.
