---
title: orchestrate-prometheus-application
sidebar_label: orchestrate-prometheus-application
sidebar_position: 13
description: "Classify and orchestrate Prometheus application work across hybrid, mobile-only, desktop, automation, SaaS, agent-client, ideation, native-agent, deployment, and documentation scenarios. Use when planning or prompting a multi-phase product build, selecting models or harnesses, running KBD/Feynman/Karpathy loops, or generating missing skills and agents."
---

# orchestrate-prometheus-application

**Category:** Workflow and retention

## What it is for

Classify and orchestrate Prometheus application work across hybrid, mobile-only, desktop, automation, SaaS, agent-client, ideation, native-agent, deployment, and documentation scenarios. Use when planning or prompting a multi-phase product build, selecting models or harnesses, running KBD/Feynman/Karpathy loops, or generating missing skills and agents.

## Why it is designed this way

Complex application work needs explicit scenario classification, authority boundaries, bounded phases, independent criticism, and public-boundary evidence. The skill coordinates those artifacts without replacing Prometheus lifecycle authority.

## Common use cases

- Plan a composite hybrid, SaaS, automation, native-agent, or documentation build
- Select relevant skills, references, harnesses, and producer/critic roles
- Run Feynman, KBD, PMPO, verification, and retention loops coherently

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/orchestrate-prometheus-application <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Builder activation aids must not pause, resume, lease, hand off, or mutate Prometheus KBD state.

## Canonical operating contract

Read `AGENT_BASE_RULES.md`, the architecture standard, and the dated model registry.
Never infer model capabilities from names or copy mutable prices/context into stable
guidance.

Progressive references:

- `references/scenario-classification.md` — known/composite scenario classification and dependency-ordered asset manifest.
- `references/control-loop.md` — Feynman/KBD/PMPO/Karpathy loop rules, authority boundaries, producer/critic selection, and completion gates.
- `references/native-agent-decision.md` — prompt versus skill versus native-agent decision guide.

## Control loop

`Feynman learn → KBD assess → research → decision-complete plan → bounded implementation → public-boundary verification → adversarial critic → Karpathy retention → next waypoint`

1. Classify the product using `references/scenario-classification.md`: full hybrid,
   Flutter-only, Tauri local agent, automation, SaaS, local agent client, ideation
   studio, native Rust agent, multi-cloud deployment, branded documentation, or a
   composite of those scenarios.
2. If domain or requirements are unclear, explain them simply, grade the explanation,
   research gaps, and repeat before architecture.
3. Emit a dependency-ordered reference manifest covering architecture, recipe,
   harness, loop, role, retention, and verification assets.
4. Produce staged harness-specific prompts with outcome, sources, authority, artifacts,
   public-boundary criteria, budgets, retry limits, and stop conditions.
5. Select producer and independent critic roles from the current registry. Do not
   duplicate or hand-edit the model catalog inside this skill.
6. Record Karpathy progress at phase boundaries. Require
   `hybrid-runtime-verification` before “working” or “complete.”
7. When a repeated operational gap is proven, use the skill creator and validate the
   new skill in a scratch project. When the missing capability requires an independent
   runtime/protocol lifecycle, use the native-agent creator.

Do not let PMPO rewrite requirements to fit a failing output, let a producer certify
its own work, or run an autonomous loop without explicit authority and termination.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`templates/project-skills/orchestrate-prometheus-application/SKILL.md`; generated harness copies
must never be edited independently.
