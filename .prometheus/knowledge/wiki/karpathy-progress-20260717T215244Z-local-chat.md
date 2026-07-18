---
type: Reference
id: karpathy-progress-20260717T215244Z-local-chat
title: "Assistant UI local chat and persistence verified"
tags:
- karpathy-progress
- local-chat
- in-progress
sources:
- conversation:operator-agent
timestamp: 2026-07-17T21:52:44Z
created_at: 2026-07-17T21:52:44Z
updated_at: 2026-07-17T21:52:44Z
revision: 1
---

## Intent

React 19 KnowMe chat now uses Assistant UI and shadcn surfaces with Flat 2.0 filled bubbles. Browser WebLLM Qwen2.5 0.5B loaded with no configuration, streamed a real response at approximately 5.5 tok/s, and the conversation survived reload through PGlite. TypeScript, 10 Vitest behaviors, and Flutter analyze pass. Native Mistral Metal remains blocked by incompatible mixed Candle revisions upstream, not by the installed Xcode Metal toolchain.

## Observed state and verification

browser local generation; browser reload persistence; pnpm exec tsc --noEmit; pnpm test -- --run (10/10); flutter analyze

## Decision and lesson

Status: in-progress. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Add shared Rust host service and Axum server contract, then connect persistent web and deployment profiles.
