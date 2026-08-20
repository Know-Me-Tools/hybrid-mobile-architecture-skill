#!/usr/bin/env bash
# scripts/verify-skill-manifest.sh
# Verify the 4-condition install contract that makes this repository
# installable as a connected skill package.
#
# Usage:
#   bash scripts/verify-skill-manifest.sh [package-root]   # default: repo root
#
# Exit 0 when all four conditions hold; exit 1 naming every violation.
# Consumers (the Prometheus Companion's validate/doctor path) run this
# before registering the package with a harness.
#
# The four conditions (see skills/connected-skill-packages/SKILL.md):
#   1. the marketplace manifest parses and declares name, version, plugins[]
#   2. plugin.json parses, declares name + version, and agrees on version
#   3. every skill in the canonical registry resolves to skills/<name>/SKILL.md
#      whose frontmatter name equals its directory name
#   4. install is idempotent: no absolute paths outside the package root and
#      no writes to a fixed global location baked into the manifests

set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ ! -d "$ROOT" ]; then
  echo "verify-skill-manifest: not a directory: $ROOT" >&2
  exit 1
fi

VIOLATIONS=0

violation() {
  printf 'verify-skill-manifest: %s\n' "$1" >&2
  VIOLATIONS=$((VIOLATIONS + 1))
}

# json_get <file> <python-expression-over-d>
# Prints the value or nothing; never aborts the script on malformed JSON.
json_get() {
  python3 -c '
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
try:
    v = eval(sys.argv[2], {"d": d})
except Exception:
    sys.exit(1)
if v is None:
    sys.exit(1)
print(v)
' "$1" "$2" 2>/dev/null || true
}

json_parses() {
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" >/dev/null 2>&1
}

# ── Condition 1: the marketplace manifest ───────────────────────────────────
# The harness-facing marketplace manifest lives at .claude-plugin/marketplace.json
# (the Claude Code convention). The root marketplace.json is this package's
# registry descriptor and carries a different shape; both are checked.
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
ROOT_DESCRIPTOR="$ROOT/marketplace.json"
MARKET_VERSION=""
if [ ! -f "$MARKETPLACE" ]; then
  violation "C1: missing .claude-plugin/marketplace.json"
elif ! json_parses "$MARKETPLACE"; then
  violation "C1: .claude-plugin/marketplace.json is not valid JSON"
else
  for field in name version; do
    if [ -z "$(json_get "$MARKETPLACE" "d.get('$field')")" ]; then
      violation "C1: .claude-plugin/marketplace.json missing required field: $field"
    fi
  done
  if [ "$(json_get "$MARKETPLACE" "len(d.get('plugins') or [])")" != "0" ] \
     && [ -n "$(json_get "$MARKETPLACE" "len(d.get('plugins') or [])")" ]; then
    :
  else
    violation "C1: .claude-plugin/marketplace.json declares no plugins[]"
  fi
  MARKET_VERSION="$(json_get "$MARKETPLACE" "d.get('version')")"
fi

if [ -f "$ROOT_DESCRIPTOR" ]; then
  if ! json_parses "$ROOT_DESCRIPTOR"; then
    violation "C1: marketplace.json is not valid JSON"
  else
    DESCRIPTOR_VERSION="$(json_get "$ROOT_DESCRIPTOR" "d.get('skill',{}).get('version') or d.get('version')")"
    if [ -n "$MARKET_VERSION" ] && [ -n "$DESCRIPTOR_VERSION" ] \
       && [ "$MARKET_VERSION" != "$DESCRIPTOR_VERSION" ]; then
      violation "C1: version disagreement: .claude-plugin/marketplace.json=$MARKET_VERSION marketplace.json=$DESCRIPTOR_VERSION"
    fi
  fi
fi

# ── Condition 2: plugin.json ────────────────────────────────────────────────
PLUGIN="$ROOT/plugin.json"
if [ ! -f "$PLUGIN" ]; then
  violation "C2: missing plugin.json at package root"
elif ! json_parses "$PLUGIN"; then
  violation "C2: plugin.json is not valid JSON"
else
  for field in name version; do
    if [ -z "$(json_get "$PLUGIN" "d.get('$field')")" ]; then
      violation "C2: plugin.json missing required field: $field"
    fi
  done
  PLUGIN_VERSION="$(json_get "$PLUGIN" "d.get('version')")"
  if [ -n "$MARKET_VERSION" ] && [ -n "$PLUGIN_VERSION" ] \
     && [ "$MARKET_VERSION" != "$PLUGIN_VERSION" ]; then
    violation "C2: version disagreement: marketplace.json=$MARKET_VERSION plugin.json=$PLUGIN_VERSION"
  fi
fi

# ── Condition 3: every declared skill resolves ──────────────────────────────
# The canonical registry is builder.manifest.json .skills[] plus the
# package-level distribution.packageSkill.
MANIFEST="$ROOT/builder.manifest.json"
if [ ! -f "$MANIFEST" ]; then
  violation "C3: missing builder.manifest.json (the canonical skill registry)"
elif ! json_parses "$MANIFEST"; then
  violation "C3: builder.manifest.json is not valid JSON"
else
  SKILL_ROOT="$(json_get "$MANIFEST" "d['distribution']['skillSourceRoot']")"
  SKILL_ROOT="${SKILL_ROOT:-skills}"

  DECLARED="$(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
names = [d["distribution"]["packageSkill"], *d["skills"]]
print("\n".join(names))
' "$MANIFEST")"

  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    skill_md="$ROOT/$SKILL_ROOT/$skill/SKILL.md"
    if [ ! -f "$skill_md" ]; then
      violation "C3: declared skill has no SKILL.md: $SKILL_ROOT/$skill/SKILL.md"
      continue
    fi
    # Frontmatter name must equal the directory name.
    fm_name="$(python3 -c '
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
if not m:
    sys.exit(1)
n = re.search(r"^name:\s*(.+)$", m.group(1), re.M)
if not n:
    sys.exit(1)
print(n.group(1).strip())
' "$skill_md" 2>/dev/null || true)"
    if [ -z "$fm_name" ]; then
      violation "C3: $skill: SKILL.md has no parseable frontmatter name"
    elif [ "$fm_name" != "$skill" ]; then
      violation "C3: $skill: frontmatter name '$fm_name' does not match directory"
    fi
  done <<EOF_SKILLS
$DECLARED
EOF_SKILLS

  # Every skill directory on disk must be declared: an undeclared directory
  # ships to nobody and is invisible to the consumer.
  if [ -d "$ROOT/$SKILL_ROOT" ]; then
    for dir in "$ROOT/$SKILL_ROOT"/*/; do
      [ -d "$dir" ] || continue
      name="$(basename "$dir")"
      if ! printf '%s\n' "$DECLARED" | grep -qx "$name"; then
        violation "C3: skill directory not declared in the registry: $name"
      fi
    done
  fi
fi

# ── Condition 4: idempotent install ─────────────────────────────────────────
# Structural precondition: nothing in the shipped manifests may pin an
# absolute path or a home-relative location outside the package root. Such a
# pin makes a second install write outside the install path, which is the
# failure mode this condition exists to exclude.
for manifest in "$MARKETPLACE" "$ROOT_DESCRIPTOR" "$PLUGIN" "$MANIFEST"; do
  [ -f "$manifest" ] || continue
  if grep -Eq '"(/(Users|home|opt|usr|var)/|~/)' "$manifest"; then
    violation "C4: $(basename "$manifest") pins an absolute or home-relative install path"
  fi
done

if [ "$VIOLATIONS" -ne 0 ]; then
  echo "verify-skill-manifest: FAIL ($VIOLATIONS violation(s))" >&2
  exit 1
fi

echo "verify-skill-manifest: PASS (4/4 conditions hold at $ROOT)"
