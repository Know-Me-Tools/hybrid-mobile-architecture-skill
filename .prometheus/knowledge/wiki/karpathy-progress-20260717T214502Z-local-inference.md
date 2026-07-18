---
type: Reference
id: karpathy-progress-20260717T214502Z-local-inference
title: "Metal installed; pinned Mistral Candle graph remains incompatible"
tags:
- karpathy-progress
- local-inference
- blocked-upstream
sources:
- conversation:operator-agent
timestamp: 2026-07-17T21:45:02Z
created_at: 2026-07-17T21:45:02Z
updated_at: 2026-07-17T21:45:02Z
revision: 1
---

## Intent

Verify the zero-configuration desktop local-model lane after Xcode Metal Toolchain installation without silently falling back to cloud.

## Observed state and verification

xcrun locates the Metal compiler and Mistral shaders compile. Two controlled cargo test attempts then fail because mistralrs-quant and mistralrs-paged-attn resolve incompatible Candle 0.10.2 and 0.11 metal kernel types. The acceleration feature change was restored to the build-safe state.

## Decision and lesson

Status: blocked-upstream. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Choose and implement a single-version Mistral/Candle pin or reuse the embedded llama.cpp backend for desktop, then rerun the ignored public-boundary streamed-response test once.
