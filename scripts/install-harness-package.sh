#!/usr/bin/env bash
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
manifest="$repo_root/builder.manifest.json"

harness="all"
scope="user"
source_value=""
git_ref=""
check_only=false
uninstall=false
with_cli=false
with_mcp=false
with_prometheus=false

usage() {
  cat <<'USAGE'
Install the KnowMe Builder harness package from a Git repository URL or checkout.

Usage:
  bash scripts/install-harness-package.sh [options]

Options:
  --harness <claude-code|codex|opencode|all>  Harness target (default: all)
  --scope <user|project>                       Installation scope (default: user)
  --source <git-url-or-path>                   Marketplace/skill source
  --ref <git-ref>                              Optional Git ref (Codex and owner/repo sources)
  --check                                      Print and validate without changing host state
  --uninstall                                  Remove receipt-owned installation surfaces
  --with-cli                                   Build and install knowme-builder
  --with-mcp                                   Configure Dart and shadcn MCP entries
  --with-prometheus                            Run the explicit full Prometheus bootstrap
  -h, --help                                   Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --harness) harness="${2:?missing value for --harness}"; shift 2 ;;
    --scope) scope="${2:?missing value for --scope}"; shift 2 ;;
    --source) source_value="${2:?missing value for --source}"; shift 2 ;;
    --ref) git_ref="${2:?missing value for --ref}"; shift 2 ;;
    --check) check_only=true; shift ;;
    --uninstall) uninstall=true; shift ;;
    --with-cli) with_cli=true; shift ;;
    --with-mcp) with_mcp=true; shift ;;
    --with-prometheus) with_prometheus=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$harness" in claude-code|codex|opencode|all) ;; *) echo "invalid harness: $harness" >&2; exit 2 ;; esac
case "$scope" in user|project) ;; *) echo "invalid scope: $scope" >&2; exit 2 ;; esac

for command_name in git jq node npx; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "missing required command: $command_name" >&2
    exit 1
  }
done

package_id="$(jq -r '.package.id' "$manifest")"
package_version="$(jq -r '.package.version' "$manifest")"
marketplace_name="knowme-builder"

if [[ -z "$source_value" ]]; then
  source_value="$(git -C "$repo_root" remote get-url origin 2>/dev/null || true)"
  [[ -n "$source_value" ]] || source_value="$repo_root"
fi

if [[ "$scope" == "user" ]]; then
  state_root="${XDG_STATE_HOME:-$HOME/.local/state}/knowme-builder"
  opencode_root="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  receipt="$state_root/install.json"
  skills_scope=(-g)
else
  state_root="$PWD/.knowme-builder"
  opencode_root="$PWD/.opencode"
  receipt="$state_root/harness-install.json"
  skills_scope=()
fi

selected_harnesses=()
if [[ "$harness" == "all" ]]; then
  selected_harnesses=(claude-code codex opencode)
else
  selected_harnesses=("$harness")
fi

has_harness() {
  local expected="$1"
  local item
  for item in "${selected_harnesses[@]}"; do
    [[ "$item" == "$expected" ]] && return 0
  done
  return 1
}

print_command() {
  printf '  '
  printf '%q ' "$@"
  printf '\n'
}

run() {
  if $check_only; then
    print_command "$@"
  else
    "$@"
  fi
}

portable_source="$source_value"
if [[ -n "$git_ref" && "$source_value" =~ ^[^/:]+/[^/]+$ ]]; then
  portable_source="${source_value}@${git_ref}"
fi

open_code_plugin="$opencode_root/plugins/knowme-builder.mjs"
open_code_manifest="$opencode_root/knowme-builder/activation-manifest.json"
open_code_config="$opencode_root/opencode.json"
open_code_commands=()
while IFS= read -r command_file; do
  open_code_commands+=("$opencode_root/commands/$(basename "$command_file")")
done < <(find "$repo_root/.opencode/commands" -maxdepth 1 -type f -name 'knowme-builder-*.md' | sort)

receipt_has() {
  local name="$1"
  [[ -f "$receipt" ]] && jq -e --arg name "$name" '.harnesses | index($name) != null' "$receipt" >/dev/null
}

remove_exact_path() {
  local path="$1"
  if $check_only; then
    print_command rm -f "$path"
  elif [[ -f "$path" || -L "$path" ]]; then
    rm -f "$path"
  fi
}

if $uninstall; then
  [[ -f "$receipt" ]] || { echo "no KnowMe Builder install receipt: $receipt" >&2; exit 1; }
  if receipt_has claude-code && jq -e '.pluginsAdded.claude == true' "$receipt" >/dev/null && command -v claude >/dev/null 2>&1; then
    run claude plugin uninstall "$package_id@$marketplace_name" --scope "$scope"
    if jq -e '.marketplacesAdded.claude == true' "$receipt" >/dev/null; then
      run claude plugin marketplace remove "$marketplace_name"
    fi
  fi
  if receipt_has codex && [[ "$scope" == "user" ]] && jq -e '.pluginsAdded.codex == true' "$receipt" >/dev/null && command -v codex >/dev/null 2>&1; then
    run codex plugin remove "$package_id@$marketplace_name"
    if jq -e '.marketplacesAdded.codex == true' "$receipt" >/dev/null; then
      run codex plugin marketplace remove "$marketplace_name"
    fi
  fi
  if receipt_has opencode; then
    public_skills=()
    while IFS= read -r skill_name; do public_skills+=("$skill_name"); done < <(
      jq -r '[.distribution.packageSkill] + .skills | .[]' "$manifest"
    )
    if jq -e '.skillsAdded.opencode == true' "$receipt" >/dev/null; then
      run npx -y skills@latest remove "${public_skills[@]}" "${skills_scope[@]}" -a opencode -y
    fi
    remove_exact_path "$open_code_plugin"
    remove_exact_path "$open_code_manifest"
    for command_path in "${open_code_commands[@]}"; do remove_exact_path "$command_path"; done
  fi
  if jq -e '.mcpAdded.claude.dart == true' "$receipt" >/dev/null && command -v claude >/dev/null 2>&1; then
    run claude mcp remove --scope "$scope" dart
  fi
  if jq -e '.mcpAdded.claude.shadcn == true' "$receipt" >/dev/null && command -v claude >/dev/null 2>&1; then
    run claude mcp remove --scope "$scope" shadcn
  fi
  if jq -e '.mcpAdded.codex.dart == true' "$receipt" >/dev/null && command -v codex >/dev/null 2>&1; then
    run codex mcp remove dart
  fi
  if jq -e '.mcpAdded.codex.shadcn == true' "$receipt" >/dev/null && command -v codex >/dev/null 2>&1; then
    run codex mcp remove shadcn
  fi
  if jq -e '(.mcpAdded.opencode.dart == true) or (.mcpAdded.opencode.shadcn == true)' "$receipt" >/dev/null && [[ -f "$open_code_config" ]]; then
    if $check_only; then
      echo "  remove receipt-owned MCP entries from $open_code_config"
    else
      temporary_config="$(mktemp "${TMPDIR:-/tmp}/knowme-opencode.XXXXXX")"
      jq \
        --argjson remove_dart "$(jq '.mcpAdded.opencode.dart // false' "$receipt")" \
        --argjson remove_shadcn "$(jq '.mcpAdded.opencode.shadcn // false' "$receipt")" \
        'if $remove_dart then del(.mcp["dart-mcp-server"]) else . end |
         if $remove_shadcn then del(.mcp.shadcn) else . end' \
        "$open_code_config" > "$temporary_config"
      chmod 600 "$temporary_config"
      mv "$temporary_config" "$open_code_config"
    fi
  fi
  if receipt_has codex && [[ "$scope" == "project" ]]; then
    public_skills=()
    while IFS= read -r skill_name; do public_skills+=("$skill_name"); done < <(
      jq -r '[.distribution.packageSkill] + .skills | .[]' "$manifest"
    )
    if jq -e '.skillsAdded.codexProject == true' "$receipt" >/dev/null; then
      run npx -y skills@latest remove "${public_skills[@]}" -a codex -y
    fi
    for prompt in "$repo_root"/.codex/prompts/knowme-builder-*.md; do
      remove_exact_path "$PWD/.codex/prompts/$(basename "$prompt")"
    done
  fi
  if $check_only; then
    print_command rm -f "$receipt"
  else
    rm -f "$receipt"
  fi
  echo "KnowMe Builder uninstall complete for receipt: $receipt"
  exit 0
fi

claude_marketplace_added=false
codex_marketplace_added=false
claude_plugin_added=false
codex_plugin_added=false
opencode_skills_added=false
codex_project_skills_added=false
claude_dart_mcp_added=false
claude_shadcn_mcp_added=false
codex_dart_mcp_added=false
codex_shadcn_mcp_added=false
opencode_dart_mcp_added=false
opencode_shadcn_mcp_added=false
if [[ -f "$receipt" ]]; then
  claude_marketplace_added="$(jq -r '.marketplacesAdded.claude // false' "$receipt")"
  codex_marketplace_added="$(jq -r '.marketplacesAdded.codex // false' "$receipt")"
  claude_plugin_added="$(jq -r '.pluginsAdded.claude // false' "$receipt")"
  codex_plugin_added="$(jq -r '.pluginsAdded.codex // false' "$receipt")"
  opencode_skills_added="$(jq -r '.skillsAdded.opencode // false' "$receipt")"
  codex_project_skills_added="$(jq -r '.skillsAdded.codexProject // false' "$receipt")"
  claude_dart_mcp_added="$(jq -r '.mcpAdded.claude.dart // false' "$receipt")"
  claude_shadcn_mcp_added="$(jq -r '.mcpAdded.claude.shadcn // false' "$receipt")"
  codex_dart_mcp_added="$(jq -r '.mcpAdded.codex.dart // false' "$receipt")"
  codex_shadcn_mcp_added="$(jq -r '.mcpAdded.codex.shadcn // false' "$receipt")"
  opencode_dart_mcp_added="$(jq -r '.mcpAdded.opencode.dart // false' "$receipt")"
  opencode_shadcn_mcp_added="$(jq -r '.mcpAdded.opencode.shadcn // false' "$receipt")"
fi

if has_harness claude-code; then
  command -v claude >/dev/null 2>&1 || { echo "claude is required for Claude Code installation" >&2; exit 1; }
  if claude plugin marketplace list 2>/dev/null | grep -Fq "$marketplace_name"; then
    run claude plugin marketplace update "$marketplace_name"
  else
    run claude plugin marketplace add "$source_value" --scope "$scope"
    claude_marketplace_added=true
  fi
  if ! claude plugin list --json 2>/dev/null | jq -e \
    --arg id "$package_id@$marketplace_name" --arg scope "$scope" \
    '.[]? | select(.id == $id and .scope == $scope)' >/dev/null; then
    claude_plugin_added=true
  fi
  run claude plugin install "$package_id@$marketplace_name" --scope "$scope"
fi

if has_harness codex; then
  if [[ "$scope" == "user" ]]; then
    command -v codex >/dev/null 2>&1 || { echo "codex is required for Codex installation" >&2; exit 1; }
    if codex plugin marketplace list --json 2>/dev/null | jq -e --arg name "$marketplace_name" '.marketplaces[]? | select(.name == $name)' >/dev/null; then
      run codex plugin marketplace upgrade "$marketplace_name"
    else
      codex_add=(codex plugin marketplace add "$source_value")
      [[ -n "$git_ref" ]] && codex_add+=(--ref "$git_ref")
      run "${codex_add[@]}"
      codex_marketplace_added=true
    fi
    if ! codex plugin list --json 2>/dev/null | jq -e \
      --arg id "$package_id@$marketplace_name" \
      '.installed[]? | select(.pluginId == $id)' >/dev/null; then
      codex_plugin_added=true
    fi
    run codex plugin add "$package_id@$marketplace_name"
  else
    if [[ ! -e "$PWD/.agents/skills/$package_id" ]]; then
      codex_project_skills_added=true
    fi
    run npx -y skills@latest add "$portable_source" --skill '*' -a codex -y --copy
    mkdir_command=(mkdir -p "$PWD/.codex/prompts")
    run "${mkdir_command[@]}"
    for prompt in "$repo_root"/.codex/prompts/knowme-builder-*.md; do
      run install -m 0644 "$prompt" "$PWD/.codex/prompts/$(basename "$prompt")"
    done
  fi
fi

if has_harness opencode; then
  if [[ "$scope" == "user" ]]; then
    portable_skill_root="$HOME/.agents/skills"
  else
    portable_skill_root="$PWD/.agents/skills"
  fi
  if [[ ! -e "$portable_skill_root/$package_id" ]]; then
    opencode_skills_added=true
  fi
  run npx -y skills@latest add "$portable_source" --skill '*' "${skills_scope[@]}" -a opencode -y --copy
  run mkdir -p "$opencode_root/plugins" "$opencode_root/knowme-builder" "$opencode_root/commands"
  run install -m 0644 "$repo_root/.opencode/plugins/knowme-builder.mjs" "$open_code_plugin"
  run install -m 0644 "$repo_root/templates/activation-manifest.json" "$open_code_manifest"
  for index in "${!open_code_commands[@]}"; do
    source_command="$repo_root/.opencode/commands/$(basename "${open_code_commands[$index]}")"
    run install -m 0644 "$source_command" "${open_code_commands[$index]}"
  done
fi

if $with_cli; then
  cli_root="${CARGO_HOME:-$HOME/.cargo}"
  run cargo build --release --locked \
    --manifest-path "$repo_root/tools/knowme-builder/Cargo.toml" \
    --target-dir "$repo_root/tools/knowme-builder/target"
  run mkdir -p "$cli_root/bin"
  run install -m 0755 "$repo_root/tools/knowme-builder/target/release/knowme-builder" "$cli_root/bin/knowme-builder"
fi

if $with_mcp; then
  if has_harness claude-code; then
    if ! claude mcp get dart >/dev/null 2>&1; then
      run claude mcp add --scope "$scope" dart -- dart mcp-server --force-roots-fallback
      claude_dart_mcp_added=true
    fi
    if ! claude mcp get shadcn >/dev/null 2>&1; then
      run claude mcp add --scope "$scope" shadcn -- npx shadcn@latest mcp
      claude_shadcn_mcp_added=true
    fi
  fi
  if has_harness codex && [[ "$scope" == "user" ]]; then
    if ! codex mcp get dart >/dev/null 2>&1; then
      run codex mcp add dart -- dart mcp-server --force-roots-fallback
      codex_dart_mcp_added=true
    fi
    if ! codex mcp get shadcn >/dev/null 2>&1; then
      run codex mcp add shadcn -- npx shadcn@latest mcp
      codex_shadcn_mcp_added=true
    fi
  fi
  if has_harness opencode; then
    if $check_only; then
      echo "  merge Dart and shadcn MCP entries into $open_code_config"
    else
      mkdir -p "$(dirname "$open_code_config")"
      current_config='{}'
      [[ -f "$open_code_config" ]] && current_config="$(<"$open_code_config")"
      if ! jq -e '.mcp["dart-mcp-server"] != null' <<<"$current_config" >/dev/null; then
        opencode_dart_mcp_added=true
      fi
      if ! jq -e '.mcp.shadcn != null' <<<"$current_config" >/dev/null; then
        opencode_shadcn_mcp_added=true
      fi
      temporary_config="$(mktemp "${TMPDIR:-/tmp}/knowme-opencode.XXXXXX")"
      jq '.mcp = (.mcp // {}) |
          .mcp["dart-mcp-server"] //= {type:"local",command:["dart","mcp-server","--force-roots-fallback"],enabled:true} |
          .mcp.shadcn //= {type:"local",command:["npx","shadcn@latest","mcp"],enabled:true}' \
        <<<"$current_config" > "$temporary_config"
      chmod 600 "$temporary_config"
      mv "$temporary_config" "$open_code_config"
    fi
  fi
fi

if $with_prometheus; then
  run bash "$repo_root/scripts/check-env.sh" --install --full
fi

if $check_only; then
  echo "Check complete; no host state changed."
  exit 0
fi

mkdir -p "$state_root"
selected_harness_json="$(printf '%s\n' "${selected_harnesses[@]}" | jq -R . | jq -s .)"
if [[ -f "$receipt" ]]; then
  harness_json="$(jq --argjson selected "$selected_harness_json" '[(.harnesses + $selected)[]] | unique' "$receipt")"
else
  harness_json="$selected_harness_json"
fi
jq -n \
  --arg package "$package_id" \
  --arg version "$package_version" \
  --arg source "$source_value" \
  --arg ref "$git_ref" \
  --arg scope "$scope" \
  --argjson harnesses "$harness_json" \
  --argjson claude_added "$claude_marketplace_added" \
  --argjson codex_added "$codex_marketplace_added" \
  --argjson claude_plugin_added "$claude_plugin_added" \
  --argjson codex_plugin_added "$codex_plugin_added" \
  --argjson opencode_skills_added "$opencode_skills_added" \
  --argjson codex_project_skills_added "$codex_project_skills_added" \
  --argjson claude_dart_mcp "$claude_dart_mcp_added" \
  --argjson claude_shadcn_mcp "$claude_shadcn_mcp_added" \
  --argjson codex_dart_mcp "$codex_dart_mcp_added" \
  --argjson codex_shadcn_mcp "$codex_shadcn_mcp_added" \
  --argjson opencode_dart_mcp "$opencode_dart_mcp_added" \
  --argjson opencode_shadcn_mcp "$opencode_shadcn_mcp_added" \
  '{schemaVersion:1, package:$package, version:$version, source:$source, ref:$ref,
    scope:$scope, harnesses:$harnesses,
    marketplacesAdded:{claude:$claude_added,codex:$codex_added},
    pluginsAdded:{claude:$claude_plugin_added,codex:$codex_plugin_added},
    skillsAdded:{opencode:$opencode_skills_added,codexProject:$codex_project_skills_added},
    mcpAdded:{
      claude:{dart:$claude_dart_mcp,shadcn:$claude_shadcn_mcp},
      codex:{dart:$codex_dart_mcp,shadcn:$codex_shadcn_mcp},
      opencode:{dart:$opencode_dart_mcp,shadcn:$opencode_shadcn_mcp}
    }}' > "$receipt.tmp"
chmod 600 "$receipt.tmp"
mv "$receipt.tmp" "$receipt"

echo "Installed KnowMe Builder $package_version for: ${selected_harnesses[*]}"
echo "Receipt: $receipt"
