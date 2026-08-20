#!/usr/bin/env bash
# scripts/scaffold-tauri-tray.sh
# Emit the tray-resident Tauri surface: a health-aggregator crate plus the tray,
# popover, and dashboard wiring.
#
# Usage:
#   bash scripts/scaffold-tauri-tray.sh <target-root> [--crate-name NAME] [--tray-id ID] [--force]
#
# Additive: refuses to overwrite an existing file unless --force is given, so
# re-running over a project that has diverged does not silently discard work.
# Verify the generated crate with:  cargo test -p <crate-name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../assets/templates/tauri-tray"

TARGET=""
CRATE_NAME="health-aggregator"
TRAY_ID="supervisor-tray"
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --crate-name) CRATE_NAME="${2:?--crate-name needs a value}"; shift 2 ;;
    --tray-id)    TRAY_ID="${2:?--tray-id needs a value}"; shift 2 ;;
    --force)      FORCE=1; shift ;;
    -h|--help)    sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)           echo "scaffold-tauri-tray: unknown option: $1" >&2; exit 1 ;;
    *)            TARGET="$1"; shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "usage: scaffold-tauri-tray.sh <target-root> [--crate-name NAME] [--tray-id ID] [--force]" >&2
  exit 2
fi

case "$CRATE_NAME" in
  ''|*[!a-z0-9_-]*)
    echo "scaffold-tauri-tray: --crate-name must be lowercase kebab or snake: $CRATE_NAME" >&2
    exit 1 ;;
esac

[ -d "$TEMPLATE_DIR" ] || {
  echo "scaffold-tauri-tray: missing templates: $TEMPLATE_DIR" >&2
  exit 1
}

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

CRATE_DIR="$TARGET/crates/$CRATE_NAME"
SRC_TAURI="$TARGET/src-tauri/src"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { printf '\n%b── %s%b\n' "$CYAN" "$1" "$NC"; }
ok()   { printf '%b  ✓%b %s\n' "$GREEN" "$NC" "$1"; }
skip() { printf '%b  ⚠%b %s\n' "$YELLOW" "$NC" "$1"; }

# render <template> <destination>
render() {
  local template="$1" destination="$2"
  if [ -e "$destination" ] && [ "$FORCE" -eq 0 ]; then
    skip "exists, left untouched: ${destination#"$TARGET"/} (use --force to overwrite)"
    return 0
  fi
  mkdir -p "$(dirname "$destination")"
  TPL_CRATE_NAME="$CRATE_NAME" TPL_TRAY_ID="$TRAY_ID" python3 -c '
import os, sys

subs = {
    "@@CRATE_NAME@@": os.environ["TPL_CRATE_NAME"],
    "@@TRAY_ID@@": os.environ["TPL_TRAY_ID"],
}
with open(sys.argv[1], encoding="utf-8") as handle:
    text = handle.read()
for token, value in subs.items():
    text = text.replace(token, value)
with open(sys.argv[2], "w", encoding="utf-8") as handle:
    handle.write(text)
' "$template" "$destination"
  ok "${destination#"$TARGET"/}"
}

step "Health aggregator crate"
render "$TEMPLATE_DIR/health-aggregator/Cargo.toml.template" "$CRATE_DIR/Cargo.toml"
render "$TEMPLATE_DIR/health-aggregator/src/lib.rs.template"  "$CRATE_DIR/src/lib.rs"

step "Tray, popover, and dashboard wiring"
render "$TEMPLATE_DIR/tray.rs.template" "$SRC_TAURI/tray.rs"

step "Next steps"
cat <<NEXT
  1. Add the crate to the workspace members in $TARGET/Cargo.toml:
       members = ["crates/$CRATE_NAME", "src-tauri"]
  2. Depend on it from src-tauri/Cargo.toml:
       $CRATE_NAME = { path = "../crates/$CRATE_NAME" }
  3. Declare the module and call the wiring from your Tauri setup:
       mod tray;
       tray::apply_accessory_policy(app);
       tray::build_tray(app)?;
       tray::intercept_dashboard_close(app);
  4. Define the "$(printf '%s' 'popover')" window (frameless, transparent,
     always-on-top, skipTaskbar) alongside the "main" dashboard window.
  5. Verify:  cargo test -p $CRATE_NAME
NEXT
ok "scaffolded into ${TARGET}"
