#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
normal_output="$(mktemp "${TMPDIR:-/tmp}/knowme-skills-normal.XXXXXX")"
internal_output="$(mktemp "${TMPDIR:-/tmp}/knowme-skills-internal.XXXXXX")"
trap 'rm -f "$normal_output" "$internal_output"' EXIT

npx -y skills@latest add "$repo_root" --list -a opencode -y > "$normal_output" 2>&1
INSTALL_INTERNAL_SKILLS=1 npx -y skills@latest add "$repo_root" --list --full-depth -a opencode -y > "$internal_output" 2>&1

normal_count="$(tr '\r' '\n' < "$normal_output" | sed -nE 's/.*Found ([0-9]+) skills.*/\1/p' | tail -1)"
internal_count="$(tr '\r' '\n' < "$internal_output" | sed -nE 's/.*Found ([0-9]+) skills.*/\1/p' | tail -1)"

# Expected counts are DERIVED, not hardcoded. Literal counts silently rot as the
# pack grows: this gate sat red on HEAD at "expected 30 public skills, found 36"
# because the pack had added six skills since the literal was written, and the
# failure looked like a discovery bug rather than a stale constant.
#
#   public   = canonical skill directories under skills/
#   internal = the vendored openspec-* / source-command-opsx-* mirrors, counted
#              once from .agents/skills (the shared store every harness derives
#              from) rather than summed across harnesses
expected_public="$(find "$repo_root/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
expected_internal_only="$(find "$repo_root/.agents/skills" -mindepth 1 -maxdepth 1 -type d \
  \( -name 'openspec-*' -o -name 'source-command-opsx-*' \) | wc -l | tr -d ' ')"
expected_total=$((expected_public + expected_internal_only))

[[ "$expected_public" -gt 0 ]] || {
  echo "check-git-url-discovery: derived 0 public skills — refusing to assert a vacuous count" >&2
  exit 1
}
# Guard BOTH sides. With expected_internal_only at 0 the internal assertion
# degenerates to `internal_count == expected_public` and the gate would pass
# green while proving nothing about opt-in internal discovery.
[[ "$expected_internal_only" -gt 0 ]] || {
  echo "check-git-url-discovery: derived 0 internal mirrors — refusing to assert a vacuous count" >&2
  exit 1
}

[[ "$normal_count" == "$expected_public" ]] || {
  sed -n '1,40p' "$normal_output" >&2
  echo "expected $expected_public public skills (from skills/), found ${normal_count:-none}" >&2
  exit 1
}
[[ "$internal_count" == "$expected_total" ]] || {
  sed -n '1,40p' "$internal_output" >&2
  echo "expected $expected_total skills with internal discovery ($expected_public public + $expected_internal_only internal), found ${internal_count:-none}" >&2
  exit 1
}

echo "Git URL discovery exposes $expected_public public and $expected_internal_only opt-in internal skills."
