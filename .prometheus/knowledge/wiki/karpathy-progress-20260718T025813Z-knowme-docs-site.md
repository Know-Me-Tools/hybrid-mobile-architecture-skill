---
type: Reference
id: karpathy-progress-20260718T025813Z-knowme-docs-site
title: "KnowMe documentation site verified"
tags:
- karpathy-progress
- knowme-docs-site
- verified
sources:
- conversation:operator-agent
timestamp: 2026-07-18T02:58:13Z
created_at: 2026-07-18T02:58:13Z
updated_at: 2026-07-18T02:58:13Z
revision: 1
---

## Intent

Built the isolated KnowMe-branded Docusaurus 3.10.1 site with architecture, reference application, deployment, UI/UX, prompting, and troubleshooting content. Flat 2.0 light and dark themes use background and spacing instead of visible borders or shadows.

## Observed state and verification

Fresh npm ci and production build passed; sanitizer passed; non-root docs image built; container returned HTTP 200 for home, architecture, deployment, and prompting routes; browser review passed desktop light, desktop dark, and 390px mobile dark; computed styles found zero shadows and no visible borders.

## Decision and lesson

Status: verified. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Publish the pinned docs image and GitHub Pages artifact from the protected release workflow.
