---
sidebar_position: 6
title: Utilities and automation
description: Exhaustive catalog of KnowMe Builder CLI workflows, compatibility scripts, generators, audits, documentation utilities, templates, and CI workflows.
---

# Utilities and automation

The Rust CLI is the supported application mutation boundary. Shell utilities
either bootstrap external tools, verify the package, or preserve compatibility
with the pre-2.0 interface.

## Public CLI utilities

| Utility | Use it for | Important behavior |
|---|---|---|
| `knowme-builder new` | New project generation | Explicit profile/mode; temporary render and atomic rename |
| `knowme-builder adopt` | Existing application adoption | Records state without re-scaffolding or claiming existing files |
| `knowme-builder upgrade` | Managed-file upgrades | Replaces only unchanged owned files; conflicts otherwise |
| `knowme-builder add` | Feature, auth, module, or legacy bridge proposal | Writes typed additions under Builder state |
| `knowme-builder skills` | Install/check 29 skills | Six project harness trees and digest lock |
| `knowme-builder audit` | Profile structure and compatibility checks | Does not claim runtime success |
| `knowme-builder doctor` | Builder/UAR/Prometheus/harness health | Calls machine-readable Prometheus doctor |
| `knowme-builder manifest` | Generate/check package manifests | Detects hand-edited generated drift |
| `knowme-builder completions` | Shell completion definitions | Bash, Zsh, Fish, PowerShell, and Elvish |

## Compatibility and application scripts

| Script | Purpose | Preferred 2.0 path |
|---|---|---|
| `add-auth.sh` | Add an authentication proposal | `knowme-builder add auth` |
| `new-feature.sh` | Add a feature proposal | `knowme-builder add feature` |
| `scaffold-hybrid.sh` | Legacy full hybrid scaffold entry point | `knowme-builder new --profile sovereign-hybrid` |
| `scaffold-flutter.sh` | Legacy Flutter scaffold | `knowme-builder new --profile flutter-mobile` |
| `scaffold-tauri.sh` | Legacy Tauri scaffold | `knowme-builder new --profile tauri-desktop` |
| `scaffold-rust-core.sh` | Legacy Rust workspace scaffold | Use a profile or maintained Rust templates through the CLI |
| `scaffold-packages.sh` | Legacy shared-package generation | `knowme-builder add module` where applicable |
| `add-project-skills.sh` | Install project-local skill copies and legacy hooks | `knowme-builder skills install` |

Compatibility wrappers exist so older automation fails gradually and receives a
deprecation notice. New documentation and automation should use the CLI.

## Workstation bootstrap utilities

| Script | Purpose | When to run |
|---|---|---|
| `check-env.sh` | Check or install the four pinned toolchain pillars | Before generation and after toolchain changes |
| `install-flutter.sh` | Install/switch the pinned Flutter beta, optionally through FVM | When Flutter is absent or on the wrong channel |
| `install-global-harnesses.sh` | Install all skills, commands, adapters, plugin payloads, and MCP entries | Initial setup and every Builder upgrade |
| `merge-zed-context-servers.mjs` | Non-destructively add Dart/shadcn context servers to Zed | Called by the global installer; Zed is an auxiliary integration |
| `patch-cargokit-ios.sh` | Apply the maintained iOS Cargokit compatibility patch | Only when the selected Flutter/Rust bridge baseline requires it |

## Generation utilities

| Script | Generates | Authority |
|---|---|---|
| `generate-builder-manifests.mjs` | Plugin, marketplace, activation, and capability manifests | `builder.manifest.json` |
| `generate-command-contract.mjs` | Rust registration, Tauri permissions, TypeScript/Dart bindings, tests | Command manifest under `assets/templates/command-contract` |
| `generate-skill-metadata.mjs` | `agents/openai.yaml` for every skill | Canonical `SKILL.md` frontmatter |
| `generate-skill-evals.mjs` | Positive, negative, near-miss, and trace evaluation data | Canonical skills and evaluation policy |
| `gen-design-tokens.sh` | Tailwind/CSS and Flutter token outputs | `assets/templates/design-tokens/tokens.toml` |
| `sync-harness-skills.sh` | Six repository harness trees | `templates/project-skills` |
| `site/scripts/generate-skill-reference.mjs` | 29 public skill reference pages | Canonical skills plus `docs/catalog/skill-guidance.json` |
| `site/scripts/generate-model-routing.mjs` | Dated public model-routing table | Prompting model registry |

Generated files are checked into the repository for review and distribution,
but their source manifests remain authoritative.

## Audit and verification utilities

| Script | Checks |
|---|---|
| `audit.sh` | Flutter, Tauri, Rust, documentation consistency, generator purity, or all detected surfaces |
| `check-builder-authority.mjs` | Manifest schema, declared skills/templates/targets, version coherence, and release completeness |
| `check-prometheus-boundary.mjs` | Builder does not duplicate Prometheus lifecycle or mutation authority |
| `check-runtime-security.mjs` | Raw MCP, identity, tool governance, tenant, and runtime boundary invariants |
| `check-skill-contracts.mjs` | Agent Skills metadata, reference reachability, evaluation coverage, and skill declarations |
| `verify-scaffold.sh` | Scratch generation, expected tree, placeholders, manifests, and compatibility shape |
| `verify-tauri-boot.sh` | Bounded Tauri launch and ready-state evidence |
| `site/scripts/sanitize.mjs` | Machine paths, private data, credentials, raw evidence, and unsupported public claims |
| `site/scripts/validate-prompting.mjs` | Prompting schemas, harness records, and recipe integrity |
| `site/scripts/test-prompting-fixtures.mjs` | Positive and negative prompting fixtures |
| `site/scripts/validate-skill-parity.mjs` | Public skill catalog and distributed payload parity |
| `site/scripts/test-orchestration-skill.mjs` | Orchestration references and critical behavior |
| `site/scripts/validate-style-contract.mjs` | Flat 2.0 and supported theme styling |
| `site/scripts/validate-built-site.mjs` | Required routes, sitemap, search, and social metadata |
| `site/scripts/check-links.mjs` | Internal or external built-site links |
| `site/scripts/browser-publication-gate.mjs` | Responsive light/dark screenshots and accessibility |

## Maintenance and analysis utilities

| Script | Purpose | Publication rule |
|---|---|---|
| `consolidate-prometheus-wikis.py` | Consolidate internal Prometheus knowledge during maintenance | Raw wiki material is not public site input |
| `worktree-consolidation-inventory.py` | Inventory divergent worktrees before safe consolidation | Report first; do not overwrite dirty worktrees |
| `lib-knowme-builder.sh` | Locate/run the CLI and print wrapper deprecations | Internal shell library |
| `lib-versions.sh` | Read pinned values from `versions.toml` | Internal shell library; scripts must not duplicate pins |

## Maintained template utilities

| Template group | Produces | Typical consumer |
|---|---|---|
| `flutter-feature` | Domain, repository, data source, Riverpod provider, screen, tests | Flutter feature work |
| `tauri-feature` | React/Tauri feature layers | Desktop/web feature work |
| `rust-core` | Shared Rust application-service workspace | All native profiles |
| `rust-adapters` | Context, inference, type, and vendor adapter crates | Runtime integration |
| `native-bridges` | Android and iOS inference/FFI bridges | Sovereign and Flutter profiles |
| `build-scripts` | Android/iOS verification and packaging scripts | Native CI and certification |
| `profile-projects` | Runnable and skeleton profile baselines | `knowme-builder new` |
| `command-contract` | Cross-language command and event bindings | Tauri/Flutter parity |
| `capability-additions` | Feature/auth/module/legacy-embed proposals | `knowme-builder add` |

## CI workflows

| Workflow | Responsibility |
|---|---|
| `production-convergence.yml` | Builder CLI, manifests, skills, profiles, security, generation, and installation gates |
| `scaffold-ci.yml` | Legacy and profile scaffold compatibility |
| `docs-pages.yml` | Frozen Docusaurus build, validation, and GitHub Pages publication |
| `deployment-catalog-ci.yml` | Deployment catalog correctness |
| `deployment-publish.yml` | Build and publish immutable deployment artifacts |
| `deployment-mirror-promote.yml` | Mirror and promote reviewed digests |

The workflows are deliberately separate. Documentation publication cannot
deploy application services, and application CI cannot certify a physical
device without attached evidence.
