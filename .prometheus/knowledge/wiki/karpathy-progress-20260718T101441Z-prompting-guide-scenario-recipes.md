---
id: karpathy-progress-20260718T101441Z-prompting-guide-scenario-recipes
title: Prompting guide scenario recipes verified
type: karpathy_progress
tags:
  - karpathy-progress
  - prompting-guide
  - scenarios
  - kbd
  - verified
created: 2026-07-18T10:14:41Z
updated: 2026-07-18T10:14:41Z
---

# Prompting guide scenario recipes verified

## Intent

Complete the `prompting-guide-scenario-recipes` KBD change by publishing ten
copyable scenario prompt packs as canonical documentation and structured data.

## Decisions

- Replaced the short scenario summary with a canonical scenario index, shared
  recipe anatomy, stage navigation, role references, architecture map, and
  recovery conventions.
- Added structured recipe JSON and public Docusaurus pages for all ten requested
  scenarios.
- Included the explicit UI/data choices requested for KnowMe and Tauri:
  shadcn-ui, Assistant UI, PEM 3.x, Zustand, PGlite, pglite-oxide, chat bubbles,
  AG-UI/ContentBlocks, and no positive TanStack Query recommendation for
  Prometheus-owned entity state.
- Included NGINX Ingress, Traefik, Envoy Gateway, wildcard TLS, and Let's
  Encrypt/certbot coverage in the multi-cloud deployment recipe.
- Added page/route/source/stop-evidence checks to the prompting validator and a
  ten-recipe evidence matrix.

## Evidence

- `npm --prefix site run validate:prompting`
- `npm --prefix site run test:prompting-fixtures`
- `npm --prefix site run sanitize`
- `npm --prefix site run check:model-routing`
- `npm --prefix site run build`
- `npx @fission-ai/openspec validate prompting-guide-scenario-recipes --strict --json`

## Reusable lesson

Scenario prompt packs need both human-readable pages and machine-readable
records. The validator should prove all scenario IDs, routes, public-boundary
evidence, critic evidence, stop conditions, and no-private-content constraints
instead of relying on manual review only.

## Next waypoint

Continue with `/kbd-apply prompting-guide-agent-orchestration`.
