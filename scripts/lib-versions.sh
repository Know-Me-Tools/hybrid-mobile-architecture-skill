#!/usr/bin/env bash
# scripts/lib-versions.sh — read versions.toml into shell variables.
#
# versions.toml is declared the SINGLE SOURCE OF TRUTH for tool/stack versions,
# but before this library every scaffolder hardcoded its own copies. That is how
# the pack drifted away from the projects it generated: bumping versions.toml
# changed the docs and the audit, and changed nothing about the emitted code.
#
# Source this, then use the exported variables in scaffolder heredocs:
#
#   source "$SCRIPT_DIR/lib-versions.sh"
#   echo "flutter_rust_bridge: $FRB_VERSION"
#
# Adding a pin: add it to versions.toml, then map it here. Never inline a
# version literal in a scaffolder — `audit.sh doc-consistency` cannot see those,
# so they rot silently.

set -euo pipefail

_VERSIONS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_TOML="${VERSIONS_TOML:-$_VERSIONS_LIB_DIR/../versions.toml}"

if [[ ! -f "$VERSIONS_TOML" ]]; then
  echo "FATAL: versions.toml not found at $VERSIONS_TOML" >&2
  exit 1
fi

# Read `key = "value"` from a [section]. Minimal on purpose: versions.toml is a
# flat file of quoted string scalars, so a TOML parser would be a dependency
# bought for nothing. Trailing `# comments` are stripped.
toml_get() {
  local section="$1" key="$2"
  awk -v section="[$section]" -v key="$key" '
    /^\[/            { in_section = ($0 == section); next }
    !in_section      { next }
    $1 == key {
      sub(/^[^=]*=[[:space:]]*/, "")
      sub(/[[:space:]]*#.*$/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$VERSIONS_TOML"
}

# Fail loudly on a missing pin. A silently-empty version produces a manifest
# like `flutter_rust_bridge: ` that fails much later with a worse message.
_require() {
  local varname="$1" value="$2"
  if [[ -z "$value" ]]; then
    echo "FATAL: $varname is empty — missing from $VERSIONS_TOML" >&2
    exit 1
  fi
  printf '%s' "$value"
}

# ── [toolchain] ─────────────────────────────────────────────────────────────
RUST_VERSION="$(_require RUST_VERSION "$(toml_get toolchain rust)")"
NODE_VERSION="$(_require NODE_VERSION "$(toml_get toolchain node)")"
FLUTTER_VERSION="$(_require FLUTTER_VERSION "$(toml_get toolchain flutter)")"
TYPESCRIPT_VERSION="$(_require TYPESCRIPT_VERSION "$(toml_get toolchain typescript)")"

# ── [frameworks] ────────────────────────────────────────────────────────────
TAURI_CLI_VERSION="$(_require TAURI_CLI_VERSION "$(toml_get frameworks tauri_cli)")"
FRB_VERSION="$(_require FRB_VERSION "$(toml_get frameworks flutter_rust_bridge)")"
RIVERPOD_VERSION="$(_require RIVERPOD_VERSION "$(toml_get frameworks riverpod)")"
VITE_VERSION="$(_require VITE_VERSION "$(toml_get frameworks vite)")"
REACT_VERSION="$(_require REACT_VERSION "$(toml_get frameworks react)")"
ZUSTAND_VERSION="$(_require ZUSTAND_VERSION "$(toml_get frameworks zustand)")"

# ── [android_build] ─────────────────────────────────────────────────────────
GRADLE_VERSION="$(_require GRADLE_VERSION "$(toml_get android_build gradle)")"
AGP_VERSION="$(_require AGP_VERSION "$(toml_get android_build android_gradle_plugin)")"
KOTLIN_VERSION="$(_require KOTLIN_VERSION "$(toml_get android_build kotlin_android_plugin)")"
LITERT_LM_VERSION="$(_require LITERT_LM_VERSION "$(toml_get android_build litert_lm_android)")"

# ── [platform] ──────────────────────────────────────────────────────────────
DART_MIN="$(_require DART_MIN "$(toml_get platform dart)")"
ANDROID_MIN_SDK="$(_require ANDROID_MIN_SDK "$(toml_get platform android_min_sdk)")"
ANDROID_ABI="$(_require ANDROID_ABI "$(toml_get platform android_abi)")"
IOS_DEPLOYMENT_TARGET="$(_require IOS_DEPLOYMENT_TARGET "$(toml_get platform ios_deployment_target)")"
MACOS_DEPLOYMENT_TARGET="$(_require MACOS_DEPLOYMENT_TARGET "$(toml_get platform macos_deployment_target)")"
JVM_TARGET="$(_require JVM_TARGET "$(toml_get platform jvm_target)")"

# ── [data] ──────────────────────────────────────────────────────────────────
SURREALDB_VERSION="$(_require SURREALDB_VERSION "$(toml_get data surrealdb)")"
PGLITE_OXIDE_VERSION="$(_require PGLITE_OXIDE_VERSION "$(toml_get data pglite_oxide)")"

# ── [sync] ──────────────────────────────────────────────────────────────────
PGLITE_VERSION="$(_require PGLITE_VERSION "$(toml_get sync pglite)")"
LORO_CRDT_VERSION="$(_require LORO_CRDT_VERSION "$(toml_get sync loro_crdt)")"
EMBEDDING_DIM="$(_require EMBEDDING_DIM "$(toml_get sync embedding_dim)")"

# ── [inference] ─────────────────────────────────────────────────────────────
INFERENCE_DESKTOP="$(_require INFERENCE_DESKTOP "$(toml_get inference desktop)")"
INFERENCE_ANDROID="$(_require INFERENCE_ANDROID "$(toml_get inference android)")"
INFERENCE_IOS="$(_require INFERENCE_IOS "$(toml_get inference ios)")"
INFERENCE_WEB="$(_require INFERENCE_WEB "$(toml_get inference web)")"

# Derived: the Dart SDK line Flutter ships, used in pubspec `environment:`.
DART_VERSION="${DART_VERSION:-$DART_MIN}"

export RUST_VERSION NODE_VERSION FLUTTER_VERSION TYPESCRIPT_VERSION \
  TAURI_CLI_VERSION FRB_VERSION RIVERPOD_VERSION VITE_VERSION REACT_VERSION \
  ZUSTAND_VERSION GRADLE_VERSION AGP_VERSION KOTLIN_VERSION LITERT_LM_VERSION \
  DART_MIN DART_VERSION ANDROID_MIN_SDK ANDROID_ABI IOS_DEPLOYMENT_TARGET \
  MACOS_DEPLOYMENT_TARGET JVM_TARGET SURREALDB_VERSION PGLITE_OXIDE_VERSION \
  PGLITE_VERSION LORO_CRDT_VERSION EMBEDDING_DIM \
  INFERENCE_DESKTOP INFERENCE_ANDROID INFERENCE_IOS INFERENCE_WEB
