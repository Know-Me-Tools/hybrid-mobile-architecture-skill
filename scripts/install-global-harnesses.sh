#!/usr/bin/env bash
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

for command_name in rsync jq node; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "missing required command: $command_name" >&2
    exit 1
  }
done

# Every harness that reads a global skills directory. This list was missing
# .claude, .codex, and .opencode — the three most-used ones on a typical
# workstation — so running this script left Claude Code itself without the
# pack's skills while reporting success. A harness absent from this list is a
# harness that silently never updates.
#
# ~/.config/opencode and ~/.opencode are BOTH listed on purpose: opencode has
# used each location across versions, and syncing both costs nothing while
# missing the live one costs everything.
skill_roots=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.kimi/skills"
  "$HOME/.opencode/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.kimi-code/skills"
  "$HOME/.agents/skills"
)

project_skills=()
while IFS= read -r skill_dir; do
  project_skills+=("$skill_dir")
done < <(
  find "$repo_root/templates/project-skills" -mindepth 1 -maxdepth 1 -type d \
    ! -name hooks -exec test -f '{}/SKILL.md' ';' -print | sort
)

sync_skill() {
  local source_dir="$1"
  local destination_dir="$2"
  mkdir -p "$destination_dir"
  rsync -a --delete "$source_dir/" "$destination_dir/"
}

install_matching_files() {
  local source_dir="$1"
  local destination_dir="$2"
  local pattern="$3"
  local source_file

  mkdir -p "$destination_dir"
  while IFS= read -r source_file; do
    install -m 0644 "$source_file" "$destination_dir/$(basename "$source_file")"
  done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type f -name "$pattern" | sort)
}

install_main_skill() {
  local skill_root="$1"
  local destination="$skill_root/hybrid-mobile-architecture"
  mkdir -p "$destination"
  rsync -a --delete \
    --exclude '.git/' \
    --exclude '.prometheus/' \
    --exclude '.agents/' \
    --exclude '.claude/' \
    --exclude '.codex/' \
    --exclude '.kimi/' \
    --exclude '.kimi-code/' \
    --exclude '.opencode/' \
    --exclude 'node_modules/' \
    --exclude 'target/' \
    --exclude 'build/' \
    --exclude 'dist/' \
    --exclude 'apps/' \
    --exclude 'site/' \
    "$repo_root/" "$destination/"
}

install_plugin_payload() {
  local destination="$1"
  mkdir -p "$destination"
  rsync -a --delete \
    --exclude '.git/' \
    --exclude '.prometheus/' \
    --exclude 'node_modules/' \
    --exclude 'target/' \
    --exclude 'build/' \
    --exclude 'dist/' \
    --exclude 'apps/' \
    --exclude 'site/' \
    "$repo_root/" "$destination/"
}

for skill_root in "${skill_roots[@]}"; do
  mkdir -p "$skill_root"
  install_main_skill "$skill_root"
  install -m 0644 "$repo_root/AGENT_BASE_RULES.md" "$(dirname "$skill_root")/AGENT_BASE_RULES.md"

  for source_dir in "${project_skills[@]}"; do
    skill_name="$(basename "$source_dir")"
    sync_skill "$source_dir" "$skill_root/$skill_name"
  done

done

# Commands and activation adapters are installed into harness-native discovery
# locations. Shared directories are updated file-by-file so unrelated user
# commands and hooks are never deleted.
sync_skill \
  "$repo_root/.claude/commands/knowme-builder" \
  "$HOME/.claude/commands/knowme-builder"
install_matching_files \
  "$repo_root/.codex/prompts" \
  "$HOME/.codex/prompts" \
  'knowme-builder-*.md'
install_matching_files \
  "$repo_root/.opencode/commands" \
  "$HOME/.opencode/commands" \
  'knowme-builder-*.md'
install_matching_files \
  "$repo_root/.opencode/commands" \
  "$HOME/.config/opencode/commands" \
  'knowme-builder-*.md'
install_matching_files \
  "$repo_root/.kimi-code/commands" \
  "$HOME/.kimi-code/commands" \
  'knowme-builder-*.md'

mkdir -p "$HOME/.claude/hooks" "$HOME/.opencode/hooks" "$HOME/.kimi-code/hooks"
install -m 0755 \
  "$repo_root/.claude/hooks/skill-activation.py" \
  "$HOME/.claude/hooks/knowme-builder-skill-activation.py"
install -m 0644 \
  "$repo_root/.opencode/hooks/skill-activation.mjs" \
  "$HOME/.opencode/hooks/knowme-builder-skill-activation.mjs"
install -m 0755 \
  "$repo_root/.kimi-code/hooks/skill-activation.py" \
  "$HOME/.kimi-code/hooks/knowme-builder-skill-activation.py"

# Install relocatable marketplace/plugin payloads without mutating a harness's
# private registry. Claude Code can register the local marketplace using its
# native CLI, while Codex discovers the versioned cache payload directly.
builder_version="$(jq -r '.package.version' "$repo_root/builder.manifest.json")"
claude_marketplace="$HOME/.claude/plugins/marketplaces/knowme-hybrid-architecture"
codex_plugin_cache="$HOME/.codex/plugins/cache/knowme-hybrid-architecture/hybrid-mobile-architecture/$builder_version"
install_plugin_payload "$claude_marketplace"
install_plugin_payload "$codex_plugin_cache"

add_claude_mcp() {
  local name="$1"
  shift
  local details
  details="$(claude mcp get "$name" 2>/dev/null || true)"
  if ! grep -q 'Scope: User' <<<"$details"; then
    claude mcp add --scope user "$name" -- "$@"
  fi
}

add_codex_mcp() {
  local name="$1"
  shift
  if ! grep -Fqx "[mcp_servers.$name]" "$HOME/.codex/config.toml" 2>/dev/null; then
    codex mcp add "$name" -- "$@"
  fi
}

if command -v claude >/dev/null 2>&1; then
  add_claude_mcp dart dart mcp-server --force-roots-fallback
  add_claude_mcp shadcn npx shadcn@latest mcp
fi

if command -v codex >/dev/null 2>&1; then
  add_codex_mcp dart dart mcp-server --force-roots-fallback
  add_codex_mcp shadcn npx shadcn@latest mcp
fi

opencode_config="$HOME/.config/opencode/opencode.json"
if [[ -f "$opencode_config" ]]; then
  opencode_tmp="$(mktemp "${TMPDIR:-/tmp}/harness-opencode.XXXXXX")"
  jq '
    .mcp = (.mcp // {}) |
    .mcp["dart-mcp-server"] //= {
      type: "local", command: ["dart", "mcp-server", "--force-roots-fallback"], enabled: true
    } |
    .mcp.shadcn //= {
      type: "local", command: ["npx", "shadcn@latest", "mcp"], enabled: true
    }
  ' "$opencode_config" > "$opencode_tmp"
  chmod --reference="$opencode_config" "$opencode_tmp" 2>/dev/null || chmod 600 "$opencode_tmp"
  mv "$opencode_tmp" "$opencode_config"
fi

kimi_mcp="$HOME/.kimi-code/mcp.json"
mkdir -p "$(dirname "$kimi_mcp")"
kimi_tmp="$(mktemp "${TMPDIR:-/tmp}/harness-kimi.XXXXXX")"
if [[ -f "$kimi_mcp" ]]; then
  jq '
    .mcpServers = (.mcpServers // {}) |
    .mcpServers.dart //= {command: "dart", args: ["mcp-server", "--force-roots-fallback"]} |
    .mcpServers.shadcn //= {command: "npx", args: ["shadcn@latest", "mcp"]}
  ' "$kimi_mcp" > "$kimi_tmp"
else
  jq -n '{mcpServers: {
    dart: {command: "dart", args: ["mcp-server", "--force-roots-fallback"]},
    shadcn: {command: "npx", args: ["shadcn@latest", "mcp"]}
  }}' > "$kimi_tmp"
fi
chmod 600 "$kimi_tmp"
mv "$kimi_tmp" "$kimi_mcp"

zed_settings="$HOME/.config/zed/settings.json"
mkdir -p "$(dirname "$zed_settings")"
node "$repo_root/scripts/merge-zed-context-servers.mjs" "$zed_settings"

echo "Installed hybrid-mobile-architecture and ${#project_skills[@]} companion skills for filesystem-based harness discovery."
printf '  %s\n' "${skill_roots[@]}"
echo "Installed namespaced commands and advisory activation adapters for Claude Code, Codex, OpenCode, and Kimi Code CLI."
echo "Installed Claude marketplace payload at $claude_marketplace"
echo "Installed Codex plugin payload at $codex_plugin_cache"
echo "Configured Dart and shadcn MCP servers for Claude Code, Codex, OpenCode, Kimi Code CLI, and Zed."
