# Global harness installation

KnowMe Builder `2.0.0-alpha.2` exposes exactly 30 public Agent Skills from the
Git repository URL. The package contains the `hybrid-mobile-architecture`
routing skill and 29 independently installable companion skills.

Repository URL:

```text
https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
```

## Portable Agent Skills installation

Install the same public set into Claude Code, Codex, and OpenCode:

```bash
npx skills add https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill \
  --skill '*' -a claude-code -a codex -a opencode -g -y
```

List without installing:

```bash
npx skills add https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill --list
```

Normal discovery returns 30 skills. The 20 OpenSpec/OPSX repository-authoring
helpers are marked internal and are visible only with
`INSTALL_INTERNAL_SKILLS=1` plus full-depth discovery.

## Native Claude Code marketplace

```bash
claude plugin marketplace add \
  https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
claude plugin install hybrid-mobile-architecture@knowme-builder --scope user
claude plugin list
```

Update or remove:

```bash
claude plugin marketplace update knowme-builder
claude plugin uninstall hybrid-mobile-architecture@knowme-builder --scope user
```

## Native Codex marketplace

```bash
codex plugin marketplace add \
  https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill --ref main
codex plugin add hybrid-mobile-architecture@knowme-builder
codex plugin list
```

Update or remove:

```bash
codex plugin marketplace upgrade knowme-builder
codex plugin remove hybrid-mobile-architecture@knowme-builder
```

## OpenCode

OpenCode has no native Git marketplace. It discovers Agent Skills through its
standard skill directories and loads JavaScript/TypeScript plugins from
`.opencode/plugins` or `~/.config/opencode/plugins`.

The portable command above installs its 30 skills. The repository installer
also installs the dependency-free advisory plugin and namespaced commands:

```bash
git clone https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
cd hybrid-mobile-architecture-skill
bash scripts/install-harness-package.sh --harness opencode \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
opencode debug skill
```

Update and safely uninstall the receipt-owned OpenCode payload:

```bash
git pull --ff-only
bash scripts/install-harness-package.sh --harness opencode \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
bash scripts/install-harness-package.sh --harness opencode --uninstall
```

## Unified receipt-based installer

From a trusted checkout:

```bash
bash scripts/install-harness-package.sh \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
```

The compatibility entry point remains:

```bash
bash scripts/install-global-harnesses.sh
```

Options:

```text
--harness claude-code|codex|opencode|all
--scope user|project
--source <git-url-or-path>
--ref <git-ref>
--check
--uninstall
--with-cli
--with-mcp
--with-prometheus
```

The default installs skills, native marketplace registrations, commands, and
advisory adapters. It does not compile the CLI, mutate MCP configuration, or
bootstrap Prometheus unless the corresponding explicit flag is present.

User-scope ownership is recorded under
`${XDG_STATE_HOME:-$HOME/.local/state}/knowme-builder/install.json`. Project
scope uses `.knowme-builder/harness-install.json`. Uninstall removes only
receipt-owned paths and marketplace registrations.

For an all-harness install, the exact check, update, and uninstall lifecycle is:

```bash
bash scripts/install-harness-package.sh --check \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
git pull --ff-only
bash scripts/install-harness-package.sh \
  --source https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill
bash scripts/install-harness-package.sh --uninstall
```

Codex native plugins are user-scoped. For `--scope project`, the installer uses
portable Codex skills and project prompt files instead of claiming unsupported
native plugin scope.

## Builder CLI and project projection

CLI installation is optional:

```bash
bash scripts/install-harness-package.sh --with-cli
knowme-builder --version
```

Generated or adopted applications receive only the 29 companion skills:

```bash
knowme-builder skills install --path <project>
knowme-builder skills check --path <project>
```

## Prometheus compatibility

Prometheus remains external. KnowMe Builder requires:

- package `1.7.0` or newer;
- control-plane contract `2.0.0` or newer; and
- current typed KBD, CRDT claim/conflict, immutable plugin-generation, and
  durable learning capabilities.

The canonical source and runbooks are:

- <https://github.com/Prometheus-AGS/prometheus-skill-system>
- <https://github.com/Prometheus-AGS/prometheus-skill-system/blob/main/docs/guide/19-installation.md>
- <https://github.com/Prometheus-AGS/prometheus-skill-system/blob/main/docs/guide/20-updating.md>

Use `--with-prometheus` only when the long, host-mutating bootstrap is intended.

## Verification

```bash
node scripts/check-skill-contracts.mjs
node scripts/sync-skill-resources.mjs --check
bash scripts/sync-harness-skills.sh --check
bash scripts/check-git-url-discovery.sh
bash scripts/test-harness-installer.sh
node scripts/test-opencode-plugin.mjs
knowme-builder --json doctor --path .
```

Restart active harness sessions after changing plugin or skill payloads.
