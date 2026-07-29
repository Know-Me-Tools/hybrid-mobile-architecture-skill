# Global harness installation

KnowMe Builder distributes one canonical instruction package to Claude Code,
Codex, OpenCode, Kimi Code CLI, and generic Agent Skills discovery roots. The
same installer also deploys native commands, advisory activation adapters,
plugin payloads, and supported development MCP entries.

For the public walkthrough, see the
[Docusaurus installation guide](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/reference/installation).

## Install the CLI

```bash
cargo build --release --locked --manifest-path tools/knowme-builder/Cargo.toml
install -m 0755 tools/knowme-builder/target/release/knowme-builder \
  "$HOME/.cargo/bin/knowme-builder"
knowme-builder --version
```

## Run the idempotent installer

```bash
bash scripts/install-global-harnesses.sh
```

The installer:

- discovers all 29 skills from `templates/project-skills`;
- installs the root `hybrid-mobile-architecture` skill;
- mirrors each companion skill into seven global discovery roots;
- installs eight namespaced Builder command wrappers for each supported
  harness command surface;
- installs Claude, OpenCode, and Kimi advisory activation adapters;
- builds relocatable local plugin payloads for Claude and Codex;
- adds Dart and shadcn MCP entries without replacing same-named user entries;
  and
- preserves unrelated skills, hooks, commands, plugins, and configuration.

## Installed locations

| Harness | Skill roots | Command/advisory surface |
|---|---|---|
| Claude Code | `~/.claude/skills` | `~/.claude/commands/knowme-builder`, hook adapter |
| Codex | `~/.codex/skills` | `~/.codex/prompts`, native skill descriptions |
| OpenCode | `~/.opencode/skills`, `~/.config/opencode/skills` | both command roots, plugin prompt adapter |
| Kimi Code CLI | `~/.kimi-code/skills`, `~/.kimi/skills` | `~/.kimi-code/commands`, prompt hook |
| Generic Agent Skills | `~/.agents/skills` | discovery only |

Zed is an auxiliary MCP/context-server integration, not one of the four
Builder lifecycle adapters.

## Native plugin registration

The installer copies a marketplace payload to:

- `~/.claude/plugins/marketplaces/knowme-hybrid-architecture`; and
- `~/.codex/plugins/cache/knowme-hybrid-architecture`.

Register the local source and install the plugin with the marketplace name
reported by the native CLI.

Claude:

```bash
claude plugin marketplace add "$HOME/.claude/plugins/marketplaces/knowme-hybrid-architecture"
claude plugin marketplace list
claude plugin install hybrid-mobile-architecture@knowme-builder --scope user
claude plugin list
```

Codex:

```bash
codex plugin marketplace add "$HOME/.codex/plugins/cache/knowme-hybrid-architecture"
codex plugin marketplace list
codex plugin add hybrid-mobile-architecture@knowme-builder
codex plugin list
```

If the marketplace was assigned a different name, substitute that name after
the `@`.

## Project installation

Global discovery is not a substitute for a pinned application payload:

```bash
knowme-builder skills install --path <project>
knowme-builder skills check --path <project>
```

The project receives six skill trees and a digest-pinned `skills-lock.json`.
Conflicting existing skills are preserved and reported.

## MCP verification

```bash
claude mcp list
codex mcp list
opencode mcp list
kimi doctor config
```

The Dart MCP supports Flutter launch, hot reload, widget inspection, and
analysis. The shadcn MCP assists supported component sourcing. Neither service
owns application architecture or acceptance.

## Payload verification

At minimum:

```bash
knowme-builder manifest check
bash scripts/sync-harness-skills.sh --check
knowme-builder --json doctor --path .
```

Verify that every installed helper under a skill `scripts` directory remains
executable. Restart active harness sessions so they rebuild their skill and
command indexes.

## Upgrades and cache refresh

Rerun the installer after every Builder upgrade. Native plugin systems may
cache a payload by version, so remove and reinstall the same-version plugin
when testing a corrected prerelease payload.

Project upgrades remain ownership-aware:

```bash
knowme-builder upgrade <project> --check
knowme-builder upgrade <project> --apply
```

Do not refresh consumer applications by copying repository harness directories
over them.
