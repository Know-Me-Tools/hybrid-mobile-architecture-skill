#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/knowme-installer-test.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

mock_bin="$test_root/bin"
test_home="$test_root/home"
mock_state="$test_root/mock-state"
mock_log="$test_root/commands.log"
mkdir -p "$mock_bin" "$test_home" "$mock_state"

install -m 0755 "$repo_root/scripts/test-fixtures/harness-installer/npx" "$mock_bin/npx"
install -m 0755 "$repo_root/scripts/test-fixtures/harness-installer/claude" "$mock_bin/claude"
install -m 0755 "$repo_root/scripts/test-fixtures/harness-installer/codex" "$mock_bin/codex"
export PATH="$mock_bin:$PATH"
export HOME="$test_home"
export XDG_CONFIG_HOME="$test_home/.config"
export XDG_STATE_HOME="$test_home/.local/state"
export KNOWME_TEST_LOG="$mock_log"
export KNOWME_TEST_STATE="$mock_state"

installer=(bash "$repo_root/scripts/install-harness-package.sh" --source "$repo_root")
"${installer[@]}"

receipt="$XDG_STATE_HOME/knowme-builder/install.json"
plugin="$XDG_CONFIG_HOME/opencode/plugins/knowme-builder.mjs"
activation="$XDG_CONFIG_HOME/opencode/knowme-builder/activation-manifest.json"
[[ -f "$receipt" && -f "$plugin" && -f "$activation" ]]
jq -e '.version == "2.0.0-alpha.2" and (.harnesses | length == 3)' "$receipt" >/dev/null

unrelated="$XDG_CONFIG_HOME/opencode/plugins/unrelated.mjs"
touch "$unrelated"
"${installer[@]}"
grep -Fq 'claude plugin marketplace update knowme-builder' "$mock_log"
grep -Fq 'codex plugin marketplace upgrade knowme-builder' "$mock_log"
jq -e '.marketplacesAdded.claude == true and .marketplacesAdded.codex == true' "$receipt" >/dev/null

"${installer[@]}" --harness opencode
jq -e '(.harnesses | sort) == ["claude-code", "codex", "opencode"]' "$receipt" >/dev/null

"${installer[@]}" --uninstall
[[ ! -e "$receipt" && ! -e "$plugin" && ! -e "$activation" ]]
[[ -f "$unrelated" ]]
[[ ! -e "$mock_state/claude-marketplace" && ! -e "$mock_state/codex-marketplace" ]]

check_home="$test_root/check-home"
HOME="$check_home" XDG_CONFIG_HOME="$check_home/.config" XDG_STATE_HOME="$check_home/.state" \
  "${installer[@]}" --harness opencode --check >/dev/null
[[ ! -e "$check_home" ]]

echo "Harness installer idempotence and ownership tests passed."
