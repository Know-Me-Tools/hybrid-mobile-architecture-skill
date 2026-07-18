---
sidebar_position: 2
title: Flutter-only mobile with Rust FFI
description: Staged prompts for a Flutter mobile app whose networking, persistence, sync, inference, and agent behavior live in Rust.
---

# Flutter-only mobile with Rust FFI

Use this recipe when the product is mobile-only but still needs the Prometheus
architecture invariant: Flutter renders and orchestrates UI state through
providers; Rust owns behavior.

## Prerequisites

```text
Verify Flutter beta, Dart codegen, Xcode/Android toolchains, Rust 1.96+,
flutter_rust_bridge_codegen version alignment, and device/simulator availability.
```

## Discovery prompt

```text
Read AGENTS.md, CLAUDE.md, arch standard, Flutter patterns, Rust patterns, FRB
configuration, generated file conventions, and existing mobile source layout.
```

## Feynman prompt

```text
Explain Flutter screen→Riverpod provider→domain/data repository→Rust FFI
layering and why Flutter must not own networking, persistence, sync, inference,
or agent behavior. Grade the explanation and list gaps.
```

## KBD prompts

```text
/kbd-assess flutter-rust-ffi
Assess the feature goal, platform targets, launch proof, restart persistence,
offline behavior, parity expectations, and UI/accessibility standard.
```

```text
/kbd-analyze flutter-rust-ffi
Analyze Flutter features, provider generation, Rust API surface, bridge
generation, build scripts, platform linker settings, and persistence flows.
```

```text
/kbd-spec flutter-rust-ffi
Specify domain contracts, Riverpod providers, FRB-generated API, Rust-owned
services, UI shell, golden/a11y checks, launch evidence, and restart persistence.
```

```text
/kbd-plan flutter-rust-ffi
Plan Rust API changes before Dart adapters, then provider/domain implementation,
screen wiring, code generation, platform build repair, launch proof, tests,
critic, and retention.
```

## Implementation prompt

```text
Implement one waypoint at a time. Move domain behavior out of screens, use
generated Riverpod providers, regenerate FRB and build_runner outputs, and keep
all side effects behind Rust/domain boundaries.
```

## Public-boundary verification

```text
Run code generation, flutter analyze, flutter test, build or launch iOS/Android,
create state through the UI, restart, and verify persisted state returns through
the Rust boundary.
```

## Critic and retention

```text
Review layering, generated outputs, platform launch logs, restart persistence,
UI parity, and whether any Dart screen directly owns persistence or network
behavior. Record versions, failures, fixes, and launch evidence in memory.
```

## Stop conditions

Stop for missing simulator/device, FFI generation mismatch, platform linker
failure, hidden direct persistence in UI, repeated launch failure, or missing
restart proof.
