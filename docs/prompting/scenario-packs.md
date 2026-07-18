---
sidebar_position: 5
title: Scenario prompt packs
slug: /scenarios
---

# Prometheus scenario prompt packs

Use these as staged prompts, not single “build everything” prompts. Every
scenario follows the same anatomy so operators can move between Codex, Claude
Code, OpenCode, Kimi Code CLI, Antigravity, and Zed without losing the KBD
thread.

## Canonical scenario index

| Scenario ID | Recipe | Architecture emphasis |
|---|---|---|
| `scenario-full-knowme-hybrid` | [Full KnowMe hybrid application](./scenarios/full-knowme-hybrid.md) | Flutter mobile, Tauri desktop, React/Axum web, shared Rust. |
| `scenario-flutter-rust-ffi` | [Flutter-only mobile with Rust FFI](./scenarios/flutter-rust-ffi.md) | Mobile UI in Flutter; networking, persistence, and agent behavior in Rust. |
| `scenario-tauri-local-inference` | [Tauri local inference desktop](./scenarios/tauri-local-inference.md) | React 19/Tauri with local model cache, pglite-oxide, and offline proof. |
| `scenario-full-stack-automation` | [Full-stack automation product](./scenarios/full-stack-automation.md) | Hands/workflows, AG-UI events, approvals, artifacts, and replay. |
| `scenario-multi-tenant-saas` | [Multi-tenant SaaS](./scenarios/multi-tenant-saas.md) | Optional Kratos/Gate/Keto, Forge/Fabric, BYOK, tenant isolation. |
| `scenario-local-agent-client` | [Local desktop agent client](./scenarios/local-agent-client.md) | MCP, skills, files, model routing, permissions, conversations, audit replay. |
| `scenario-ideation-studio` | [Business ideation and validation studio](./scenarios/ideation-studio.md) | Feynman learning, falsification, scoring, decision journal, retention. |
| `scenario-native-rust-agent` | [Native Rust agent](./scenarios/native-rust-agent.md) | Generated Rust agent with one core and protocol adapters. |
| `scenario-multi-cloud-deployment` | [Source-built multi-cloud deployment](./scenarios/multi-cloud-deployment.md) | Locks, BuildKit, attestations, Compose, CNPG, GitOps, ingress/gateway TLS. |
| `scenario-branded-docs-portal` | [Branded documentation portal](./scenarios/branded-docs-portal.md) | Classified content, KnowMe Flat 2.0 theme, Pages/container, sanitizer, OpenGraph. |

## Shared recipe anatomy

Each recipe contains:

1. prerequisites and authority boundary;
2. discovery prompt;
3. Feynman learning prompt;
4. KBD assess/analyze/spec/plan prompts;
5. focused research prompt;
6. bounded implementation prompt;
7. public-boundary verification prompt;
8. independent critic prompt;
9. reflection and Karpathy retention prompt;
10. recovery prompt;
11. stop conditions.

The machine-readable source of truth for these fields lives in
`docs/prompting/data/recipes/*.json`; the public pages explain how to use them.

## Stage navigation

Use the same stage order for every scenario:

```text
discover
→ Feynman learn
→ KBD assess
→ KBD analyze
→ KBD spec
→ KBD plan
→ research
→ bounded implementation
→ public-boundary verification
→ independent critic
→ reflection and retention
```

If a stage reveals missing authority, unsupported claims, or an architecture
contradiction, stop at that stage and recover. Do not skip forward to
implementation to “make progress.”

## Role-class references

Role IDs are defined in the content inventory and resolved through the dated
model registry instead of hard-coding current model names in every recipe.

| Role ID | Use |
|---|---|
| `role-frontier-architect` | Hard architecture, cross-repository synthesis, and final design judgment. |
| `role-balanced-producer` | Normal implementation and bounded repair. |
| `role-mechanical-transformer` | Safe high-volume edits with objective checks. |
| `role-research-synthesizer` | Source-grounded research and gap synthesis. |
| `role-independent-critic` | Verification against original requirements and evidence. |
| `role-long-context-cartographer` | Large repository or document mapping. |
| `role-multimodal-reviewer` | UI, image, video, and diagram review. |

See [model routing](./model-routing.generated.md) for current role-to-model
recommendations generated from the dated registry.

## Architecture map

| Product shape | Binding architecture rule |
|---|---|
| Mobile | Flutter UI; Rust owns networking, persistence, sync, inference, and agent behavior. |
| Desktop | Tauri shell; React UI; Rust-owned commands, persistence, model loading, diagnostics. |
| Web | React UI can be served statically or by Axum; server-side agent endpoints live in Rust. |
| Chat UI | Assistant UI/shadcn-style components; ContentBlock/AG-UI event rendering; bubbles and conversation history. |
| Client state | Prometheus Entity Management with Zustand/PGlite where applicable; no TanStack Query for Prometheus-owned entity state. |
| Deployment | Source-built image catalog, immutable digests, Compose for local profiles, Kustomize/GitOps for clusters. |

## Recovery conventions

Every recipe uses the same recovery IDs:

- `recovery-two-failure-stop`: stop after two repeated failures on the same
  approach and reassess.
- `recovery-replan-at-kbd`: return to KBD assess/analyze/spec/plan when an
  assumption fails.
- `recovery-skill-gap`: create or update a skill when a repeatable operational
  gap is proven.
- `recovery-human-checkpoint`: ask the operator before external side effects,
  destructive actions, or authority expansion.
- `recovery-clean-checkout-repro`: reproduce from a fresh checkout before calling
  a product, site, image, or skill complete.

## Shared phase prompts

**Plan:** “Run the Feynman/KBD assessment for this scenario. Read the binding
rules and selected skills. Produce a decision-complete waypoint plan with
artifacts, authority, clean-checkout criteria, budgets, retry limits, and a
critic.”

**Implement:** “Implement only `[waypoint]`. Preserve existing work. Exercise
the public boundary once before adding 3–5 behavior tests. Record failures and
stop after two repeats of the same failed approach.”

**Verify:** “As an independent critic, grade the original criteria. Inspect the
real launch, persistence, packaging, security defaults, and omitted platforms.
Do not accept the producer summary as evidence.”

**Reflect:** “Append intent, observed behavior, evidence, failures, decision,
and reusable lesson to project Karpathy memory. Add private context only to the
private wiki. Advance the waypoint only on verified evidence.”
