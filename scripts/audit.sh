#!/usr/bin/env bash
# scripts/audit.sh
# Audit a codebase for TJ-ARCH-MOB-001 architectural compliance.
# Usage: bash scripts/audit.sh <platform: flutter|tauri|rust|doc-consistency|all> [project-root]
#
# `doc-consistency` audits the PACK's own authority docs (SKILL.md, CLAUDE.md,
# AGENTS.md, README.md, references/*.md) against versions.toml — the pack's
# instructions to agents must not contradict themselves.
#
# `all` audits every surface of a hybrid project from its root, auto-detecting
# mobile/ (Flutter), desktop/ (Tauri), and rust/gen_ui_core — and verifies the
# KnowMe-slice layer contracts on each present surface in one pass.

set -euo pipefail

PLATFORM="${1:-flutter}"
ROOT="${2:-.}"

# ── all: fan out over every present surface of a hybrid project ──────────────
if [[ "$PLATFORM" == "all" ]]; then
  SELF="$0"
  HYBRID_ROOT="$ROOT"
  # The hybrid scaffold nests everything under a <project>/ dir. If the given
  # root has no surfaces directly but a single subdir does, descend into it.
  if [[ ! -d "$HYBRID_ROOT/mobile" && ! -d "$HYBRID_ROOT/desktop" ]]; then
    for sub in "$HYBRID_ROOT"/*/; do
      if [[ -d "$sub/mobile" || -d "$sub/desktop" ]]; then HYBRID_ROOT="${sub%/}"; break; fi
    done
  fi

  RC=0
  ran_any=0
  # UI surfaces carry the KnowMe-slice layer contracts — audit both if present.
  for spec in "Flutter mobile:flutter:mobile" "Tauri desktop:tauri:desktop"; do
    label="${spec%%:*}"; rest="${spec#*:}"; plat="${rest%%:*}"; sub="${rest#*:}"
    target="$HYBRID_ROOT/$sub"
    if [[ -d "$target" ]]; then
      ran_any=1
      echo ""
      echo -e "\033[0;36m########## $label ($target) ##########\033[0m"
      bash "$SELF" "$plat" "$target" || RC=1
    fi
  done
  # Rust: the single-crate scaffold ships rust/gen_ui_core (audits cleanly). The
  # layered workspace (C-001) splits modules across rust/crates/* — no one crate
  # matches the monolithic module audit, so skip it here and note the alternative.
  if [[ -d "$HYBRID_ROOT/rust/gen_ui_core/src" ]]; then
    ran_any=1
    echo ""
    echo -e "\033[0;36m########## Rust core ($HYBRID_ROOT/rust/gen_ui_core) ##########\033[0m"
    bash "$SELF" "rust" "$HYBRID_ROOT/rust/gen_ui_core" || RC=1
  elif [[ -d "$HYBRID_ROOT/rust/crates" ]]; then
    echo ""
    echo -e "\033[0;36m########## Rust workspace ($HYBRID_ROOT/rust) ##########\033[0m"
    echo "  → layered workspace detected (rust/crates/*): module invariants are"
    echo "    enforced per-crate at compile time; run 'cargo clippy' at the rust root."
  fi

  # Doc-consistency is pack-global, not per-surface: run once. It self-skips
  # when the authority docs aren't present (i.e. inside a scaffolded project).
  echo ""
  echo -e "\033[0;36m########## Doc consistency (pack authority docs) ##########\033[0m"
  bash "$SELF" "doc-consistency" || RC=1
  ran_any=1

  if [[ "$ran_any" == "0" ]]; then
    echo "Error: no surfaces found under $HYBRID_ROOT (expected mobile/, desktop/, or rust/gen_ui_core)"
    exit 1
  fi
  echo ""
  if [[ $RC -eq 0 ]]; then
    echo -e "\033[0;32m  ✓ All present surfaces compliant with TJ-ARCH-MOB-001\033[0m"
  else
    echo -e "\033[0;31m  ✗ One or more surfaces have violations — see above\033[0m"
  fi
  exit $RC
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
pass()  { echo -e "    ${GREEN}✓${NC} $1"; ((PASS_COUNT++)) || true; }
fail()  { echo -e "    ${RED}✗${NC} $1"; ((FAIL_COUNT++)) || true; ((VIOLATIONS++)) || true; }
warn()  { echo -e "    ${YELLOW}⚠${NC} $1"; ((WARN_COUNT++)) || true; }
check() { echo -e "  ${CYAN}→${NC} $1"; }

PASS_COUNT=0; FAIL_COUNT=0; WARN_COUNT=0; VIOLATIONS=0

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  TJ-ARCH-MOB-001 Compliance Audit — $PLATFORM ${NC}"
echo -e "${CYAN}  $(date +%Y-%m-%d)                                  ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""

# ── Flutter audit ──────────────────────────────────────────────────────────
if [[ "$PLATFORM" == "flutter" ]]; then
  LIB="$ROOT/lib"
  [[ -d "$LIB" ]] || { echo "Error: $LIB not found"; exit 1; }

  echo -e "${CYAN}[01] Dependency checks (pubspec.yaml)${NC}"
  PUBSPEC="$ROOT/pubspec.yaml"
  if [[ -f "$PUBSPEC" ]]; then
    grep -q "flutter_riverpod:" "$PUBSPEC" && pass "flutter_riverpod present" || fail "flutter_riverpod MISSING — required"
    grep -q "riverpod_annotation:" "$PUBSPEC" && pass "riverpod_annotation present" || fail "riverpod_annotation MISSING"
    grep -q "freezed_annotation:" "$PUBSPEC" && pass "freezed_annotation present" || warn "freezed_annotation not found"
    grep -q "flutter_rust_bridge:" "$PUBSPEC" && pass "flutter_rust_bridge present" || warn "flutter_rust_bridge not found (required when gen_ui_core is wired)"
    grep -q "shadcn_flutter:" "$PUBSPEC" && pass "shadcn_flutter present (shadcn equivalent)" || warn "shadcn_flutter not found — consider adding"
    grep -q "go_router:" "$PUBSPEC" && pass "go_router present" || warn "go_router not found"
    # Anchor to the dependency key so path_provider (and other *_provider packages)
    # don't trip the check — match only the standalone `provider` package.
    grep -qE "^[[:space:]]+provider:" "$PUBSPEC" && fail "provider package found — use Riverpod only" || pass "provider package not present ✓"
    # Catch both `bloc:` and `flutter_bloc:` as dependency keys.
    grep -qE "^[[:space:]]+(flutter_)?bloc:" "$PUBSPEC" && fail "bloc package found — use Riverpod only" || pass "bloc package not present ✓"
    grep -q "setState\|StatefulWidget" "$LIB/features" 2>/dev/null && warn "StatefulWidget usage found — prefer ConsumerStatefulWidget or hooks" || true
  else
    fail "pubspec.yaml not found"
  fi

  echo ""
  echo -e "${CYAN}[02] Feature-based clean architecture${NC}"
  if [[ -d "$LIB/features" ]]; then
    pass "features/ directory exists"
    for feature in "$LIB/features"/*/; do
      fname="$(basename "$feature")"
      [[ -d "$feature/data" ]]         && pass "  $fname/data/" || warn "  $fname/data/ missing"
      [[ -d "$feature/domain" ]]       && pass "  $fname/domain/" || fail "  $fname/domain/ MISSING — required"
      [[ -d "$feature/presentation" ]] && pass "  $fname/presentation/" || fail "  $fname/presentation/ MISSING"
    done
  else
    fail "features/ directory MISSING — feature-based arch required"
  fi

  [[ -d "$LIB/core" ]]   && pass "core/ directory exists" || warn "core/ directory missing"
  [[ -d "$LIB/shared" ]] && pass "shared/ directory exists" || warn "shared/ directory missing"
  [[ -d "$LIB/bridge" ]] && pass "bridge/ directory exists" || warn "bridge/ directory missing (required for Rust FFI)"

  echo ""
  echo -e "${CYAN}[03] Riverpod pattern compliance${NC}"
  # Check for codegen annotations
  if find "$LIB" -name "*.dart" | xargs grep -l "@riverpod\|@Riverpod" 2>/dev/null | head -1 | grep -q .; then
    pass "@riverpod codegen annotations found"
  else
    warn "@riverpod codegen annotations not found — use codegen, not manual providers"
  fi
  # Check for manual StateNotifierProvider (deprecated pattern)
  if grep -r "StateNotifierProvider\|ChangeNotifierProvider" "$LIB" 2>/dev/null | grep -v ".g.dart" | grep -q .; then
    fail "StateNotifierProvider/ChangeNotifierProvider found — use @riverpod codegen"
  else
    pass "No deprecated provider patterns found"
  fi

  echo ""
  echo -e "${CYAN}[04] Business logic boundary${NC}"
  # Check for HTTP calls in presentation layer
  if grep -r "http\.\|dio\.\|Dio(" "$LIB/features" 2>/dev/null | grep -E "presentation/|screens/|widgets/" | grep -v ".g.dart" | grep -q .; then
    fail "HTTP calls found in presentation layer — move to data/repositories"
  else
    pass "No HTTP calls in presentation layer"
  fi
  # Check for invoke() in Flutter (should be in Rust, not Dart HTTP)
  if grep -r "import 'package:http/" "$LIB/features" 2>/dev/null | grep -E "presentation/" | grep -q .; then
    fail "http package imported in presentation — use repository pattern"
  else
    pass "HTTP package not imported in presentation layer"
  fi

  echo ""
  echo -e "${CYAN}[05] Code generation artifacts${NC}"
  if find "$LIB" -name "*.g.dart" | head -1 | grep -q .; then
    pass "Code generation artifacts (.g.dart) present"
  else
    warn "No .g.dart files found — run: flutter pub run build_runner build"
  fi
  if find "$LIB" -name "*.freezed.dart" | head -1 | grep -q .; then
    pass "Freezed artifacts (.freezed.dart) present"
  else
    warn "No .freezed.dart files found — run: flutter pub run build_runner build"
  fi

  echo ""
  echo -e "${CYAN}[06] gen_ui_core FFI bridge${NC}"
  if [[ -f "$LIB/bridge/rust_bridge_provider.dart" ]]; then
    pass "bridge/rust_bridge_provider.dart present"
    grep -q "import 'generated_api.dart'" "$LIB/bridge/rust_bridge_provider.dart" && pass "FFI import wired" || warn "FFI import not yet wired (uncomment after frb codegen)"
  else
    warn "bridge/rust_bridge_provider.dart not found"
  fi

  echo ""
  echo -e "${CYAN}[07] Layer contract — FFI facade reached only through providers${NC}"
  # The bridge facade (rust_bridge_provider) is the FFI seam. Screens/widgets must
  # NOT import it directly — they go through providers/notifiers. (UI → provider → FFI)
  if grep -rn "rust_bridge_provider.dart" "$LIB/features" 2>/dev/null | grep -E "presentation/(screens|widgets)/" | grep -q .; then
    fail "bridge facade imported in a screen/widget — reach the FFI only via providers/notifiers"
    grep -rn "rust_bridge_provider.dart" "$LIB/features" 2>/dev/null | grep -E "presentation/(screens|widgets)/" | head -5 | sed 's/^/    /'
  else
    pass "bridge facade not imported in screens/widgets ✓"
  fi
  # No raw graph/SQL query strings in Dart — the intent surface (memory_search,
  # graph_expand) lives in Rust; Dart never sees SurrealQL/SQL. Match only inside
  # Dart string literals ('…"…) and skip doc/line comments so keywords in prose
  # (e.g. "recursive RELATE walk") don't false-positive.
  dart_raw_sql() {
    grep -rn "SELECT .*FROM\|RELATE \|DEFINE INDEX\|DEFINE TABLE" "$LIB" 2>/dev/null \
      | grep -v ".g.dart" \
      | sed -E 's/^[^:]+:[0-9]+://' \
      | grep -vE '^[[:space:]]*//' \
      | grep -E "['\"]"
  }
  if dart_raw_sql | grep -q .; then
    fail "raw query strings found in Dart — graph/SQL lives in Rust, never the UI layer"
    dart_raw_sql | head -5 | sed 's/^/    /'
  else
    pass "No raw SurrealQL/SQL in Dart ✓"
  fi
  # FFI-backed providers must opt out of Riverpod 3 auto-retry (Rust errors are
  # terminal). Flag providers that reach the bridge without a retry override.
  if grep -rln "rust_bridge_provider.dart" "$LIB" 2>/dev/null | grep -E "providers/|_provider.dart|_notifier.dart" | grep -q .; then
    if grep -rn "@Riverpod(retry:" "$LIB" 2>/dev/null | grep -q .; then
      pass "FFI providers opt out of auto-retry (@Riverpod(retry: …)) ✓"
    else
      warn "No @Riverpod(retry: …) override found — FFI-backed providers should disable auto-retry"
    fi
  fi

  echo ""
  echo -e "${CYAN}[08] KnowMe-slice features present${NC}"
  # The vertical slice proves every seam: chat, entity CRUD, memory/graph-RAG,
  # sync status, first-run startup. Missing any leaves a seam unproven.
  for f in chat notes memory startup; do
    [[ -d "$LIB/features/$f" ]] && pass "features/$f/" || fail "features/$f/ MISSING — KnowMe-slice seam unproven"
  done
  [[ -f "$LIB/shared/widgets/sync_chip.dart" ]] && pass "sync status chip present" || warn "shared/widgets/sync_chip.dart not found"

# ── Tauri/React audit ─────────────────────────────────────────────────────
elif [[ "$PLATFORM" == "tauri" ]]; then
  SRC="$ROOT/src"
  [[ -d "$SRC" ]] || { echo "Error: $SRC not found"; exit 1; }

  echo -e "${CYAN}[01] Dependency checks (package.json)${NC}"
  PKG="$ROOT/package.json"
  if [[ -f "$PKG" ]]; then
    # Pass $PKG to every grep — a single stdin redirect on the `if` would let the
    # first grep drain it and starve the rest (they'd all read EOF and "fail").
    grep -q '"zustand"'                "$PKG" && pass "zustand present" || fail "zustand MISSING — required"
    grep -q '"@prometheus-ags/prometheus-entity-management"' "$PKG" && pass "Prometheus Entity Management present" || fail "@prometheus-ags/prometheus-entity-management MISSING — required 3.x server/entity state layer"
    grep -q '"@prometheus-ags/prometheus-entity-management"[[:space:]]*:[[:space:]]*"[~^]*3\.' "$PKG" && pass "Prometheus Entity Management is on 3.x" || fail "Prometheus Entity Management must use version 3.x"
    grep -q '"@tanstack/react-query"' "$PKG" && fail "@tanstack/react-query found — use Prometheus Entity Management 3.x" || pass "TanStack Query not present ✓"
    grep -q '"@tanstack/react-router"' "$PKG" && pass "@tanstack/react-router present" || fail "@tanstack/react-router MISSING"
    grep -q '"@tanstack/react-table"'  "$PKG" && pass "@tanstack/react-table present" || warn "@tanstack/react-table not found"
    grep -q '"@tauri-apps/api"'        "$PKG" && pass "@tauri-apps/api present" || fail "@tauri-apps/api MISSING"
    grep -q '"@assistant-ui/react"'    "$PKG" && pass "Assistant UI present" || fail "@assistant-ui/react MISSING — required chat runtime"
    grep -q '"@electric-sql/pglite"'   "$PKG" && pass "PGlite present" || fail "PGlite MISSING — browser conversation persistence required"
    grep -q '"immer"'                  "$PKG" && pass "immer present" || warn "immer not found — recommended for Zustand"
    grep -qE '"(redux|@reduxjs)'       "$PKG" && fail "Redux found — use Zustand" || pass "Redux not present ✓"
    grep -qE '"(jotai|recoil)'         "$PKG" && fail "jotai/recoil found — use Zustand" || pass "jotai/recoil not present ✓"
    grep -qE '"react-router'           "$PKG" && fail "react-router found — use TanStack Router" || pass "react-router not present ✓"

    # C-125 local-first gates (references/sync/doctrine.md).
    # Declared-but-unused sync deps misrepresent capability (assessment gap 8):
    # each of these, when declared, must actually be imported somewhere in src/.
    for dep in "loro-crdt" "@electric-sql/pglite-sync" "@electric-sql/pglite-pgvector"; do
      if grep -q "\"$dep\"" "$PKG"; then
        if grep -rq "from '$dep" "$SRC" 2>/dev/null || grep -rq "from \"$dep" "$SRC" 2>/dev/null; then
          pass "$dep declared and imported ✓"
        else
          warn "$dep declared in package.json but never imported — wire it or drop it"
        fi
      fi
    done
    # Vault is local-class: never a PEM entity, never a sync scope (LFS-INV-4).
    if grep -rqE "registerEntityTransport\((['\"])[^'\"]*[Vv]ault|_vault_state" --include='*.ts' "$SRC/features/entities" 2>/dev/null; then
      fail "vault table wired into the entity/sync layer — local-class data never server-syncs"
    else
      pass "vault stays out of the entity/sync layer ✓"
    fi
    # A chat feature needs its client-RAG vector surface (C-123).
    if [[ -d "$SRC/features/chat" ]]; then
      if grep -q '"@electric-sql/pglite-pgvector"' "$PKG"; then
        pass "chat feature has the pgvector surface ✓"
      else
        warn "chat feature present but @electric-sql/pglite-pgvector missing — client RAG has no vector store"
      fi
    fi
  else
    fail "package.json not found"
  fi

  echo ""
  echo -e "${CYAN}[02] Feature-based clean architecture${NC}"
  if [[ -d "$SRC/features" ]]; then
    pass "features/ directory exists"
    for feature in "$SRC/features"/*/; do
      fname="$(basename "$feature")"
      # Skip empty scaffold placeholders (no .ts/.tsx yet) — an unimplemented
      # feature has no layers to violate. Layer rules apply once code lands.
      if ! find "$feature" -type f \( -name '*.ts' -o -name '*.tsx' \) 2>/dev/null | grep -q .; then
        warn "  $fname/ is an empty placeholder — skipped (add code to activate layer checks)"
        continue
      fi
      [[ -d "$feature/api" ]]        && pass "  $fname/api/" || warn "  $fname/api/ missing"
      [[ -d "$feature/stores" ]]     && pass "  $fname/stores/" || warn "  $fname/stores/ absent (valid for read-only view-model features)"
      [[ -d "$feature/entities" ]]   && pass "  $fname/entities/" || warn "  $fname/entities/ missing (normalized server/entity state)"
      [[ -d "$feature/hooks" ]]      && pass "  $fname/hooks/" || fail "  $fname/hooks/ MISSING — required for layer contract"
      if [[ -d "$feature/components" || -d "$feature/screens" ]]; then
        pass "  $fname/ visual surface present"
      else
        fail "  $fname/components/ or screens/ MISSING"
      fi
    done
  else
    fail "features/ directory MISSING"
  fi

  echo ""
  echo -e "${CYAN}[02b] Product UI contract${NC}"
  [[ -f "$ROOT/components.json" && -d "$SRC/components/ui" ]] && pass "shadcn/ui registry and primitives present" || fail "shadcn/ui is not initialized"
  if grep -r "AssistantRuntimeProvider\|useExternalStoreRuntime" "$SRC/features/chat" 2>/dev/null | grep -q . \
    && grep -r "@/components/assistant-ui/thread" "$SRC/features/chat" 2>/dev/null | grep -q .; then
    pass "Assistant UI runtime and thread are mounted"
  else
    fail "Assistant UI is installed but not mounted at the chat boundary"
  fi
  if grep -r "chat_conversations\|ConversationRecord" "$SRC/features" 2>/dev/null | grep -q . \
    && grep -r "useGraphStore\|useEntity" "$SRC/features/entities" 2>/dev/null | grep -q .; then
    pass "durable conversation entities use PEM + PGlite path"
  else
    fail "conversation persistence/PEM integration is incomplete"
  fi
  if grep -qi '"name"[[:space:]]*:[[:space:]]*"knowme-poc"' "$PKG" \
    || [[ -f "$ROOT/../docs/KnowMe.dc.html" ]]; then
    for destination in Home Chat Hands Memory Models Settings; do
      grep -r "['\"]$destination['\"]" "$SRC/app" 2>/dev/null | grep -q . \
        && pass "destination: $destination" || fail "destination $destination MISSING from KnowMe app shell"
    done
  else
    pass "KnowMe-specific six-destination check not applicable to generic scaffold"
  fi
  if rg -n -P '(?<![\\w-])border(?:-[trblxyse])?(?=\\s|\")|(?<![\\w-])shadow-(?!none)' \
      "$SRC/app" "$SRC/features" "$SRC/shared" --glob '*.tsx' --glob '*.css' 2>/dev/null | grep -q .; then
    fail "visible border/shadow utility found in product UI — Flat 2.0 requires background-only separation"
  else
    pass "Flat 2.0 product surfaces contain no visible border/shadow utilities"
  fi

  echo ""
  echo -e "${CYAN}[03] Layer contract enforcement${NC}"
  # Component→Hook→Store→[invoke]. Components must import ONLY hooks: no store
  # imports (matched by path, so an in-package import from '../stores/…' counts).
  if grep -rn "from '.*stores/\|from \"@/features/.*stores/" "$SRC/features" 2>/dev/null | grep -E "components/[^:]*\.tsx:" | grep -q .; then
    fail "Store imports found in component files — components must use hooks only"
    echo "    Violations:"
    grep -rn "from '.*stores/\|from \"@/features/.*stores/" "$SRC/features" 2>/dev/null | grep -E "components/[^:]*\.tsx:" | head -5 | sed 's/^/      /'
  else
    pass "No direct store imports in component files ✓"
  fi

  # invoke()/listen() are allowed ONLY in stores — never components, hooks, or
  # entity modules. Strip the grep path:line: prefix and drop // comments so the words
  # "invoke"/"listen" in prose (e.g. "no invoke() here") don't false-positive.
  ts_ipc_leak() {
    grep -rn "invoke(\|listen(" "$SRC/features" 2>/dev/null \
      | grep -E "/features/[^/]+/(components|hooks|entities)/[^:]*\.(ts|tsx):" \
      | sed -E 's/^([^:]+:[0-9]+):/\1@@/' \
      | grep -vE '@@[[:space:]]*//' \
      | sed -E 's/@@/: /'
  }
  if ts_ipc_leak | grep -q .; then
    fail "invoke()/listen() found outside stores — the only IPC layer is stores/"
    ts_ipc_leak | head -5 | sed 's/^/    /'
  else
    pass "No invoke()/listen() outside stores ✓"
  fi

  # Hooks should not call fetch() or API directly
  if grep -rn "await fetch(\|= fetch(" "$SRC/features" 2>/dev/null | grep -E "hooks/[^:]*\.(ts|tsx):" | grep -q .; then
    fail "fetch() found in hooks — calls to external APIs belong in stores or api/"
  else
    pass "No direct fetch() in hooks ✓"
  fi

  # No raw graph/SQL query strings outside stores — the intent surface (memory_search,
  # graph_expand) lives in Rust; the browser only runs its own local pglite in stores.
  if grep -rn "RELATE \|DEFINE INDEX\|DEFINE TABLE" "$SRC/features" 2>/dev/null | grep -E "(components|hooks|entities)/" | grep -q .; then
    fail "raw SurrealQL found outside stores — graph logic lives in Rust, not the UI"
  else
    pass "No raw SurrealQL outside stores ✓"
  fi

  echo ""
  echo -e "${CYAN}[04] Prometheus Entity Management usage${NC}"
  if grep -r "useEntities\|useEntityQuery\|useEntityMutation\|registerEntityTransport" "$SRC/features" 2>/dev/null | grep -q .; then
    pass "Prometheus Entity Management hooks/transports in use"
    if grep -r "useEntities\|useEntityQuery\|useEntityMutation" "$SRC/features" 2>/dev/null | grep -E "components/.*\.tsx:" | grep -q .; then
      fail "Entity-management hooks found in component files — compose them through feature hooks"
    fi
  else
    warn "No Prometheus Entity Management hooks found — required for server/async/entity state"
  fi

  echo ""
  echo -e "${CYAN}[05] Tauri IPC bridge${NC}"
  if [[ -f "$SRC/bridge/a2ui/types.ts" ]]; then
    pass "bridge/a2ui/types.ts present"
  else
    warn "bridge/a2ui/types.ts not found — required for A2UI streaming"
  fi
  if grep -r "listen(\|onChatEvent" "$SRC" 2>/dev/null | grep -v "node_modules" | grep -q "a2ui_event\|onChatEvent"; then
    pass "a2ui_event listener wired"
  else
    warn "a2ui_event listener not found — wire in store init"
  fi

  echo ""
  echo -e "${CYAN}[06] KnowMe-slice features present${NC}"
  # Same vertical slice as Flutter: chat, entity CRUD, memory/graph-RAG, startup.
  for f in chat entities memory startup; do
    [[ -d "$SRC/features/$f" ]] && pass "features/$f/" || fail "features/$f/ MISSING — KnowMe-slice seam unproven"
  done
  # memory/startup stores must be the invoke layer (already checked in [03]);
  # confirm they actually reach the FFI so the seam is real, not a stub-only dir.
  if grep -rn "invoke(" "$SRC/features/memory" "$SRC/features/startup" 2>/dev/null | grep -E "stores/" | grep -q .; then
    pass "memory/startup stores reach the FFI (invoke in stores) ✓"
  else
    warn "memory/startup stores do not call invoke — seam may be stub-only"
  fi

# ── Rust audit ─────────────────────────────────────────────────────────────
elif [[ "$PLATFORM" == "rust" ]]; then
  [[ -d "$ROOT/src" ]] || { echo "Error: $ROOT/src not found"; exit 1; }

  echo -e "${CYAN}[01] Module structure${NC}"
  for mod in api api_http runtime streaming config protocol agent inference mcp db; do
    if [[ -f "$ROOT/src/$mod.rs" ]] || [[ -d "$ROOT/src/$mod" ]]; then
      pass "$mod module present"
    else
      warn "$mod module missing"
    fi
  done

  echo ""
  echo -e "${CYAN}[02] Runtime invariants${NC}"
  if grep -q "OnceLock\|once_cell" "$ROOT/src/runtime.rs" 2>/dev/null; then
    pass "Global runtime uses OnceLock singleton pattern"
  else
    warn "Runtime singleton pattern not detected"
  fi
  if grep -r "tokio::runtime::Builder::new_multi_thread" "$ROOT/src" 2>/dev/null | grep -q .; then
    pass "Multi-thread Tokio runtime configured"
  else
    warn "Multi-thread runtime not found"
  fi
  if grep -r "spawn_blocking" "$ROOT/src" 2>/dev/null | grep -q .; then
    pass "spawn_blocking used for CPU-bound work"
  else
    warn "No spawn_blocking found — ensure inference uses blocking pool"
  fi

  echo ""
  echo -e "${CYAN}[03] Protocol pipeline${NC}"
  [[ -f "$ROOT/src/protocol/a2ui.rs" ]] && pass "A2UI adapter present" || fail "A2UI adapter MISSING"
  [[ -f "$ROOT/src/protocol/agui.rs" ]] && pass "AG-UI adapter present" || fail "AG-UI adapter MISSING"
  grep -q "broadcast::channel\|broadcast::Sender" "$ROOT/src/protocol/mod.rs" 2>/dev/null && pass "Broadcast channels in pipeline" || warn "Broadcast channels not found in protocol/mod.rs"

  echo ""
  echo -e "${CYAN}[04] Build targets${NC}"
  grep -q "cdylib\|staticlib" "$ROOT/Cargo.toml" 2>/dev/null && pass "Both cdylib and staticlib crate-types present" || warn "Check crate-type = [\"cdylib\", \"staticlib\"]"

# ── Doc-consistency audit ──────────────────────────────────────────────────
# The pack's product is authoritative instruction to agents: divergent authority
# docs are defects (assessment 2026-07-16 §5). versions.toml is the single
# source of truth; this mode fails on any stale version/engine string in the
# authority docs. Paths resolve relative to the SCRIPT (the pack repo), not the
# audited project — scaffolded projects without these docs skip cleanly.
elif [[ "$PLATFORM" == "doc-consistency" ]]; then
  PACK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  VERSIONS="$PACK_ROOT/versions.toml"

  echo -e "${CYAN}[01] Single source of truth${NC}"
  if [[ -f "$VERSIONS" ]]; then
    pass "versions.toml present at pack root"
  else
    fail "versions.toml MISSING — authority docs have no source of truth"
  fi

  # Authority docs subject to the drift gate. wasm-targets.md is excluded: it is
  # a bannered historical finding that legitimately quotes superseded versions.
  AUTHORITY_DOCS=()
  for doc in SKILL.md CLAUDE.md AGENTS.md README.md; do
    [[ -f "$PACK_ROOT/$doc" ]] && AUTHORITY_DOCS+=("$PACK_ROOT/$doc")
  done
  while IFS= read -r -d '' ref; do
    [[ "$ref" == *"wasm-targets.md" ]] && continue
    AUTHORITY_DOCS+=("$ref")
  done < <(find "$PACK_ROOT/references" -name '*.md' -print0 2>/dev/null)

  if [[ ${#AUTHORITY_DOCS[@]} -eq 0 ]]; then
    warn "No authority docs found relative to the script — skipping (scaffolded project?)"
  else
    echo ""
    echo -e "${CYAN}[02] Stale version strings${NC}"
    # pattern|human label — each is a value versions.toml has superseded.
    STALE_CHECKS=(
      '1\.80\+|Rust 1.80+ (now 1.96+)'
      '1\.95\+|Rust 1.95+ (now 1.96+)'
      'Node\.js[^0-9]*22|Node 22 (now 24+)'
      '22\+ LTS|Node 22+ LTS (now 24+)'
      'Riverpod 2\.[x6]|Riverpod 2.x/2.6 (now 3.3)'
      '2\.3\+.*flutter_rust_bridge|flutter_rust_bridge_codegen.*2\.3\+|frb 2.3+ (now 2.12+)'
      'Vite 7|Vite 7 (now 8)'
      '"vite": "\^7|vite ^7 dep pin (now ^8)'
      'Flutter (SDK \| )?3\.29\+|Flutter 3.29+ (now beta channel)'
    )
    for entry in "${STALE_CHECKS[@]}"; do
      pattern="${entry%|*}"; label="${entry##*|}"
      hits=$(grep -lE "$pattern" "${AUTHORITY_DOCS[@]}" 2>/dev/null || true)
      if [[ -n "$hits" ]]; then
        fail "Stale: $label — in: $(echo "$hits" | xargs -n1 basename | tr '\n' ' ')"
      else
        pass "No stale '$label' strings"
      fi
    done

    echo ""
    echo -e "${CYAN}[03] Inference-engine authority${NC}"
    # Per-lane engines (versions.toml [inference]): desktop/mobile=llama-cpp-2,
    # web=WebLLM, mistral.rs optional. 'candle' as a current-engine claim is stale.
    hits=$(grep -lE 'candle' "${AUTHORITY_DOCS[@]}" 2>/dev/null || true)
    if [[ -n "$hits" ]]; then
      fail "Stale 'candle' engine references — in: $(echo "$hits" | xargs -n1 basename | tr '\n' ' ')"
    else
      pass "No stale candle engine references"
    fi
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "  Audit complete — $PLATFORM"
echo -e "  ${GREEN}PASS: $PASS_COUNT${NC}  ${YELLOW}WARN: $WARN_COUNT${NC}  ${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""

if [[ $VIOLATIONS -gt 0 ]]; then
  echo -e "${RED}  ✗ $VIOLATIONS violation(s) found — fix before merging${NC}"
  echo ""
  exit 1
else
  echo -e "${GREEN}  ✓ No violations — compliant with TJ-ARCH-MOB-001${NC}"
  echo ""
fi
