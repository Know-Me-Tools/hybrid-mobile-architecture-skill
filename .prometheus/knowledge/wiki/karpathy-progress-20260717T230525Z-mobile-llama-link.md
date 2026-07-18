---
type: Reference
id: karpathy-progress-20260717T230525Z-mobile-llama-link
title: "Mobile llama.cpp iOS link boundary identified"
tags:
- karpathy-progress
- mobile-llama-link
- blocked
sources:
- conversation:operator-agent
timestamp: 2026-07-17T23:05:25Z
created_at: 2026-07-17T23:05:25Z
updated_at: 2026-07-17T23:05:25Z
revision: 1
---

## Intent

Run the first real iOS simulator integration build for the mobile llama.cpp lane and isolate the remaining static-link failure.

## Observed state and verification

Both simulator builds compiled a 385 MB arm64 Rust archive and reached the final Xcode link. Both failed on identical unresolved cpp-httplib symbols. Cargo feature inspection proved llama-cpp-2 0.1.151 activates llama-cpp-sys-2 default common because the upstream dependency declaration does not disable sys defaults; removing common downstream cannot change that edge. Xcode Metal and Rust iOS targets are installed. No third build was attempted.

## Decision and lesson

Status: blocked. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Pin a reviewed upstream or owned patch that sets default-features false on the llama-cpp-sys-2 edge, then restart the two-attempt audit with an iOS simulator link followed by real model download and generation throughput proof.
