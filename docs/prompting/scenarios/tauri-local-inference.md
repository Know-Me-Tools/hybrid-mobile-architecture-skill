---
sidebar_position: 3
title: Tauri local inference desktop
description: Staged prompts for a React/Tauri desktop app with local model fallback, Assistant UI chat, PEM/Zustand, pglite-oxide, diagnostics, launch, and packaging proof.
---

# Tauri local inference desktop

Use this recipe for a desktop-first local agent app. The UI should feel like the
KnowMe mood board: Flat 2.0, chat bubbles, sidebars by background color rather
than borders, shadcn-ui components, Assistant UI chat structure, and real
ContentBlock/AG-UI event rendering.

## Prerequisites

```text
Verify Tauri CLI, Rust 1.96+, Node 24+, local default model availability or
download path, app-data write access, and Prometheus Entity Management 3.x
package source.
```

## Discovery prompt

```text
Read AGENTS.md, CLAUDE.md, Tauri/React/Rust patterns, KnowMe UI standard, mood
board, shadcn-ui setup, Assistant UI usage, PEM/Zustand conventions, and
pglite-oxide docs.
```

## Feynman prompt

```text
Explain how React components use shadcn-ui/Assistant UI and hooks/stores while
Rust core owns model loading, inference, diagnostics, and desktop persistence.
Grade the explanation and transfer it into implementation rules.
```

## KBD prompts

```text
/kbd-assess tauri-local-inference
Assess chat bubbles, model source selection, offline-first launch, model
cache/fallback, conversation history, AG-UI events, diagnostics, package build,
and restart behavior.
```

```text
/kbd-analyze tauri-local-inference
Analyze Tauri commands, React stores, PEM integration, local package exports,
pglite-oxide path, diagnostics file, model cache, and UI composition.
```

```text
/kbd-spec tauri-local-inference
Specify shadcn-ui/Assistant UI chat, ContentBlock/AG-UI rendering, no-border Flat
2.0 styling, PEM/Zustand state, pglite-oxide/shared Rust persistence, local
fallback model, and boot diagnostics.
```

```text
/kbd-plan tauri-local-inference
Plan Rust command/runtime work first, then PEM/Zustand stores, Assistant UI chat
shell, model settings, diagnostics, launch proof, packaging proof, tests, critic,
and retention.
```

## Implementation prompt

```text
Implement one waypoint at a time. Use shadcn-ui components over raw HTML where
available, Assistant UI for chat structure, PEM 3.x/Zustand for client entity
state, and Rust commands for all inference and persistence behavior.
```

## Public-boundary verification

```text
Run typecheck/tests, production build, Tauri dev or no-bundle launch, disable
network where relevant, stream a local-model chat, inspect diagnostics, restart,
and reopen the persisted conversation.
```

## Critic and stop evidence

```text
Review whether chat actually uses Assistant UI/shadcn patterns, avoids positive
TanStack Query recommendations, persists multiple conversations, handles offline
fallback, and proves real Tauri launch instead of screenshots only.
```

Stop for missing local model strategy, broken package exports, unsupported
pglite-oxide assumptions, repeated Tauri launch failure, or no restart
persistence evidence.
