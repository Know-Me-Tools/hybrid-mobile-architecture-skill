#!/usr/bin/env bash
# Re-apply this pack's repo-local invariants to vendored skill mirrors.
#
# WHY THIS EXISTS
#   `openspec update` regenerates the vendored openspec-* / source-command-opsx-*
#   skills from an external generator. `metadata.internal: true` is a repo-local
#   requirement that `scripts/check-skill-contracts.mjs` imposes on those files;
#   the OpenSpec CLI has no notion of `internal` (it appears nowhere in
#   openspec/config.yaml or the CLI's vocabulary), so it strips the key on EVERY
#   run, on every version. Bumping the pin does not stop that — only this script
#   does.
#
# USAGE
#   openspec update [--force]            # external generator writes the mirrors
#   bash scripts/normalize-vendored-skills.sh   # re-apply repo invariants
#   node scripts/check-skill-contracts.mjs      # gate should now pass
#
#   --check   report what would change; exit 1 if anything would; write nothing.
#
# The managed harness set is DERIVED from check-skill-contracts.mjs rather than
# hardcoded here, so a future harness addition or migration cannot silently fall
# outside normalization while still being gated.
#
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTRACT="$REPO_ROOT/scripts/check-skill-contracts.mjs"
CHECK_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1; shift ;;
    -h|--help) sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "normalize-vendored-skills: unknown option: $1" >&2; exit 1 ;;
  esac
done

[ -f "$CONTRACT" ] || {
  echo "normalize-vendored-skills: missing $CONTRACT" >&2
  exit 1
}

# Derive the managed harnesses + prefixes from the contract check's own table,
# so the two can never disagree about which trees are governed.
# The table is READ, not imported: check-skill-contracts.mjs runs its assertions
# at module scope and calls process.exit(1) when the gate fails, so importing it
# would kill this script precisely when the mirrors are broken — the one moment
# normalization is needed. Parsing the exported literal keeps the single source
# of truth without inheriting the gate's exit behaviour.
#
# An earlier revision scraped `"name": { ... }` line by line and silently
# dropped any entry a formatter wrapped across lines; a JSON parse of the whole
# object literal cannot do that. Any shape it cannot parse is a hard error.
HARNESSES="$(
  node -e '
    const fs = require("node:fs");
    const src = fs.readFileSync(process.argv[1], "utf8");
    const m = src.match(/export const INTERNAL_SKILL_HARNESSES = (\{[\s\S]*?\n\});/);
    if (!m) {
      process.stderr.write("cannot locate the exported INTERNAL_SKILL_HARNESSES literal\n");
      process.exit(1);
    }
    let table;
    try {
      // Tolerate trailing commas, then parse as JSON so multi-line and
      // single-line spellings are equally valid.
      table = JSON.parse(m[1].replace(/,(\s*[}\]])/g, "$1"));
    } catch (err) {
      process.stderr.write(`INTERNAL_SKILL_HARNESSES is not parseable: ${err.message}\n`);
      process.exit(1);
    }
    for (const [harness, prefixes] of Object.entries(table)) {
      const wanted = Object.entries(prefixes)
        .filter(([, count]) => Number(count) > 0)
        .map(([prefix, count]) => `${prefix}:${count}`);
      if (wanted.length) process.stdout.write(`${harness} ${wanted.join(",")}\n`);
    }
  ' "$CONTRACT"
)"
[ -n "$HARNESSES" ] || {
  echo "normalize-vendored-skills: derived an empty harness set — refusing to run" >&2
  exit 1
}

changed=0
scanned=0

while read -r harness prefixes; do
  [ -n "$harness" ] || continue
  if [ ! -d "$REPO_ROOT/$harness/skills" ]; then
    echo "normalize-vendored-skills: managed harness $harness/skills is missing" >&2
    exit 1
  fi
  IFS=',' read -ra PREFIX_LIST <<< "$prefixes"
  for spec in "${PREFIX_LIST[@]}"; do
    prefix="${spec%%:*}"
    want="${spec##*:}"
    found=0
    for dir in "$REPO_ROOT/$harness/skills/$prefix"*/; do
      [ -d "$dir" ] || continue
      file="${dir%/}/SKILL.md"
      [ -f "$file" ] || continue
      scanned=$((scanned + 1))
      found=$((found + 1))

      # Already correct? `internal: true` must be the LAST key under `metadata:`
      # — that is the shape check-skill-contracts.mjs asserts.
      if REPLY="$(SKILL_FILE="$file" python3 -c '
import os, re, sys
t = open(os.environ["SKILL_FILE"]).read()
fm = re.match(r"^---\n([\s\S]*?)\n---(?:\n|$)", t)
sys.exit(0 if fm and re.search(r"^metadata:\n(?:  .+\n)*  internal: true$", fm.group(1) + "\n", re.M) else 1)
' 2>/dev/null; echo $?)"; [ "$REPLY" = "0" ]; then
        continue
      fi

      changed=$((changed + 1))
      rel="${file#"$REPO_ROOT"/}"
      if [ "$CHECK_ONLY" = "1" ]; then
        echo "would normalize: $rel"
        continue
      fi

      SKILL_FILE="$file" python3 <<'PY'
import os, re, sys

path = os.environ["SKILL_FILE"]
text = open(path).read()

# Operate on the YAML frontmatter ONLY. An unanchored edit would inject
# `internal: true` into whatever `metadata:` appeared first — including a prose
# example in the body — satisfying an unanchored gate while the frontmatter the
# harnesses parse stays wrong.
fm = re.match(r"^---\n([\s\S]*?)\n---(?:\n|$)", text)
if not fm:
    sys.stderr.write(f"normalize-vendored-skills: {path}: no YAML frontmatter\n")
    sys.exit(1)

head, body = fm.group(1), text[fm.end():]
head = re.sub(r"^  internal:.*\n", "", head + "\n", flags=re.M).rstrip("\n")

m = re.search(r"^metadata:\n((?:  .+\n)*)", head + "\n", re.M)
if m:
    head = (head + "\n")[:m.end(1)] + "  internal: true\n" + (head + "\n")[m.end(1):]
    head = head.rstrip("\n")
else:
    head = head + "\nmetadata:\n  internal: true"

open(path, "w").write(f"---\n{head}\n---\n{body}")
PY
      echo "normalized: $rel"
    done
    # A harness that lost its mirrors must not be reported as "already
    # normalized" — the glob would simply match nothing and the loop would
    # report success for a tree that is not there.
    if [ "$found" -ne "$want" ]; then
      echo "normalize-vendored-skills: $harness/skills: expected $want ${prefix}* mirror(s), found $found" >&2
      exit 1
    fi
  done
done <<< "$HARNESSES"

if [ "$CHECK_ONLY" = "1" ]; then
  if [ "$changed" -gt 0 ]; then
    echo "normalize-vendored-skills: $changed of $scanned mirror(s) need normalization" >&2
    exit 1
  fi
  echo "normalize-vendored-skills: all $scanned vendored mirror(s) already normalized"
  exit 0
fi

echo "normalize-vendored-skills: normalized $changed of $scanned vendored mirror(s)"
