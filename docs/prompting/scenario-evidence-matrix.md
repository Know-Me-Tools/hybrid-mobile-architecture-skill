---
sidebar_position: 6
title: Scenario evidence matrix
description: Independent review matrix for the ten Prometheus scenario prompt packs.
---

# Scenario evidence matrix

Review date: 2026-07-18

Scope: `prompting-guide-scenario-recipes`

This matrix checks the ten scenario prompt packs against the normative scenario
requirements. It is not proof that a generated product exists; it is proof that
the prompting guide now contains complete staged recipes with explicit
verification, critic, recovery, and stop evidence.

## Review criteria

Each recipe must provide:

- stable scenario ID;
- machine-readable recipe record;
- public scenario page linked from the scenario index;
- staged prompts for discovery, Feynman, KBD assess/analyze/spec/plan,
  research, implementation, public-boundary verification, critic, retention, and
  recovery;
- at least one public-boundary evidence requirement;
- independent critic role and evidence;
- stop conditions;
- recovery path;
- no private raw content;
- no positive TanStack Query recommendation for Prometheus-owned entity state.

## Evidence matrix

| Scenario ID | Public page | Structured data | Normative coverage | Review disposition |
|---|---|---|---|---|
| `scenario-full-knowme-hybrid` | `docs/prompting/scenarios/full-knowme-hybrid.md` | `docs/prompting/data/recipes/full-knowme-hybrid.json` | Flutter mobile, Tauri desktop, React/Axum web, shared Rust, chat/ContentBlocks, persistence, launch, cross-surface proof, critic, retention. | PASS |
| `scenario-flutter-rust-ffi` | `docs/prompting/scenarios/flutter-rust-ffi.md` | `docs/prompting/data/recipes/flutter-rust-ffi.json` | Layering, Riverpod/FRB generation, simulator/device launch, restart persistence, parity, recovery, critic, stop evidence. | PASS |
| `scenario-tauri-local-inference` | `docs/prompting/scenarios/tauri-local-inference.md` | `docs/prompting/data/recipes/tauri-local-inference.json` | Model cache/fallback, offline proof, shadcn-ui/Assistant UI, PEM/Zustand, pglite-oxide, diagnostics, launch, packaging, recovery, critic. | PASS |
| `scenario-full-stack-automation` | `docs/prompting/scenarios/full-stack-automation.md` | `docs/prompting/data/recipes/full-stack-automation.json` | Workflow state, approvals, resumability, replay, destructive checkpoints, artifacts, recovery, verification. | PASS |
| `scenario-multi-tenant-saas` | `docs/prompting/scenarios/multi-tenant-saas.md` | `docs/prompting/data/recipes/multi-tenant-saas.json` | Threat model, RLS, optional Kratos/Gate/Keto, BYOK, Forge/Fabric isolation, anonymous-mode decision, deployment, tenant proof. | PASS |
| `scenario-local-agent-client` | `docs/prompting/scenarios/local-agent-client.md` | `docs/prompting/data/recipes/local-agent-client.json` | MCP trust, file grants, skills, conversations/events, model routing, approval denial, audit replay, recovery, public workflow proof. | PASS |
| `scenario-ideation-studio` | `docs/prompting/scenarios/ideation-studio.md` | `docs/prompting/data/recipes/ideation-studio.json` | Feynman transfer, falsification, counter-evidence, experiments, scoring, decision journal, Karpathy retention, skill thresholds, critic, stop criteria. | PASS |
| `scenario-native-rust-agent` | `docs/prompting/scenarios/native-rust-agent.md` | `docs/prompting/data/recipes/native-rust-agent.json` | Capability classification, generator, one core/adapters, protocol consumers, Docker/launch proof, skill-versus-agent test, recovery, critic evidence. | PASS |
| `scenario-multi-cloud-deployment` | `docs/prompting/scenarios/multi-cloud-deployment.md` | `docs/prompting/data/recipes/multi-cloud-deployment.json` | Locks, BuildKit, attestations, digest promotion, Compose/CNPG, GKE/AKS/EKS GitOps, NGINX, Traefik, Envoy Gateway, wildcard/Let's Encrypt TLS, no-direct-deploy enforcement. | PASS |
| `scenario-branded-docs-portal` | `docs/prompting/scenarios/branded-docs-portal.md` | `docs/prompting/data/recipes/branded-docs-portal.json` | Classification, canonical source, KnowMe Flat 2.0 themes, Mermaid/search, Pages/container, sanitization, accessibility, screenshots, OpenGraph, recovery, publication proof. | PASS |

## Verification commands

```bash
npm --prefix site run validate:prompting
npm --prefix site run test:prompting-fixtures
npm --prefix site run sanitize
npm --prefix site run check:model-routing
npm --prefix site run build
```

## Review result

The ten recipe prompt packs satisfy the requested scenario coverage. Remaining
phase work after this change is broader agent orchestration and publication
gating, not missing scenario recipe content.
