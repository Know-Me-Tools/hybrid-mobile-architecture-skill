---
sidebar_position: 7
title: Skills
description: Complete index and usage model for all 30 public KnowMe Builder Agent Skills.
---

# The 30 public Builder skills

KnowMe Builder publishes one package-level `hybrid-mobile-architecture` skill
and 29 project companions for Claude Code, Codex, OpenCode, and compatible Agent
Skills clients. Each skill is deliberately
narrow: it protects one architectural, security, data, design, delivery, or
verification boundary.

## How skills work

The harness discovers a skill from its `name` and `description`, then reads the
body when the task matches. Invoke one explicitly when the boundary is
important:

```text
/agent-runtime-security Review this MCP-backed tool.
/hybrid-runtime-verification Prove the Android lane works on a device.
```

Activation adapters may recommend a skill from prompt terms. They are
advisory. They cannot mutate Prometheus project identity, signed KBD state,
claims/conflicts, or lifecycle, and cannot force a session to continue.

## Package routing skill

| Skill | Use it when |
|---|---|
| `hybrid-mobile-architecture` | Selecting a Builder profile, adopting an evolved application, or applying the overall Flutter/Tauri/React/Axum/Rust architecture |

## Quality and release gates

| Skill | Use it when |
|---|---|
| [a11y-gate](./skills/a11y-gate) | Completing UI work; verify WCAG 2.2 AA, keyboard, semantics, contrast, motion, and streaming announcements |
| [flutter-golden-ui](./skills/flutter-golden-ui) | Completing a Flutter widget/screen; capture deterministic production-theme goldens |
| [tauri-ui-review](./skills/tauri-ui-review) | Completing React/Tauri UI; review four widths in both themes |
| [reference-ui-fidelity](./skills/reference-ui-fidelity) | Implementing from a prototype, screenshot, design file, mood board, or specification |
| [hybrid-runtime-verification](./skills/hybrid-runtime-verification) | Making any working, ready, or shippable claim |

## Agent UI and runtime

| Skill | Use it when |
|---|---|
| [a2ui-surface-contract](./skills/a2ui-surface-contract) | Rendering typed generated UI and continuing actions |
| [agui-event-contract](./skills/agui-event-contract) | Designing runtime event streams, SSE resume, ordering, or recovery |
| [content-block-ui](./skills/content-block-ui) | Rendering or adding a rich agent-output variant |
| [agent-runtime-security](./skills/agent-runtime-security) | Governing tools, approvals, identity, tenants, audit, or cancellation |
| [axum-agent-gateway](./skills/axum-agent-gateway) | Building the authenticated Axum-to-UAR boundary |
| [persona-scoped-agent](./skills/persona-scoped-agent) | Constraining prompts, tools, retrieval, and release behavior by verified persona |
| [local-inference-lanes](./skills/local-inference-lanes) | Selecting or changing per-device engines and per-turn execution lanes |

## Application architecture and integration

| Skill | Use it when |
|---|---|
| [entity-graph-web-shell](./skills/entity-graph-web-shell) | Building a React/PEM shell over normalized entity state |
| [mini-app-module](./skills/mini-app-module) | Adding a manifest-driven, removable applet |
| [legacy-app-embed](./skills/legacy-app-embed) | Embedding a frozen or separately deployed application safely |
| [pem-local-first](./skills/pem-local-first) | Adding entities, local projections, transports, or durable optimistic mutations |
| [orchestrate-prometheus-application](./skills/orchestrate-prometheus-application) | Planning a composite application and routing work to the correct skills and control loop |

## Data, privacy, and domain

| Skill | Use it when |
|---|---|
| [sync-doctrine](./skills/sync-doctrine) | Designing sync, replication, offline writes, scopes, queues, or privacy lanes |
| [peer-profile-sync](./skills/peer-profile-sync) | Synchronizing private user profile/vault data device-to-device |
| [client-rag](./skills/client-rag) | Adding on-device embeddings and retrieval |
| [anonymized-replica](./skills/anonymized-replica) | Producing production-shaped but privacy-reviewed fixtures |
| [domain-glossary-service](./skills/domain-glossary-service) | Versioning canonical terms, synonyms, and domain mappings |

## Design system

| Skill | Use it when |
|---|---|
| [hybrid-design-tokens](./skills/hybrid-design-tokens) | Changing color, type, spacing, radius, motion, or responsive tokens |
| [mobile-navigation](./skills/mobile-navigation) | Adding top-level destinations or responsive navigation chrome |
| [tauri-custom-titlebar](./skills/tauri-custom-titlebar) | Building desktop window chrome in a shared Tauri/web bundle |

## Build, delivery, documentation, and retention

| Skill | Use it when |
|---|---|
| [dependency-pin-discipline](./skills/dependency-pin-discipline) | Adding or moving any dependency or toolchain version |
| [deploy-hybrid-agentic-stack](./skills/deploy-hybrid-agentic-stack) | Planning local, web, realtime, authenticated, or full-agentic deployment |
| [build-branded-docusaurus](./skills/build-branded-docusaurus) | Building and publishing a sanitized product documentation portal |
| [karpathy-progress-memory](./skills/karpathy-progress-memory) | Recording evidence, decisions, failures, and exact handoff position |

## Installation

Workstation:

```bash
bash scripts/install-global-harnesses.sh
```

Project:

```bash
knowme-builder skills install --path <project>
knowme-builder skills check --path <project>
```

## Source and generation

`skills` is canonical. The project template, six repository harness trees, and
the 29 detailed companion pages linked above are generated projections.

```bash
bash scripts/sync-harness-skills.sh --check
node site/scripts/generate-skill-reference.mjs --check
```

Edit the canonical `SKILL.md` and
`docs/catalog/skill-guidance.json`, regenerate, then review the diff.
