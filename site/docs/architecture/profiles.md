---
sidebar_position: 2
title: Generation profiles
description: Choose a KnowMe Builder application profile and understand its runtime, UI, storage, and verification boundaries.
---

# Generation profiles

A profile is an architecture contract, not a starter-theme choice. It selects
surfaces, the UAR integration mode, generated templates, expected public
boundaries, and the acceptance suite.

The Builder requires a profile explicitly because guessing wrong can create a
second runtime, the wrong persistence authority, or an unsafe client boundary.

## Profile comparison

| Profile | Surfaces | UAR mode | Best for |
|---|---|---|---|
| `sovereign-hybrid` | Flutter mobile, Tauri/React desktop, Rust core | Embedded mobile; service/in-process desktop and web | Private, local-first products spanning phones and desktops |
| `governed-web-shell` | React shell, Axum BFF | Service | Tenant-governed business applications, entity graphs, legacy embedding, human release gates |
| `flutter-mobile` | Flutter and Rust | Embedded | Mobile-first local or field applications |
| `tauri-desktop` | Tauri/React and Rust | Service or in-process facade | Desktop local-agent and operator applications |
| `axum-web` | React and Axum | Service | Web-only governed agent applications |

## Runnable versus skeleton

`runnable` must provide a deterministic vertical slice:

```text
message
  → UAR run
  → model stream
  → governed tool
  → A2UI/AG-UI event
  → persisted projection
  → restart recovery
```

`skeleton` may contain unsupported surfaces or TODOs, but every gap must be
declared in the project manifest and generated documentation. A skeleton is not
a failed runnable profile; it is an explicit architecture starting point.

## `sovereign-hybrid`

Use this profile when users expect the application to work locally, preserve
private state on their devices, and expose native mobile and desktop
experiences.

Key decisions:

- Flutter owns mobile presentation.
- Tauri and React own desktop presentation.
- Rust owns shared application services and typed native adapters.
- UAR is embedded for mobile/local execution and exposed through a service or
  in-process facade where appropriate on desktop/web.
- Local stores are selected per tier; shared data and private vault data follow
  different sync lanes.
- Local inference engines are selected per device, not by a generic “mobile”
  switch.
- Native bridge and inference changes require physical-device evidence.

Common use cases include private assistants, offline field tools, personal
knowledge products, cross-device conversation applications, and products with
local model execution.

## `governed-web-shell`

Use this profile when the application is a browser shell around normalized
business entities and governed agent workflows.

Key decisions:

- React components read through feature hooks.
- PEM owns normalized durable entity state.
- PGlite is a local projection and offline queue, not authorization.
- Axum derives actor and tenant from verified identity.
- UAR owns runs, models, tools, approvals, and cancellation.
- Cedar or the selected project policy engine authorizes mutations and agent
  triggers.
- A2UI and AG-UI are typed projection/event boundaries.
- Legacy applications are embedded only through a versioned, origin-checked
  bridge.
- Project-local overlays define client roles and human release boundaries.

Common use cases include operations workspaces, document-generation systems,
regulated back-office tools, composable mini-app portals, and migrations that
must preserve a frozen legacy substrate.

## Component profiles

Use `flutter-mobile`, `tauri-desktop`, or `axum-web` when the product truly has
one delivery surface. They retain the same authority boundaries as the larger
profiles; they do not permit UI-owned agent loops or direct tool transport.

## Choosing a profile

Ask these questions in order:

1. Which user-visible surfaces must ship?
2. Must mobile operate without a local service process?
3. Is the product personal/local-first or tenant-governed?
4. Does an evolved application need adoption rather than generation?
5. Which physical platforms need release certification?

If answers span both major profiles, do not invent a new implicit profile.
Adopt the closest profile and record explicit project-local additions in the
policy overlay and generated ownership state.
