---
title: entity-graph-web-shell
sidebar_label: entity-graph-web-shell
sidebar_position: 20
description: "Design or review a React web shell whose normalized application state is owned by Prometheus Entity Management, with components reading through hooks and an Axum boundary owning remote effects. Use for entity graphs, PEM transports, PGlite projections, web-shell layering, or normalized cross-view updates."
---

# entity-graph-web-shell

**Category:** Application architecture

## What it is for

Design or review a React web shell whose normalized application state is owned by Prometheus Entity Management, with components reading through hooks and an Axum boundary owning remote effects. Use for entity graphs, PEM transports, PGlite projections, web-shell layering, or normalized cross-view updates.

## Why it is designed this way

Normalized entity state must converge across views without making components aware of transports. PEM owns durable application state, hooks expose intent, and Axum owns remote effects and verified identity.

## Common use cases

- Build a React shell over PEM and PGlite
- Register entity transports and normalized cross-view updates
- Test offline replay, projection recovery, and tenant denial

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/entity-graph-web-shell <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Components must not call fetch, IPC, raw stores, or UAR directly.

## Canonical operating contract

Use this contract for browser shells that project a normalized entity graph.

## Invariants

1. Components import feature hooks, never transports, `fetch`, or raw stores.
2. Hooks select normalized entities and expose intent-oriented operations.
3. Register one transport per entity type. Every mutation returns canonical
   entities so all subscribed views converge.
4. PGlite is a local projection and offline queue, not an authorization source.
5. The Axum boundary derives tenant and actor identity from `VerifiedSession`.
6. Agent actions enter through the UAR gateway; UI code never owns agent
   lifecycle or tool execution.
7. Unknown entity kinds remain inspectable and do not disappear silently.

## Verification

- Assert components contain no direct network or IPC calls.
- Exercise create/update/delete across two subscribed views.
- Restart the shell and verify projection recovery.
- Deny cross-tenant reads and writes at the server boundary.
- Verify offline replay is idempotent and preserves causal order.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`skills/entity-graph-web-shell/SKILL.md`; generated scaffold and harness copies
must never be edited independently.
