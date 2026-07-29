---
sidebar_position: 3
title: First project
description: Generate or adopt a KnowMe Builder application safely, install its skills, and verify its control and runtime boundaries.
---

# Your first Builder project

This walkthrough shows the supported sequence. It deliberately separates
generation, development control, runtime authority, and release evidence.

## 1. Verify the workstation

```bash
knowme-builder --version
prometheus doctor --json
knowme-builder manifest check
```

Fix missing control-plane requirements before generating. Builder hooks are
advisory and cannot replace Prometheus pause, resume, cancel, lease, audit, or
handoff behavior.

## 2. Choose generation or adoption

For a new application:

```bash
knowme-builder new my-app \
  --profile sovereign-hybrid \
  --mode runnable \
  --check

knowme-builder new my-app \
  --profile sovereign-hybrid \
  --mode runnable
```

For an evolved application:

```bash
knowme-builder adopt existing-app \
  --profile governed-web-shell \
  --check

knowme-builder adopt existing-app \
  --profile governed-web-shell \
  --apply
```

Never turn an existing application into a “new” destination with `--force`.
Adoption records Builder state without claiming ownership of existing files.

## 3. Inspect the tracked state

Review:

- `.knowme-builder/project.toml` for profile, Builder version, UAR mode,
  surfaces, and policy-overlay path;
- `.knowme-builder/generated.lock.json` for Builder-owned file digests;
- `skills-lock.json` for Builder, Prometheus, OpenSpec, and third-party skill
  pins; and
- `.knowme-builder/policy-overlay.toml` for project-specific rules.

Do not place client-specific roles or policy in reusable Builder skills.

## 4. Verify skill installation

```bash
knowme-builder skills check --path my-app
```

Start a fresh session in Claude Code, Codex, OpenCode, or Kimi and explicitly
invoke one skill:

```text
/agent-runtime-security Review the tool boundary for this project.
```

The harness should load the project copy of the skill. Advisory activation may
suggest related skills, but lifecycle changes still go through Prometheus.

## 5. Start controlled work

Use Prometheus KBD commands for development state:

```bash
prometheus kbd status --json
prometheus kbd claim
prometheus kbd audit
```

Use `prometheus kbd pause`, `resume`, `cancel`, `revise`, and `handoff` as
operator controls. Treat waypoint, progress, and position JSON files as
read-only compatibility projections.

## 6. Add a capability

Preview before applying:

```bash
cd my-app
knowme-builder add feature conversations --path . --check
knowme-builder add feature conversations --path .
```

The addition is emitted as a typed proposal under `.knowme-builder/additions`.
Integrate it through the project’s architecture rather than copying generated
snippets into arbitrary layers.

## 7. Run architecture and runtime gates

```bash
knowme-builder audit --path .
knowme-builder --json doctor --path .
```

Then run the profile’s real toolchain. For example, a hybrid profile normally
includes Rust format/clippy/test, Flutter analyze/test/build, TypeScript
typecheck/test/build, Tauri command/permission parity, deterministic UAR runs,
persistence recovery, and security tests.

Invoke `hybrid-runtime-verification` before describing the result as working.
If a native bridge, platform baseline, or local inference engine changed,
record current physical-device evidence.

## 8. Upgrade safely

```bash
knowme-builder upgrade . --check
```

Review every conflict. An upgrade is intentionally allowed to stop; preserving
a consumer’s deliberate modification is more important than making the
generator appear idempotent.
