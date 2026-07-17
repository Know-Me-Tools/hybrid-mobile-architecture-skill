#!/usr/bin/env bash
# TJ-ARCH-MOB-001 compliant
# Launch a built KnowMe Tauri binary with isolated app data and prove that its
# frontend completed the real migrations -> seeds -> local-sync startup path.

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: bash scripts/verify-tauri-boot.sh <binary> <empty-app-data-dir> [timeout-seconds]" >&2
  exit 2
fi

BINARY="$1"
APP_DATA="$2"
LIMIT_SECONDS="${3:-240}"

if [[ ! -x "$BINARY" ]]; then
  echo "Tauri binary is not executable: $BINARY" >&2
  exit 2
fi
if [[ -e "$APP_DATA" ]]; then
  echo "App-data proof directory must not already exist: $APP_DATA" >&2
  exit 2
fi

mkdir -p "$APP_DATA"
PROCESS_LOG="$APP_DATA/tauri-process.log"
DIAGNOSTIC_LOG="$APP_DATA/diagnostics/desktop.log"

GEN_UI_APP_DATA_DIR="$APP_DATA" RUST_LOG="info" "$BINARY" >"$PROCESS_LOG" 2>&1 &
APP_PID=$!

cleanup() {
  if kill -0 "$APP_PID" 2>/dev/null; then
    pkill -TERM -P "$APP_PID" 2>/dev/null || true
    kill -TERM "$APP_PID" 2>/dev/null || true
    for _ in 1 2 3 4 5; do
      kill -0 "$APP_PID" 2>/dev/null || return 0
      sleep 1
    done
    pkill -KILL -P "$APP_PID" 2>/dev/null || true
    kill -KILL "$APP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

deadline=$((SECONDS + LIMIT_SECONDS))
while (( SECONDS < deadline )); do
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    echo "Tauri exited before reaching ready state" >&2
    tail -n 200 "$PROCESS_LOG" >&2 || true
    [[ -f "$DIAGNOSTIC_LOG" ]] && tail -n 200 "$DIAGNOSTIC_LOG" >&2
    exit 1
  fi

  if [[ -f "$DIAGNOSTIC_LOG" ]] \
    && grep -q "desktop migrations ready" "$DIAGNOSTIC_LOG" \
    && grep -q "seed load ready" "$DIAGNOSTIC_LOG" \
    && grep -q "sync ready in local-only mode" "$DIAGNOSTIC_LOG" \
    && [[ -d "$APP_DATA/config-db" ]] \
    && [[ -d "$APP_DATA/memory-db" ]] \
    && [[ -d "$APP_DATA/model-cache/fastembed" ]]; then
    echo "Tauri boot proof passed"
    echo "diagnostics=$DIAGNOSTIC_LOG"
    echo "app_data=$APP_DATA"
    exit 0
  fi
  sleep 1
done

echo "Tauri did not reach ready within ${LIMIT_SECONDS}s" >&2
tail -n 200 "$PROCESS_LOG" >&2 || true
[[ -f "$DIAGNOSTIC_LOG" ]] && tail -n 200 "$DIAGNOSTIC_LOG" >&2
exit 1
