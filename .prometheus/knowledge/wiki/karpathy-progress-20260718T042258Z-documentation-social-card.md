---
type: Reference
id: karpathy-progress-20260718T042258Z-documentation-social-card
title: "Publish KnowMe documentation OpenGraph image"
tags:
- karpathy-progress
- documentation-social-card
- verified
sources:
- conversation:operator-agent
timestamp: 2026-07-18T04:22:58Z
created_at: 2026-07-18T04:22:58Z
updated_at: 2026-07-18T04:22:58Z
revision: 1
---

## Intent

Use the operator-supplied documentation homepage screenshot as the canonical social-sharing image for GitHub Pages.

## Observed state and verification

The source and committed PNG have identical SHA-256 ba5a2765d00243d7220cba3f952807fc0862c92ef673b812726221089d19cbef and dimensions 3460 by 2130. A sanitized production build passed and emits summary_large_image, absolute og:image and twitter:image URLs, PNG type, dimensions, and descriptive alt metadata.

## Decision and lesson

Status: verified. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Commit and deploy through the Pages workflow, then verify the public page HTML and public image return HTTP 200 with the expected absolute URL and image/png content type.
