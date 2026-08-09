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

[[ "$normal_count" == "30" ]] || {
  sed -n '1,40p' "$normal_output" >&2
  echo "expected 30 public skills, found ${normal_count:-none}" >&2
  exit 1
}
[[ "$internal_count" == "50" ]] || {
  sed -n '1,40p' "$internal_output" >&2
  echo "expected 50 skills with internal discovery, found ${internal_count:-none}" >&2
  exit 1
}

echo "Git URL discovery exposes 30 public and 20 opt-in internal skills."
