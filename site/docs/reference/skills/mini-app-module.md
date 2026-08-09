---
title: mini-app-module
sidebar_label: mini-app-module
sidebar_position: 21
description: "Add or review a self-contained mini-application module inside a governed web shell. Use for route modules, feature manifests, capability declarations, navigation registration, module policy, lazy loading, or independently testable applets."
---

# mini-app-module

**Category:** Application architecture

## What it is for

Add or review a self-contained mini-application module inside a governed web shell. Use for route modules, feature manifests, capability declarations, navigation registration, module policy, lazy loading, or independently testable applets.

## Why it is designed this way

A folder of components is not a removable product boundary. A versioned module manifest makes routes, entities, capabilities, policy actions, events, and migrations explicit so the shell can validate, isolate, lazy-load, upgrade, or disable the module.

## Common use cases

- Add a governed applet to a web shell
- Register routes, entities, navigation, capabilities, or migrations
- Test isolation, permission denial, lazy-load failure, and disablement

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/mini-app-module <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Do not allow modules to import each other's internal stores, components, or transports.

## Canonical operating contract

A mini-app is a versioned feature boundary, not an arbitrary component folder.

## Required manifest

Declare a stable module ID, version, routes, entity types, required
capabilities, policy actions, event contracts, and optional migrations. The
shell validates this manifest before mounting the module.

## Boundaries

- Presentation depends on domain interfaces.
- Data adapters implement domain interfaces and register with the shell.
- Cross-module communication uses typed events or shared entity references.
- A module cannot import another module's internal store or component tree.
- Server mutations require verified identity and policy enforcement.
- Agent triggers call the governed UAR gateway.
- Capability requests are deny-by-default.

## Done

Test manifest rejection, lazy-load failure, route isolation, entity cleanup,
permission denial, and upgrade compatibility. A module is complete only when it
can be disabled without breaking the host shell.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`skills/mini-app-module/SKILL.md`; generated scaffold and harness copies
must never be edited independently.
