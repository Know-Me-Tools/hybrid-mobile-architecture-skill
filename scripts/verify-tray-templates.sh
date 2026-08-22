#!/usr/bin/env bash
# scripts/verify-tray-templates.sh
# Render the tauri-tray templates through the real scaffold and BUILD them.
#
# WHY THIS EXISTS
#   assets/templates/tauri-tray/ ships Rust that no build ever touched. It was
#   reviewed against Tauri's docs, which is not the same as compiling: when this
#   gate was first written it immediately found E0596 in tray.rs.template —
#   `apply_accessory_policy(app: &App)` cannot call `set_activation_policy`,
#   which needs `&mut App`. Every project scaffolded by scaffold-tauri-tray.sh
#   had received code that could not build.
#
#   The gate drives scaffold-tauri-tray.sh rather than re-implementing its
#   rendering, so what is compiled is exactly what a consumer receives.
#
# USAGE
#   bash scripts/verify-tray-templates.sh              # both templates
#   bash scripts/verify-tray-templates.sh --fast       # aggregator only (~14s)
#   bash scripts/verify-tray-templates.sh --keep       # leave the scratch tree
#
# COST (warm cargo cache, this machine)
#   health-aggregator  ~14s   — tokio only
#   tray.rs            ~2min  — the full Tauri 2 graph
#
#   That is why audit.sh exposes this as its own named mode and NOT as part of
#   `all`: a two-minute step inside the everyday aggregate audit is a step
#   people learn to skip.
#
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAFFOLD="$REPO_ROOT/scripts/scaffold-tauri-tray.sh"
CRATE_NAME="health-aggregator"
FAST=0
KEEP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --fast) FAST=1; shift ;;
    --keep) KEEP=1; shift ;;
    -h|--help) sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "verify-tray-templates: unknown option: $1" >&2; exit 1 ;;
  esac
done

command -v cargo >/dev/null 2>&1 || {
  echo "verify-tray-templates: cargo not on PATH — cannot build the templates" >&2
  exit 1
}
[ -x "$SCAFFOLD" ] || [ -f "$SCAFFOLD" ] || {
  echo "verify-tray-templates: missing $SCAFFOLD" >&2
  exit 1
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hma-tray.XXXXXX")"
cleanup() {
  if [ "$KEEP" = "1" ]; then echo "verify-tray-templates: scratch kept at $WORK"
  else rm -rf "$WORK"; fi
}
trap cleanup EXIT

FAILURES=0
SKIPPED=0
fail() { printf 'verify-tray-templates: FAIL: %s\n' "$1" >&2; FAILURES=$((FAILURES + 1)); }
ok()   { printf '  ✓ %s\n' "$1"; }

echo "── Tray template build gate"
echo "   scratch: $WORK"
echo ""

# ── Render through the REAL scaffold ─────────────────────────────────────────
TARGET="$WORK/app"
mkdir -p "$TARGET/src-tauri"
if ! bash "$SCAFFOLD" "$TARGET" --crate-name "$CRATE_NAME" >"$WORK/scaffold.out" 2>&1; then
  fail "scaffold-tauri-tray.sh itself failed:"
  sed 's/^/      /' "$WORK/scaffold.out" >&2
  exit 1
fi
ok "rendered via scaffold-tauri-tray.sh"

CRATE_DIR="$TARGET/crates/$CRATE_NAME"
[ -f "$CRATE_DIR/src/lib.rs" ] || fail "scaffold produced no $CRATE_NAME/src/lib.rs"
TRAY_RS="$TARGET/src-tauri/src/tray.rs"
[ -f "$TRAY_RS" ] || fail "scaffold produced no src-tauri/src/tray.rs"
[ "$FAILURES" -eq 0 ] || exit 1

# Keep one target dir for both builds so the Tauri graph is compiled once.
export CARGO_TARGET_DIR="$WORK/target"

# ── 1. health-aggregator: build + test + clippy ──────────────────────────────
echo ""
echo "── health-aggregator (tokio only)"
if ( cd "$CRATE_DIR" && cargo clippy --all-targets -- -D warnings ) >"$WORK/agg.out" 2>&1; then
  ok "clippy -D warnings clean"
else
  fail "health-aggregator clippy failed:"
  tail -25 "$WORK/agg.out" | sed 's/^/      /' >&2
fi
if ( cd "$CRATE_DIR" && cargo test ) >"$WORK/agg-test.out" 2>&1; then
  ok "$(grep -Eo '[0-9]+ passed' "$WORK/agg-test.out" | head -1 | sed 's/$/ tests/')"
else
  fail "health-aggregator tests failed:"
  tail -25 "$WORK/agg-test.out" | sed 's/^/      /' >&2
fi

# ── 2. tray.rs: compile against the real Tauri graph ─────────────────────────
if [ "$FAST" = "1" ]; then
  SKIPPED=1
  echo ""
  echo "  – tray.rs: SKIPPED (--fast). The Tauri graph is the slow half AND the"
  echo "    half that shipped a compile error; do not rely on --fast as the gate."
else
  echo ""
  echo "── tray.rs (full Tauri 2 graph — this is the ~2min half)"
  TRAY_CRATE="$WORK/tray-probe"
  mkdir -p "$TRAY_CRATE/src"
  cat > "$TRAY_CRATE/Cargo.toml" <<EOF_TOML
[package]
name = "tray-probe"
version = "0.1.0"
edition = "2021"

[dependencies]
tauri = { version = "2", features = ["tray-icon"] }
EOF_TOML
  cp "$TRAY_RS" "$TRAY_CRATE/src/lib.rs"
  if ( cd "$TRAY_CRATE" && cargo clippy -- -D warnings ) >"$WORK/tray.out" 2>&1; then
    ok "tray.rs compiles clean under clippy -D warnings"
  else
    fail "tray.rs does not compile:"
    grep -E '^(error|warning)' "$WORK/tray.out" | head -12 | sed 's/^/      /' >&2
    tail -8 "$WORK/tray.out" | sed 's/^/      /' >&2
  fi
fi

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "verify-tray-templates: FAIL — $FAILURES problem(s); the scaffold ships code that does not build" >&2
  exit 1
fi
if [ "$SKIPPED" = "1" ]; then
  # Exit 2, not 0. A prose warning is not a machine-readable signal: with a
  # deliberately broken tray.rs, --fast previously printed "PASS — every
  # rendered template builds" and exited 0. Anything consuming the exit code
  # would have recorded a green gate over the exact defect this exists to catch.
  echo "verify-tray-templates: PARTIAL — health-aggregator only; tray.rs was NOT built (--fast)." >&2
  echo "verify-tray-templates: this is not a pass. Run without --fast to gate the templates." >&2
  exit 2
fi
echo "verify-tray-templates: PASS — every rendered template builds"
