---
sidebar_position: 2
title: Inference lanes
---

# Per-device engines, per-turn lanes

Two choices are frequently conflated. They are orthogonal.

| Choice | Scope | Selected |
|---|---|---|
| **Engine** | per **device** | at build time, by feature flag |
| **Lane** | per **turn** | at runtime, by the user |

The `local` lane means "run on this device." *Which* engine that implies depends
entirely on what device it is.

## Engines

| Surface | Engine | Feature flag | Shape |
|---|---|---|---|
| Desktop | llama-cpp-2 | `local-llama` (+ `-metal` / `-opencl` / `-mtmd`) | In-process, GGUF |
| Android | **LiteRT-LM** | `local-litert-lm` | Rust + Kotlin bridge over JNI |
| iOS | **MLX-Swift** | `local-mlx` | Rust + Swift bridge over a C vtable |
| macOS | **MLX-C** (`mlex`) | `local-mlxc` | In-process, Apple mlx-c (no Python) |
| Web | WebLLM | — (TypeScript surface) | MLC WebGPU |
| Desktop (optional) | mistral.rs | `local-mistral` | Experimental |

All implement `gen_ui_types::inference::InferenceProvider`. Callers depend on the
trait; only `gen_ui_inference` depends on an engine. That is what makes a lane
swap a one-crate change rather than an app-wide refactor.

Current values live in `versions.toml` `[inference]`. Read them there — do not
copy them into code.

### Why Android is not llama.cpp

This is the assumption worth correcting. llama.cpp *builds* for Android, so it
looks like the obvious single mobile engine. In practice its GPU path
(OpenCL/Adreno) proved **device-specific**: it works on the phone you tested and
fails on the next one.

For a correctness baseline that is the worst available failure shape — it passes
your CI and fails your users. LiteRT-LM runs everywhere on CPU, so it is the
Android default; llama.cpp stays out of Android production.

**There is no "mobile engine."** A `mobile = ...` key, or a `cfg(mobile)` branch
selecting an engine, is the bug this table exists to prevent.

## The three lanes

```rust
pub const LANE_CLOUD: &str = "cloud";  // BYOK remote; cannot be zero-config default
pub const LANE_LOCAL: &str = "local";  // on-device; model_id, no provider_id
pub const LANE_UAR:   &str = "uar";    // embedded-library on mobile, never a sidecar
```

Parse through the `Lane` enum. **Reject unknown lanes loudly** — never a
`_ => default` arm. A silent fallback runs the turn somewhere the user did not
choose, and on the `cloud` lane that means data leaving the device.

## Half Rust, half native

The Android and iOS lanes are split across languages:

- **Rust owns** catalog, download, verification, RAM preflight, tool policy, and
  event normalization.
- **The native bridge owns** only the vendor SDK's generation call.

The halves bind by **symbol name** — the JNI fully-qualified class path, and the
Swift `@_silgen_name` symbol. Both are generated from the same placeholders so
they cannot drift.

Two traps worth stating outright:

- The JNI package path must be a **legal Java identifier**. `com.example.my-app`
  is not — hyphens are illegal in Java/Kotlin package names. Rust holds it as a
  plain string, so nothing complains until class resolution fails on device.
- A Swift file present on disk but absent from `project.pbxproj` **is not
  compiled**. The symptom is a missing symbol, not a missing file.

## Model acquisition

Each requirement exists because of a distinct failure:

| Requirement | Failure it prevents |
|---|---|
| Resumable | A dropped connection at 90% of a multi-GB file restarting from zero |
| Revision-pinned | "Latest" silently changing weights under a cached path |
| SHA-256 verified | A truncated file loading as a broken model |
| Small files first | Discovering a bad revision after gigabytes instead of seconds |
| No partial file at the final path | A resumed run treating an incomplete file as done |

## Memory preflight

On iOS an over-budget load is a **jetsam process kill** — no exception, no log,
no chance to recover. The gate therefore runs *before* the load, not around it.

Compute the budget from physical memory and keep the fraction conservative: the
OS and the app's own non-model allocations draw on the same pool.

## Verification

Host checks keep feature-gated modules from rotting:

```bash
cargo check -p gen_ui_inference --features local-litert-lm
cargo check -p gen_ui_inference --features local-mlx
```

They prove nothing about whether a lane *works*. Local lanes fail at model load,
on device, after every host check passes:

```bash
node scripts/android/verify-native-inference-gates.mjs   # arm64-only APK, required .so
node scripts/android/verify-device-runtime-gates.mjs     # no JNI/dlopen failure in logcat
```

Record the result in `docs/platform-support.md`.
