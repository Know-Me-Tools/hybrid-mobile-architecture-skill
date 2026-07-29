---
title: agent-runtime-security
sidebar_label: agent-runtime-security
sidebar_position: 26
description: "Enforce the security boundary around Universal Agent Runtime and governed tool execution. Use for MCP tools, approvals, effect classification, policy checks, agent budgets, JWT/JWKS identity, tenant isolation, audit logs, or cancellation."
---

# agent-runtime-security

**Category:** Runtime security

## What it is for

Enforce the security boundary around Universal Agent Runtime and governed tool execution. Use for MCP tools, approvals, effect classification, policy checks, agent budgets, JWT/JWKS identity, tenant isolation, audit logs, or cancellation.

## Why it is designed this way

Tool descriptions, model output, transport metadata, and client claims are all untrusted. The skill establishes one governed sequence for trust resolution, schema validation, effect classification, authorization, confirmation, bounded execution, and immutable audit.

## Common use cases

- Add or review an MCP-backed tool
- Implement approval, cancellation, timeout, or output limits
- Validate JWT/JWKS identity and tenant isolation around agent runs

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/agent-runtime-security <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

It does not define application-specific policy. Put roles, tenant rules, and release boundaries in the project policy overlay.

## Canonical operating contract

Application-facing code may request a tool only through UAR governance. Raw MCP
transport execution is internal.

## Governed tool sequence

1. Resolve a trusted server and tool identity.
2. Validate input against JSON Schema.
3. Classify effects independently of MCP annotations.
4. Evaluate policy with verified actor and tenant context.
5. Obtain explicit confirmation when policy requires it.
6. Execute with idempotency ID, timeout, output limit, and cancellation.
7. Validate and redact the result.
8. Append an immutable audit outcome.

MCP annotations are hints, never authorization. Tool names and descriptions are
untrusted data. Deny unknown servers, schemas, effects, and identities.

Authorization uses `VerifiedSession` created by signature, issuer, audience,
expiry, and revocation-aware validation. Decoded token hints are display-only.

Test forged tokens, prompt injection in tool metadata, schema bypass, replay,
SSRF, cancellation, output flooding, approval races, revoked keys, and
cross-tenant requests.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`templates/project-skills/agent-runtime-security/SKILL.md`; generated harness copies
must never be edited independently.
