---
title: a2ui-surface-contract
sidebar_label: a2ui-surface-contract
sidebar_position: 24
description: "Implement or review A2UI-driven surfaces that render governed agent output as typed projections. Use for A2UI components, action continuation, dynamic forms, generated UI state, approval surfaces, or cross-platform rendering parity."
---

# a2ui-surface-contract

**Category:** Agent UI contracts

## What it is for

Implement or review A2UI-driven surfaces that render governed agent output as typed projections. Use for A2UI components, action continuation, dynamic forms, generated UI state, approval surfaces, or cross-platform rendering parity.

## Why it is designed this way

A2UI is deliberately a projection protocol. Keeping execution authority out of the renderer prevents generated UI, approval components, and action continuations from bypassing UAR governance.

## Common use cases

- Render typed agent-generated forms or components
- Continue an A2UI action after restart
- Handle unknown component types, approval state, or cancellation consistently

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/a2ui-surface-contract <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Do not use it to select models, execute tools, or make policy decisions in a client.

## Canonical operating contract

A2UI describes a projection. It does not grant authority.

## Rules

- Parse a versioned discriminated event envelope.
- Render only registered component types and validated props.
- Preserve unknown events as inspectable artifacts.
- Route actions back through UAR with run, event, and idempotency IDs.
- Show pending approval, cancellation, denial, failure, and resumed states.
- Never execute tool calls, provider routing, or policy decisions in the UI.
- Sanitize rich content and external URLs.
- Apply accessibility and platform design-token contracts.

Verify deterministic rendering, action continuation after restart, duplicate
event handling, unknown event display, cancellation, denied actions, malformed
props, and equivalent semantics across supported surfaces.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`templates/project-skills/a2ui-surface-contract/SKILL.md`; generated harness copies
must never be edited independently.
