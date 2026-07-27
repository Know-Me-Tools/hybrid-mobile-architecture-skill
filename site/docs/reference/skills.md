---
sidebar_position: 2
title: Project skills
---

# The 19 project skills

Every project the pack scaffolds receives these skills in all supported harness
directories (`.claude`, `.codex`, `.opencode`, `.kimi`, `.kimi-code`, `.agents`),
plus an activation hook.

Most are **behavioral gates**, not code generators: they fire before a class of
work and state the rule that class gets wrong. Their descriptions are written to
be directive and trigger-rich on purpose — prompt-matching descriptions raise
activation from roughly 50% to 84–100%, and a gate that does not fire is not a
gate.

## Before you write code

| Skill | Fires before |
|---|---|
| [`local-inference-lanes`](../architecture/inference-lanes) | Adding, selecting, or debugging an on-device inference engine, or deciding where a chat turn runs |
| `dependency-pin-discipline` | Adding, bumping, or unpinning a dependency in any manifest, or writing a version literal into a script |
| `hybrid-design-tokens` | Writing any color, spacing, typography, radius, or theme value on any surface |
| `mobile-navigation` | Adding, moving, or restyling top-level navigation — including any `Platform.isIOS` check in nav code, which is wrong |
| `content-block-ui` | Rendering, adding, or editing a ContentBlock variant |
| `pem-local-first` | Wiring client entity/server state |
| `sync-doctrine` | Any sync, replication, realtime, offline, or local-first work |
| `peer-profile-sync` | Handling profile data, sensitive personal data, or agent-learned facts |
| `client-rag` | Adding vector search, embeddings, semantic recall, or retrieval |
| `reference-ui-fidelity` | Implementing a UI when a spec, mood board, prototype, or reference app exists |
| `tauri-custom-titlebar` | Building or debugging a Tauri window frame |

## Before you call it done

| Skill | Fires before |
|---|---|
| `hybrid-runtime-verification` | Calling anything working, complete, ready, shippable, or verified |
| `a11y-gate` | Calling any UI change done — cross-surface WCAG 2.2 AA |
| `tauri-ui-review` | Calling any React/Tauri surface done — screenshots at 320/768/1024/1440, both themes |
| `flutter-golden-ui` | Calling any Flutter widget or screen done |

## Orchestration and docs

| Skill | Purpose |
|---|---|
| `orchestrate-prometheus-application` | Classify and route work across hybrid, mobile-only, desktop, automation, and SaaS scenarios |
| `deploy-hybrid-agentic-stack` | Plan, scaffold, and verify the full stack — web, desktop, mobile, Rust host, Axum, Flint services |
| `build-branded-docusaurus` | Scaffold, brand, sanitize, and verify a documentation portal |
| `karpathy-progress-memory` | Capture evidence-backed progress records and reusable lessons |

## Two rules worth reading in full

**Per-device inference.** The engine is chosen per device — Android LiteRT-LM,
iOS/macOS MLX, desktop llama.cpp, web WebLLM — and the lane (`cloud` / `local` /
`uar`) is chosen per turn. Conflating them, or assuming a single "mobile" engine,
is the most common mistake in this area. See
[Inference lanes](../architecture/inference-lanes).

**Exact pins with rationale.** Pins are exact, not floors, and the comment
explaining *why* is the real artifact. A pin without a reason is a number nobody
dares change, so someone eventually "tidies" it back to a caret and re-derives
the same failure. Dart codegen packages share one `analyzer` dependency and do
not move together; the resolution is a coherent set pinned exactly, moved
together or not at all.

## Keeping them in sync

`templates/project-skills/` is the source. The six harness trees are copies, and
a copy edited in place diverges silently — each harness would then teach a
different rule for the same situation.

```bash
bash scripts/sync-harness-skills.sh          # mirror source into every tree
bash scripts/sync-harness-skills.sh --check  # verify only; non-zero on drift
```

The drift check runs as part of `audit.sh doc-consistency`, alongside a gate that
fails when a skill exists but `plugin.json` does not distribute it.

To install the skills globally for every harness on a workstation:

```bash
bash scripts/install-global-harnesses.sh
```
