---
sidebar_position: 2
title: CLI reference
description: Complete command reference for the knowme-builder non-destructive application generator.
---

# `knowme-builder` CLI

The CLI is the supported mutation boundary for Builder-owned application
artifacts. Shell scripts remain compatibility wrappers and emit deprecation
notices where a typed CLI command exists.

Use the global `--json` option before the subcommand in automation:

```bash
knowme-builder --json doctor --path .
```

JSON results describe the operation, target path, selected profile, planned or
completed actions, conflicts, warnings, whether files changed, and overall
success.

## Safety model

Every mutation-capable workflow follows these rules:

- an explicit profile is required when architecture would otherwise be
  ambiguous;
- previews do not modify the target;
- a new project is rendered in a temporary directory, validated, then renamed;
- non-empty destinations are rejected unless adoption or force was explicit;
- user-owned files are not silently overwritten;
- Builder-owned files carry source and installed digests; and
- modified managed files produce a conflict instead of being replaced.

## `new`

Create a validated application in a new destination:

```bash
knowme-builder new <path> \
  --profile sovereign-hybrid \
  --mode runnable
```

Options:

| Option | Meaning |
|---|---|
| `--profile` | Required architecture profile |
| `--mode runnable` | Emit one functioning deterministic agentic vertical slice |
| `--mode skeleton` | Emit explicitly marked unsupported/TODO surfaces |
| `--check` | List the paths that would be generated |
| `--adopt` | Treat a non-empty destination as an adoption request |
| `--force` | Explicitly replace a destination; mutually exclusive with adopt |

Prefer `adopt` for any evolved application. `--force` is for disposable
destinations and should not be used as an upgrade strategy.

## `adopt`

Add Builder state, skills, policy overlay, and profile metadata to an existing
application without re-scaffolding it:

```bash
knowme-builder adopt <path> --profile governed-web-shell --check
knowme-builder adopt <path> --profile governed-web-shell --apply
```

`--check` and `--apply` are mutually exclusive and one is required. Adoption
creates:

- `.knowme-builder/project.toml`;
- `.knowme-builder/generated.lock.json`;
- `.knowme-builder/policy-overlay.toml`;
- `.knowme-builder/activation-manifest.json`; and
- the pinned `skills-lock.json` and project skill payloads.

Adoption does not claim ownership of existing application files.

## `upgrade`

Preview or apply a new Builder version to files already recorded as
Builder-owned:

```bash
knowme-builder upgrade <path> --check
knowme-builder upgrade <path> --apply
```

The engine compares three digests: the generated source, the last installed
content, and the current consumer file.

| Current state | Result |
|---|---|
| Current equals last installed | Safe replacement |
| Current differs from last installed | Conflict and proposed patch |
| No ownership metadata | User-owned; no replacement |
| Source digest unchanged | No-op |

Resolve conflicts deliberately, then update ownership metadata through the
supported upgrade flow.

## `add`

Add a typed capability to an adopted project:

```bash
knowme-builder add feature conversations --path .
knowme-builder add auth verified-session --path .
knowme-builder add module reporting --path .
knowme-builder add legacy-embed frozen-portal --path .
```

Kinds:

| Kind | Generated contract |
|---|---|
| `feature` | Feature manifest and implementation guidance |
| `auth` | Verified-session authentication addition |
| `module` | Versioned mini-app/module manifest |
| `legacy-embed` | Versioned, origin-checked bridge contract |

Use `--check` to preview. Additions are stored under
`.knowme-builder/additions/<kind>/<name>` so an application can review and
integrate them without overwriting feature code.

## `skills`

Install or verify the complete canonical skill bundle:

```bash
knowme-builder skills install --path .
knowme-builder skills install --path . --check
knowme-builder skills install --path . --force
knowme-builder skills check --path .
```

`check` is read-only. A normal install refuses drifted targets and writes
proposals under `.knowme-builder/conflicts`. `--force` preserves the initial
pre-Builder copy in `.knowme-builder/backups` before replacement.

## `audit`

Check whether the expected surfaces for a profile exist and report unsafe
compatibility-state use:

```bash
knowme-builder audit --path . --profile sovereign-hybrid
knowme-builder --json audit --path .
```

An adopted project supplies its profile automatically. Supplying `--profile`
is useful for a pre-adoption assessment.

The audit intentionally does not claim runtime success. Use the
`hybrid-runtime-verification` skill and profile-specific CI for launch,
persistence, workflow, and device evidence.

## `doctor`

Check the package manifest, external contracts, Prometheus control plane, and
project integration:

```bash
knowme-builder --json doctor --path .
```

The doctor calls `prometheus doctor --json` and verifies its machine-readable
contract version. A healthy directory without a compatible Prometheus control
plane is not a healthy Builder development environment.

## `manifest`

Generate or verify the target-specific plugin, marketplace, activation, and
capability manifests derived from `builder.manifest.json`:

```bash
knowme-builder manifest generate
knowme-builder manifest check
```

Generated targets are reviewable artifacts but not independent authorities.
CI rejects hand-edited drift.

## `completions`

Print shell completion definitions:

```bash
knowme-builder completions bash
knowme-builder completions zsh
knowme-builder completions fish
knowme-builder completions power-shell
knowme-builder completions elvish
```

## Exit behavior

Argument errors, invalid profiles, malformed project state, unsafe
destinations, stale ownership, missing contracts, and failed health checks
produce a non-zero exit. Automation should inspect both the exit code and JSON
result rather than scraping human prose.
