---
sidebar_position: 1
title: Installation
description: Install KnowMe Builder, its CLI, skills, commands, advisory adapters, plugins, and MCP utilities across Claude Code, Codex, OpenCode, and Kimi.
---

# Install KnowMe Builder

KnowMe Builder has three installation layers. Install the layers that match how
you work:

1. **The CLI** performs versioned, ownership-aware generation and adoption.
2. **The workstation bundle** installs skills, slash commands, advisory
   activation adapters, plugin payloads, and supported MCP utilities.
3. **Project-local adoption** pins the exact Builder and Prometheus contracts
   that an application expects.

The layers are separate on purpose. A globally installed skill can help you
reason about any repository, while a project-local lock records what that
specific application was generated and reviewed against.

## Prerequisites

For the Builder itself:

- Git;
- Rust and Cargo matching `versions.toml`;
- `rsync`, `jq`, and Node.js for the cross-harness installer; and
- Prometheus CLI contract `2.0.0` or newer for lifecycle and KBD coordination.

Application profiles add their own toolchains:

| Surface | Required tools |
|---|---|
| Flutter mobile | Flutter beta pin, Dart, platform SDKs, FRB code generation |
| Tauri desktop | Rust, Node.js, pnpm, Tauri CLI, OS build prerequisites |
| Axum/web | Rust, Node.js, pnpm |
| Local inference | Platform-native SDK and physical-device verification for the selected engine |

Check the pinned stack without changing the machine:

```bash
bash scripts/check-env.sh
```

Use `--install` for normal remediation and `--full` only when you intend to run
the expensive Flutter and full Prometheus bootstrap operations:

```bash
bash scripts/check-env.sh --install
bash scripts/check-env.sh --full
```

## Build and install the CLI

From a trusted checkout:

```bash
cargo build --release --locked --manifest-path tools/knowme-builder/Cargo.toml
install -m 0755 tools/knowme-builder/target/release/knowme-builder \
  "$HOME/.cargo/bin/knowme-builder"
knowme-builder --version
```

If the repository participates in a parent Cargo workspace, Cargo may place the
binary in the workspace-level `target/release` directory. Use the path printed
by Cargo rather than assuming the crate-local target directory.

Generate shell completion text with:

```bash
knowme-builder completions bash
knowme-builder completions zsh
knowme-builder completions fish
```

Redirect the output into the completion directory used by your shell.

## Install all harness payloads

Run the idempotent workstation installer:

```bash
bash scripts/install-global-harnesses.sh
```

It installs:

- the root `hybrid-mobile-architecture` skill;
- all 29 companion skills;
- native command wrappers for the eight Builder workflows;
- advisory activation adapters;
- Claude and Codex marketplace/plugin payloads;
- Dart and shadcn MCP entries where the harness supports them; and
- the shared generic-agent skill copies used by compatible tools.

The canonical companion-skill source is
`templates/project-skills`. The installer mirrors that source into:

| Consumer | Installed location |
|---|---|
| Claude Code | `~/.claude/skills` |
| Codex | `~/.codex/skills` |
| OpenCode | `~/.opencode/skills` and `~/.config/opencode/skills` |
| Kimi Code CLI | `~/.kimi-code/skills` and `~/.kimi/skills` |
| Generic Agent Skills discovery | `~/.agents/skills` |

The installer owns only the Builder-namespaced payloads. It preserves unrelated
skills, commands, hooks, and MCP configuration.

## Install native marketplace plugins

The global installer creates relocatable local marketplace payloads. Register
and install them through each native CLI so the harness records the plugin in
its own registry.

Claude Code:

```bash
claude plugin marketplace add "$HOME/.claude/plugins/marketplaces/knowme-hybrid-architecture"
claude plugin install hybrid-mobile-architecture@knowme-builder --scope user
claude plugin list
```

Codex:

```bash
codex plugin marketplace add "$HOME/.codex/plugins/cache/knowme-hybrid-architecture"
codex plugin add hybrid-mobile-architecture@knowme-builder
codex plugin list
```

Marketplace names can differ if an operator registered the source under a
custom name. Use `claude plugin marketplace list` or
`codex plugin marketplace list` to obtain the configured name before
installing.

OpenCode and Kimi consume their generated skill, command, and adapter payloads
directly. Restart already-running harness sessions after installation so they
rebuild discovery indexes.

## Install into a project

For an adopted or generated application:

```bash
knowme-builder skills install --path <project>
knowme-builder skills check --path <project>
```

Installation writes the same 29 skills to all six project discovery trees:
`.claude`, `.codex`, `.opencode`, `.kimi-code`, `.kimi`, and `.agents`.
It also refreshes `skills-lock.json`.

When a target skill directory already differs, installation reports a conflict
instead of overwriting it. Review the proposed payload under
`.knowme-builder/conflicts`. Use `--force` only after deciding that the existing
copy should be replaced; the initial copy is preserved under
`.knowme-builder/backups`.

## Verify the complete installation

Run both product and control-plane health checks:

```bash
knowme-builder --json doctor --path <project>
prometheus doctor --json
knowme-builder skills check --path <project>
```

Then verify native discovery:

```bash
claude plugin list
claude mcp list
codex plugin list
codex mcp list
opencode debug skill
opencode mcp list
kimi doctor config
```

Success means more than “the directory exists.” The skill count, payload
digests, generated commands, executable helper scripts, plugin version, and
project lock must agree with the canonical package.

## Updating

Update from a trusted source, rebuild the CLI, rerun the global installer, then
preview project changes:

```bash
knowme-builder upgrade <project> --check
knowme-builder upgrade <project> --apply
knowme-builder skills check --path <project>
```

The upgrade engine replaces only Builder-owned files whose current digest still
matches the last installed digest. Modified managed files produce a conflict
report and proposed replacement. Files without ownership metadata remain
user-owned.

## Uninstalling or rolling back

Before stable cutover, restore project payloads from
`.knowme-builder/backups` and restore the previous `skills-lock.json`.
After cutover, an upgrade conflict stops the operation; the Builder never
silently falls back to untracked copies.

Remove native plugins through the harness’s plugin command. Do not delete an
entire global skills directory because it may contain unrelated packages.
