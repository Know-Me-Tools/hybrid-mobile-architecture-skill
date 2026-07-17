# 2026-07-16-c114-desktop-app-actually-runs

> Phase: phase-codegen-and-ci-verification · Status: proposed
> Depends on: (none — this is the phase's actual goal)
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

The phase's stated goal is **"a functioning app that we have tested on web and desktop
using Tauri."** Thirteen changes were planned and nine merged, but until 2026-07-16 late
session **nobody had ever built or launched the desktop app**. When someone finally did,
three ship-blockers surfaced immediately — every one invisible to `cargo check`,
`cargo clippy`, `tsc`, `vitest`, `flutter analyze`, and CI, all of which were green.

This change exists because closing feature changes was measuring the wrong thing.

## What was found (2026-07-16, by finally running it)

1. **The Tauri app did not compile.** `src-tauri` is a SEPARATE workspace with its own
   `Cargo.lock`, so the candle `[patch]` added to `rust/Cargo.toml` never applied. It
   pulls the inference lane in transitively via `tauri-plugin-gen-ui` (a path dep), so it
   inherited mistral.rs but not the patch that makes mistral.rs build. `cargo check` in
   `rust/` was green while the actual shipping binary failed on the same E0308 fixed
   hours earlier. **FIXED** (commit ee128bc) — the patch now exists in both workspaces.

2. **The production frontend bundle had never been built.** `vite build` failed with 103
   errors: esbuild cannot downlevel the dependencies' destructuring to `safari13`, the
   Tauri scaffold default nobody revisited. `tsc` passes and `vite dev` works — only the
   production bundle goes through esbuild's transform. **FIXED** (commit 93093e5) —
   `safari15`, the lowest that builds (bisected; 14 still fails).

3. **The app launches but its backend never initialises.** With both above fixed, the
   binary runs and the window opens, but
   `~/Library/Application Support/ai.prometheusags.knowme-poc/` stays **empty** — no
   `config-db`, no `memory-db`. `run_migrations` is not completing, so there is no config
   store, no memory store, and no `gen_ui_agent::state`. Chat and memory cannot work.
   **NOT FIXED — this is the change.**

## What changes

- Diagnose why `run_migrations` does not complete in the real binary. `StartupGate`
  blocks on it and `main.tsx` mounts it, so the wiring looks right; the failure is
  somewhere in the invoke → command → pglite/SurrealDB open path, and it is silent
  (the app emits no log output even at `RUST_LOG=debug`, which is itself a finding —
  a boot failure the user cannot see is worse than a crash).
- Then actually exercise the goal: boot → seed → chat + memory search, on desktop, once.
- Add a CI job that BUILDS and LAUNCHES the app. Every green check today verified a path
  adjacent to the one that ships; that gap is the root cause of all three findings and
  of the four "verified but broken in production" changes found earlier this session
  (memory search never worked; the desktop chat lane rendered nothing since C-103).

## Impact

- No new features. This is the difference between "thirteen changes closed" and "the app
  runs", which is what the phase was actually asked for.
