---
type: Reference
id: karpathy-progress-20260718T025813Z-prompting-system
title: "Prometheus application prompting system verified"
tags:
- karpathy-progress
- prompting-system
- verified
sources:
- conversation:operator-agent
timestamp: 2026-07-18T02:58:13Z
created_at: 2026-07-18T02:58:13Z
updated_at: 2026-07-18T02:58:13Z
revision: 1
---

## Intent

Published the dated machine-readable model registry, harness playbooks, Feynman/KBD/Karpathy control loop, ten staged application scenarios, and OpenAI Proxy native-agent case study. Added the reusable orchestrate-prometheus-application skill to every supported local harness.

## Observed state and verification

Model registry schema validator passed 14 requested model entries with official dated sources; Docusaurus production build includes the prompting plugin; both new skills passed quick_validate; activation hook and six harness copies were generated.

## Decision and lesson

Status: verified. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Refresh the model registry from official sources before routing decisions after its review interval.
