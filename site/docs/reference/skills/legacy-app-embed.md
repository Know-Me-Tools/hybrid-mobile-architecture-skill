---
title: legacy-app-embed
sidebar_label: legacy-app-embed
sidebar_position: 23
description: "Embed a frozen or independently deployed legacy application inside a governed shell through a versioned bridge. Use for iframe integration, postMessage protocols, origin validation, correlation IDs, compatibility negotiation, or frozen-substrate constraints."
---

# legacy-app-embed

**Category:** Integration boundaries

## What it is for

Embed a frozen or independently deployed legacy application inside a governed shell through a versioned bridge. Use for iframe integration, postMessage protocols, origin validation, correlation IDs, compatibility negotiation, or frozen-substrate constraints.

## Why it is designed this way

An embedded legacy application is an independently deployed, potentially hostile system. A versioned, capability-limited bridge prevents postMessage convenience from becoming an identity, tenant, policy, or runtime bypass.

## Common use cases

- Embed a frozen SSR application in a governed shell
- Define origin, source-window, version, and correlation checks
- Test replay, navigation, reload, timeout, and malformed messages

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/legacy-app-embed <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Never send credentials, trusted tenant IDs, policy decisions, database access, or raw runtime handles through the bridge.

## Canonical operating contract

Treat the embedded application as an untrusted external system.

## Bridge contract

- Pin allowed origins and bridge versions.
- Use a discriminated, schema-validated message envelope.
- Require request, correlation, and session IDs.
- Validate origin, source window, version, message type, and payload before use.
- Permit only explicitly declared capabilities.
- Time out requests and make mutating requests idempotent.
- Keep authentication tokens, tenant IDs, and policy decisions out of messages.
- Record redacted bridge outcomes for audit.

The host may translate authorized intent into its own BFF or UAR calls. The
embedded app never receives raw runtime, database, or tool-governance access.

Test hostile origins, replay, malformed payloads, unknown versions, navigation
away, reload during an in-flight request, and duplicate responses.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`skills/legacy-app-embed/SKILL.md`; generated scaffold and harness copies
must never be edited independently.
