---
sidebar_position: 1
title: Full KnowMe hybrid application
description: Staged prompts for building the full KnowMe reference app across Flutter mobile, Tauri desktop, React/Axum web, and shared Rust.
---

# Full KnowMe hybrid application

Build the reference KnowMe application as one architecture, not three separate
apps. Flutter owns mobile UI, Tauri/React owns desktop UI, Axum can serve the
React web interface, and shared Rust owns networking, persistence, inference,
sync, agent behavior, model configuration, and public protocol endpoints.

## Prerequisites

```text
Verify Flutter beta, Rust 1.96+, Node 24+, Tauri 2.10+, a local model path or
download strategy, and Prometheus Entity Management 3.x availability before
planning.
```

## Discovery prompt

```text
Read AGENTS.md, CLAUDE.md, references/arch-standard.md, React/Tauri, Flutter,
Rust, deployment, UI, and project skill docs. Inventory app surfaces, generated
templates, current KBD/OpenSpec state, and existing KnowMe specifications.
```

## Feynman prompt

```text
Explain how one shared Rust core serves Flutter mobile, Tauri desktop, and Axum
web while React and Flutter remain thin UI layers. Grade the explanation, list
gaps, and transfer the result into implementation rules.
```

## KBD phase prompts

```text
/kbd-assess full-knowme-hybrid
Assess chat bubbles, ContentBlock/AG-UI events, multiple conversations,
local-first persistence, BYOK-ready configuration, launch proof, and
cross-surface parity.
```

```text
/kbd-analyze full-knowme-hybrid
Analyze current source, templates, KnowMe specs, mood board, PEM/Zustand/PGlite,
pglite-oxide, Flutter providers, Rust FFI, Tauri commands, and Axum hosting.
```

```text
/kbd-spec full-knowme-hybrid
Specify shared Rust ownership, React component→hook→store layering, Flutter
screen→provider→domain/data layering, no TanStack Query, Flat 2.0 UI, and
public-boundary proof.
```

```text
/kbd-plan full-knowme-hybrid
Plan Rust core contracts first, then React/Tauri UI and persistence, Flutter
providers/FFI, Axum host, deployment/docs updates, and integrated verification.
```

## Implementation prompt

```text
Implement one bounded waypoint at a time. Keep networking, inference, sync,
persistence, and agent logic in Rust. React and Flutter components call hooks or
providers only. Use PEM 3.x with Zustand/PGlite for web state and
pglite-oxide/shared Rust for desktop where configured.
```

## Public-boundary verification

```text
Launch Tauri, serve the production web bundle or Axum host, launch a simulator
or device, create and reopen multiple conversations, stream a local-model chat,
display ContentBlocks, prove persistence after restart, and run clean-checkout
build gates.
```

## Independent critic

```text
Compare the app against the original hybrid goal, mood board, UI standard, Rust
ownership invariant, launch evidence, local-model behavior, persistence proof,
and clean-checkout reproduction. Fail if any surface is simulated or omitted.
```

## Recovery and stop conditions

Stop for missing toolchain authority, unsupported package claims, repeated launch
failure, private content leakage, or inability to prove one shared persisted
workflow across surfaces. If any surface fails twice, return to KBD analysis for
that surface before continuing.
