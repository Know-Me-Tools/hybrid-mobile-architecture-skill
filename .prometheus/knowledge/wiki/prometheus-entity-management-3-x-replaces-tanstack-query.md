---
type: Reference
id: prometheus-entity-management-3-x-replaces-tanstack-query
title: Prometheus Entity Management 3.x replaces TanStack Query
tags:
- prometheus-entity-management
- react
- tauri
- state-management
- architecture-decision
- scaffolding
sources:
- chat:codex
timestamp: 2026-07-17T16:55:37Z
created_at: 2026-07-17T16:55:37Z
updated_at: 2026-07-17T20:05:20Z
revision: 2
---

## Binding decision

Every React/Tauri project produced or governed by `hybrid-mobile-architecture` uses `@prometheus-ags/prometheus-entity-management` version 3.x as its server-side, asynchronous, normalized entity-state layer. Do not install or recommend `@tanstack/react-query`.

TanStack Router, Table, and Virtual remain allowed because they solve routing, presentation, and virtualization rather than entity state.

## Ownership boundaries

- Zustand owns client/UI state such as selection, filters, navigation state, and streaming state.
- Prometheus Entity Management owns registered entity transports, request deduplication, the normalized entity graph, cross-view reactivity, graph-aware mutations, relations, and local-first persistence.
- Components consume feature hooks only. Feature hooks compose Zustand selectors with Prometheus Entity Management hooks. Transport and API wiring stays at the entity-runtime/store boundary.
- New scaffolds and generated features use `useEntities`, `useEntityQuery`, `useEntity`, and `useEntityMutation` from the 3.x package.
- The architecture audit fails when React Query is present, when Prometheus Entity Management is absent, or when its declared version is not 3.x.

## Documentation and UI rule

This decision must remain explicit in `CLAUDE.md`, `AGENTS.md`, `SKILL.md`, generated project instructions, project-local UI skills, architecture references, auth/testing examples, scaffold templates, marketplace metadata, and the HTML architecture standard.

React visual components use shadcn/ui over raw HTML controls. Assistant UI owns chat threads, composers, streaming lifecycle, thread lists, attachments, and message actions. Flutter uses the same semantic design tokens and corresponding shadcn_flutter components. All surfaces use Flat 2.0 with no visible borders, divider lines, or layout shadows.

For durable chat, Prometheus Entity Management normalizes conversations and related entities. Browser persistence is PGlite; Tauri persistence is pglite-oxide behind typed Rust commands. Zustand remains limited to transient interaction state.

## Rationale

Prometheus Entity Management is owned by Prometheus AGS and provides the normalized entity graph, relation-aware invalidation, local-first adapters, and global reactive updates required by KnowMe. Keeping a second isolated query cache would duplicate responsibility and allow entity views to drift.
