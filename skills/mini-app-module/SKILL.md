---
name: mini-app-module
description: Add or review a self-contained mini-application module inside a governed web shell. Use for route modules, feature manifests, capability declarations, navigation registration, module policy, lazy loading, or independently testable applets.
---

# Mini-App Module

A mini-app is a versioned feature boundary, not an arbitrary component folder.

## Required manifest

Declare a stable module ID, version, routes, entity types, required
capabilities, policy actions, event contracts, and optional migrations. The
shell validates this manifest before mounting the module.

## Seeding from a KnowDesign prototype

A working htmx + Alpine prototype from KnowDesign ships `od-prototype.json`
(routes, components, UI state, entities, token roles). Use it as the starting
point for the manifest instead of reverse-engineering screens:

- routes become the module's routes and its repository contract;
- entities become entity types;
- `HX-Trigger` events become event contracts;
- token roles go to `hybrid-design-tokens`.

The full field mapping is in `references/od-prototype-mapping.md`. The
prototype carries no identity or policy, so capabilities and policy actions
are always added by hand.

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
