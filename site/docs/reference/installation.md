---
sidebar_position: 1
title: Installation
description: Install KnowMe Builder skills and native plugins for Claude Code, Codex, OpenCode, Kimi Code, MiniMax Code CLI, and Zed.
---

# Install KnowMe Builder

KnowMe Builder `2.0.0-alpha.4` publishes exactly 36 public, self-contained Agent
Skills from:

```text
https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
```

The public set is the package-level `hybrid-mobile-architecture` skill plus 35
project companions. Repository-only OpenSpec/OPSX authoring helpers are hidden
from normal discovery.

## Portable Git URL installation

From a trusted checkout, install the public skill source:

```bash
npx skills add ./skills \
  --skill '*' -a claude-code -a codex -a opencode -g -y
```

List the catalog without writing:

```bash
npx skills add ./skills --list
```

## Claude Code marketplace

```bash
claude plugin marketplace add \
  https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
claude plugin install hybrid-mobile-architecture@knowme-builder --scope user
claude plugin list
```

Update and remove through Claude's supported CLI:

```bash
claude plugin marketplace update knowme-builder
claude plugin uninstall hybrid-mobile-architecture@knowme-builder --scope user
```

## Codex marketplace

```bash
codex plugin marketplace add \
  https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill --ref main
codex plugin add hybrid-mobile-architecture@knowme-builder
codex plugin list
```

Update and remove through Codex's supported CLI:

```bash
codex plugin marketplace upgrade knowme-builder
codex plugin remove hybrid-mobile-architecture@knowme-builder
```

## OpenCode plugin model

OpenCode has no native Git marketplace. Its supported model is Agent Skills in
the OpenCode/Claude/Agents discovery directories plus local JavaScript or
TypeScript files in `.opencode/plugins` or `~/.config/opencode/plugins`.

Use the portable installation command for skills. From a trusted checkout, use
the unified installer to add the dependency-free advisory plugin and commands:

```bash
git clone https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
cd hybrid-mobile-architecture-skill
node scripts/install-harness-package.mjs --harness opencode \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
opencode debug skill
```

Update and safely uninstall only the receipt-owned OpenCode payload:

```bash
git pull --ff-only
node scripts/install-harness-package.mjs --harness opencode \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
node scripts/install-harness-package.mjs --harness opencode --uninstall
```

## Unified installer

The receipt-based installer can configure all six harnesses:

```bash
node scripts/install-harness-package.mjs \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
```

Supported options are:

```text
--harness claude-code|codex|opencode|kimi-code|minimax-code|zed|all
--scope user|project
--source <git-url-or-path>
--ref <git-ref>
--check
--uninstall
--with-cli
--with-mcp
--with-prometheus
```

The default installs only skills, native marketplace registrations, commands,
and advisory adapters. CLI compilation, MCP mutation, and the long Prometheus
bootstrap require their explicit flags. The compatibility wrapper
`scripts/install-global-harnesses.mjs` delegates to the same installer.

The installer preserves unrelated files and records ownership under the XDG
state directory for user scope or `.knowme-builder/harness-install.json` for
project scope. Uninstall removes only receipt-owned surfaces.

Kimi Code receives both `~/.kimi-code/skills` and the shared
`~/.agents/skills`; Zed uses `~/.agents/skills`; MiniMax Code uses its resolved
data directory (`$MINIMAX_DATA_DIR`, `$MAVIS_DATA_DIR`, or `~/.minimax`).

For an all-harness install, use this exact check, update, and uninstall cycle:

```bash
node scripts/install-harness-package.mjs --check \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
git pull --ff-only
node scripts/install-harness-package.mjs \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
node scripts/install-harness-package.mjs --uninstall
```

## Optional Builder CLI

Install from the unified entry point:

```bash
node scripts/install-harness-package.mjs --with-cli
knowme-builder --version
```

Or build explicitly from a trusted checkout:

```bash
cargo install --locked --path tools/knowme-builder
```

## Project-local skills

Generated and adopted applications receive the 35 companion skills, not the
package-level distribution skill:

```bash
knowme-builder skills install --path <project>
knowme-builder skills check --path <project>
```

Conflicting existing directories are preserved and reported rather than
silently overwritten.

## Prometheus dependency

Prometheus remains an external dependency. Builder requires package `1.7.0` or
newer and control-plane contract `2.0.0` or newer. The current source and
runbooks are:

- [Prometheus Skill System](https://github.com/Prometheus-AGS/prometheus-skill-system)
- [Installation](https://github.com/Prometheus-AGS/prometheus-skill-system/blob/main/docs/guide/19-installation.md)
- [Updating](https://github.com/Prometheus-AGS/prometheus-skill-system/blob/main/docs/guide/20-updating.md)

`knowme-builder doctor` reports package compatibility, control-plane contract
compatibility, typed KBD/durable-learning capability availability, and
operational service health separately.

## Verify

```bash
knowme-builder --json doctor --path <project>
knowme-builder skills check --path <project>
prometheus --version
prometheus doctor --json
prometheus learning status --json
claude plugin list
codex plugin list
opencode debug skill
```

Repository maintainers additionally run:

```bash
node scripts/check-skill-contracts.mjs
node scripts/sync-skill-resources.mjs --check
node scripts/sync-harness-skills.mjs --check
node scripts/check-git-url-discovery.mjs
node scripts/test-harness-installer.mjs
```
