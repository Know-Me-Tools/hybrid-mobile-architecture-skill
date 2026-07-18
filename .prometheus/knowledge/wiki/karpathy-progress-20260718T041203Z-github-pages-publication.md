---
type: Reference
id: karpathy-progress-20260718T041203Z-github-pages-publication
title: "Publish KnowMe documentation through GitHub Pages"
tags:
- karpathy-progress
- github-pages-publication
- verified
sources:
- conversation:operator-agent
timestamp: 2026-07-18T04:12:03Z
created_at: 2026-07-18T04:12:03Z
updated_at: 2026-07-18T04:12:03Z
revision: 1
---

## Intent

Enable the product documentation site as a public, HTTPS-enforced GitHub Pages workflow deployment while preserving Docusaurus for extensive product documentation and reserving Astro Starlight for a future central ecosystem portal.

## Observed state and verification

GitHub Pages repository configuration now uses build_type workflow with HTTPS enforcement. Workflow run 29630055445 passed frozen install, production build, artifact upload, and deployment. Public HTTP 200 verification passed for home, architecture, KnowMe reference, deployment catalog, edge-and-TLS, prompting playbook, and search routes at the repository project URL. Sanitization and broken-link production build passed after adding the documentation-platform decision page.

## Decision and lesson

Status: verified. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

When an approved custom domain is supplied, verify domain ownership and DNS, configure the Pages custom domain, and update SITE_URL and BASE_URL. Build a separate Astro Starlight central portal only when cross-product navigation and federated search are ready; keep authenticated services on dedicated infrastructure.
