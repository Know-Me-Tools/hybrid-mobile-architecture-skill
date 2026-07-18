---
type: Reference
id: karpathy-progress-20260717T221423Z-axum-host
title: "Shared host and Axum vertical slice launched"
tags:
- karpathy-progress
- axum-host
- in-progress
sources:
- conversation:operator-agent
timestamp: 2026-07-17T22:14:23Z
created_at: 2026-07-17T22:14:23Z
updated_at: 2026-07-17T22:14:23Z
revision: 1
---

## Intent

Added gen_ui_host as the shared Tauri/Axum composition layer, gen_ui_server_axum with typed versioned routes and lossless POST-to-SSE receiver registration, and knowme-web-server with embedded or validated external React assets. Launched the real process against pglite-oxide, SurrealDB, and FastEmbed; health/readiness, SPA fallback, API 404, active lane, and structured validation/provider errors were proven. Added pinned multi-stage non-root Docker packaging, profile-based Forge/Fabric/Gate/Kratos Compose configuration, and a source-backed Flint-to-Supabase research contract.

## Observed state and verification

cargo clippy gen_ui_host/gen_ui_server_axum -D warnings; cargo clippy knowme-web-server -D warnings; live port 18080 HTTP probes; docker build --check; docker compose config for default/authenticated/realtime/full-agentic

## Decision and lesson

Status: in-progress. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Verify Tauri consumes gen_ui_host, add hosted repository and BYOK contracts, validate deployment profiles, and apply the same server/deployment changes to scaffolds.
