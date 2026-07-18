<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=ea71fdefea350b6e6d1e699869ee0dc3dc780cff9384436c9c1a0bc1184e5006 -->
---
type: Reference
id: hybrid-scaffold-plan-ready-with-12-openspec-changes
title: Hybrid scaffold plan ready with 12 OpenSpec changes
tags:
- hybrid-mobile-architecture
- scaffolding
- openspec
- kbd-orchestrator
- flutter
- rust-ffi
- tauri
- react-19
links:
- hybrid-mobile-architecture-scaffold-phase-initialization
- hybrid-mobile-scaffold-phase-assessment-readiness
- hybrid-scaffold-assessment-waits-on-remaining-research-agents
- hybrid-scaffold-assessment-receives-testing-policy-research
- hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T18:33:11.677109+00:00
created_at: 2026-07-15T18:33:11.677109+00:00
updated_at: 2026-07-15T18:33:11.677109+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-15T18:09:14Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `execute_ready`
- **Plan state:** `kbd-plan` complete, step `0/12`
- **Plan file:** `.kbd-orchestrator/phases/scaffold-full-hybrid-project/plan.md`
- **OpenSpec proposals:** `openspec/changes/2026-07-15-c0*/`

This advances the same scaffolding phase initialized in [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md) and assessed through [Hybrid Mobile scaffold phase assessment readiness](/hybrid-mobile-scaffold-phase-assessment-readiness.md), [Hybrid scaffold assessment waits on remaining research agents](/hybrid-scaffold-assessment-waits-on-remaining-research-agents.md), [Hybrid scaffold assessment receives testing policy research](/hybrid-scaffold-assessment-receives-testing-policy-research.md), and [Hybrid scaffold analysis integrates PEM and PES sync findings](/hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings.md).

## Phase goals

- Create a complete generated instance of the hybrid mobile architecture:
  - Flutter mobile application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts from the reference library to generate a working project.
- Verify all generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the local environment satisfies minimum tool version requirements.

## Execution plan

The plan contains **12 changes** arranged into **3 waves** for worktree concurrency.

### Wave 0: serial foundation

1. **C-001 layered workspace**
   - Establishes cross-crate trait seams in `gen_ui_types` before downstream lanes begin.
   - Freezes shared interfaces required to avoid conflicts:
     - `EntityTransport`
     - `SyncTransport`
     - `ContentBlock`
     - `ViewDescriptor`
2. **C-002 wasm32 spike**
   - Early risk-reduction lane for wasm32 feasibility and constraints.

### Wave 1: parallel implementation lanes

Designed for six parallel worktrees after the Wave 0 seams land:

- **C-003 relational store + startup orchestrator**
- **C-004 SurrealDB graph RAG**
- **C-005 sync engine** based on the DIY-via-forge decision
- **C-006 Flint integration**
- **C-007 FFI leaves + packaging**
- **C-008 documentation corrections**; can dispatch immediately
- **C-009 project skills**; can dispatch immediately

### Wave 2: user-facing surfaces and vertical slice

- **C-010 Flutter surface** using the `prometheus_entity_management` Dart port
- **C-011 React surface** using PEM `3.0.0-alpha.0`
- **C-012 KnowMe vertical slice** across all four targets

## Harness and model assignments

Assignments were selected by skill activation reliability, frontier reasoning needs, cost efficiency, and context length requirements.

| Tier | Changes | Assignment |
|---|---:|---|
| Architecture-defining / distributed correctness | `C-001`, `C-005`, `C-012` | Claude Code · **Opus 4.8** |
| Skill-heavy novel work: SurrealDB 3.x, Riverpod 3, Flint SDKs, skills, wasm forensics | `C-002`, `C-004`, `C-006`, `C-009`, `C-010` | Claude Code · **Sonnet 5** |
| High-volume established-pattern backend + TypeScript-heavy frontend | `C-003`, `C-011` | Codex · **gpt-5.6-sol** |
| Mechanical glue: `flutter_rust_bridge`/Tauri skeletons | `C-007` | OpenCode · **GLM 5.2** |
| Documentation rewrite with long-context read/edit | `C-008` | Kimi Code CLI · **K2.6** |
| C-006 API digestion sub-lane | part of `C-006` | Kimi Code CLI · **K2.7** |

Provider distribution is intentional: Wave 1's five heavy lanes are spread across four providers to avoid quota contention.

## Execution status and next action

- Current status: `execute_ready`
- Completed: plan generation only (`0/12` implementation changes complete)
- Remaining: all 12 OpenSpec changes
- Next command: `/kbd-execute`
- First required execution target: `C-001` layered workspace with Claude Code Opus 4.8
- Immediately dispatchable in parallel worktrees: `C-008` documentation corrections and `C-009` project skills

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
