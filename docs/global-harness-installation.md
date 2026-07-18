# Global harness installation

The repository is both an Agent Skills package and a collection of reusable companion
skills. Use the checked-in installer to make the architecture skill, scaffold utilities,
and companion workflows available outside this repository:

```bash
bash scripts/install-global-harnesses.sh
```

The installer is idempotent. It updates only the skill names owned by this repository,
preserves unrelated skills and configuration, and adds the Dart and shadcn MCP servers
only when a same-named entry does not already exist.

## Installed locations

| Harness | Global skills | MCP configuration |
|---|---|---|
| Claude Code | `hybrid-mobile-architecture@knowme-hybrid-architecture` plugin | Claude Code user scope |
| OpenCode | `~/.config/opencode/skills` | `~/.config/opencode/opencode.json` |
| Codex | `hybrid-mobile-architecture@knowme-hybrid-architecture` plugin | `~/.codex/config.toml` |
| Kimi Code CLI | `~/.kimi-code/skills` | `~/.kimi-code/mcp.json` |
| Zed | `~/.agents/skills` | `~/.config/zed/settings.json` |

Zed and Kimi also discover the shared `~/.agents/skills` directory. Separate native
copies are retained for deterministic harness behavior and for tools that do not scan the
shared directory.

## Claude Code marketplace

This repository contains a current `.claude-plugin/plugin.json` and
`.claude-plugin/marketplace.json`. Initialize and install it with:

```bash
claude plugin validate .claude-plugin/plugin.json
claude plugin marketplace add Know-Me-Tools/hybrid-mobile-architecture-skill --scope user
claude plugin install hybrid-mobile-architecture@knowme-hybrid-architecture --scope user
```

## Codex marketplace

The Codex marketplace manifest is `.agents/plugins/marketplace.json`:

```bash
codex plugin marketplace add Know-Me-Tools/hybrid-mobile-architecture-skill
codex plugin add hybrid-mobile-architecture@knowme-hybrid-architecture
```

## Verification

```bash
claude plugin list
claude mcp list
codex plugin list
codex mcp list
opencode debug skill
opencode mcp list
kimi doctor config
```

In Zed, open **Settings → AI → Skills** and **Settings → AI → MCP Servers**. The
architecture and companion skills should be listed, and the Dart and shadcn server status
indicators should become active when their commands are available.

Restart already-running harness sessions after installation so their skill catalogs and
plugin snapshots are rebuilt.

Use the GitHub marketplace source for normal installation. A local working-tree source
may contain ignored compiler caches and application builds that are intentionally absent
from Git and can make plugin snapshotting unnecessarily slow.
