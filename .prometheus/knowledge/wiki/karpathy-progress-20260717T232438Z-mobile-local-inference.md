---
type: Reference
id: karpathy-progress-20260717T232438Z-mobile-local-inference
title: "iOS local llama chat build and launch verified"
tags:
- karpathy-progress
- mobile-local-inference
- verified
sources:
- conversation:operator-agent
timestamp: 2026-07-17T23:24:38Z
created_at: 2026-07-17T23:24:38Z
updated_at: 2026-07-17T23:24:38Z
revision: 1
---

## Intent

Patched llama-cpp-2 0.1.151 so disabling common actually disables llama-cpp-sys-2 common, then separated mobile Scribe from the default FFI lane because whisper.cpp and llama.cpp cannot safely co-link two GGML implementations into one force-loaded iOS archive.

## Observed state and verification

cargo tree for aarch64-apple-ios-sim showed llama-cpp-sys-2 with no common feature; gen_ui_inference Clippy passed; flutter build ios --simulator --debug built Runner.app; simctl launched ai.prometheusags.mobile; screenshot showed the KnowMe Home shell; the simulator app container contained entity-records.sqlite3, knowme-poc.db, and model-cache directories.

## Decision and lesson

Status: verified. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Propagate the pinned wrapper patch and explicit mobile inference feature contract into generated projects, then verify local chat model download and streamed generation through the Flutter UI.
