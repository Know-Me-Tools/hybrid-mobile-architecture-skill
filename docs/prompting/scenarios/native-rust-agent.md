---
sidebar_position: 8
title: Native Rust agent
description: Staged prompts for generating a native Rust agent with one core, protocol adapters, Docker/launch proof, skill-versus-agent testing, recovery, and critic evidence.
---

# Native Rust agent

Use this recipe when a reusable skill is not enough and the capability needs a
runtime service, protocol surface, persistence, or deployment package.

## Prerequisites

```text
Verify stable job definition, protocol consumers, runtime choice,
config/security model, Docker target, and whether a skill would be sufficient
instead of an agent.
```

## Discovery and Feynman prompts

```text
Read native-agent creator instructions, Axum/Rust patterns, protocol docs,
OpenAI proxy case study, packaging conventions, and current templates.
```

```text
Explain why this capability needs a native agent rather than a skill, and how
one core behavior maps to protocol adapters without duplicate logic.
```

## KBD prompts

```text
/kbd-assess native-rust-agent
Assess capability boundary, consumers, protocols, persistence, auth,
configuration, observability, packaging, and operator deployment needs.
```

```text
/kbd-analyze native-rust-agent
Analyze generator outputs, one-core/adapters architecture, Axum routes,
MCP/ACP/AG-UI/A2A contracts, Dockerfile, and integration tests.
```

```text
/kbd-spec native-rust-agent
Specify core traits, adapters, config, health/readiness, protocol consumers,
Docker image, security defaults, and public-boundary tests.
```

```text
/kbd-plan native-rust-agent
Plan capability classification first, then generator invocation, core
implementation, adapters, protocol tests, Docker launch, critic, and retention.
```

## Implementation and verification

```text
Generate or implement the agent with one behavior core. Add only required
adapters. Keep protocol glue thin and test each declared consumer.
```

```text
Build the agent, run it, exercise each declared protocol with a real consumer or
smoke request, build the Docker image, and prove health/readiness.
```

## Stop evidence

Stop for unclear job definition, no consumer, duplicated adapter logic,
unsupported protocol claims, failed launch, missing Docker proof, or unjustified
native-agent scope.
