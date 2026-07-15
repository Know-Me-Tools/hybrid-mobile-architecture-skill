#!/usr/bin/env bash
# scripts/scaffold-packages.sh
# C-007: publishing scaffolds — npm + pub.dev package skeletons for the shared
# ContentBlock UI + leaf bindings. These are PUBLISHABLE library skeletons
# (crates.io/pub.dev/npm), structured for publication from day one per CLAUDE.md.
#
# Usage: bash scripts/scaffold-packages.sh <project-root>
#
# Emits, relative to <project-root>:
#   packages/gen-ui-react/                  @prometheus-ags/gen-ui-react (npm)
#   packages/gen-ui-wasm/                   @prometheus-ags/gen-ui-wasm  (npm)
#   rust/crates/tauri-plugin-gen-ui/guest-js/   @prometheus-ags/tauri-plugin-gen-ui (npm guest bindings)
#   flutter_packages/gen_ui_flutter/        gen_ui_flutter (pub.dev, FFI plugin)
#   flutter_packages/gen_ui_widgets/        gen_ui_widgets (pub.dev, ContentBlock widgets)
#
# ContentBlock contract (FROZEN in gen_ui_types, 11 variants): text, thinking,
# code, citation, memory, toolUse, toolResult, skill, artifact, image, divider.
# The React switch and the Flutter switch below are EXHAUSTIVE over these — adding
# a variant is a compile error on both sides by design.
set -euo pipefail

ROOT="${1:-.}"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }

TS_MARK="// TJ-ARCH-MOB-001 compliant"
DART_MARK="// TJ-ARCH-MOB-001 compliant"

step "Scaffolding publishable packages under $ROOT"

# ═══════════════════════════════════════════════════════════════════════════
# @prometheus-ags/gen-ui-react — ContentBlock React 19 components (npm)
# ═══════════════════════════════════════════════════════════════════════════
REACT_DIR="$ROOT/packages/gen-ui-react"
mkdir -p "$REACT_DIR/src"

cat > "$REACT_DIR/package.json" << 'EOF'
{
  "name": "@prometheus-ags/gen-ui-react",
  "version": "0.1.0",
  "description": "ContentBlock React 19 components for the TJ-ARCH-MOB-001 hybrid architecture. Used in Tauri desktop, plain web, and Flutter webview embeds.",
  "license": "MIT OR Apache-2.0",
  "type": "module",
  "main": "./dist/index.js",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "files": ["dist", "src"],
  "sideEffects": false,
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "typecheck": "tsc --noEmit"
  },
  "peerDependencies": {
    "react": "^19.0.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "typescript": "^5.6.0"
  },
  "publishConfig": {
    "access": "public"
  }
}
EOF

cat > "$REACT_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "declaration": true,
    "outDir": "dist",
    "rootDir": "src",
    "skipLibCheck": true
  },
  "include": ["src"]
}
EOF

# ContentBlock discriminated union — mirrors the Rust serde(tag="type",
# rename_all="camelCase") shape exactly.
cat > "$REACT_DIR/src/content-block.ts" << EOF
$TS_MARK
// ContentBlock — the cross-platform UI contract, mirrored from gen_ui_types
// (Rust). serde emits { type: "text", text: "..." } etc (tag="type", camelCase).
// Keep in lockstep with crates/gen_ui_types/src/content_block.rs.

export type ContentBlock =
  | { type: "text"; text: string }
  | { type: "thinking"; text: string }
  | { type: "code"; language: string; code: string }
  | { type: "citation"; source: string; quote: string }
  | { type: "memory"; operation: string; key: string; value: string | null }
  | { type: "toolUse"; id: string; name: string; inputJson: string }
  | { type: "toolResult"; toolUseId: string; outputJson: string; isError: boolean }
  | { type: "skill"; name: string; status: string }
  | { type: "artifact"; id: string; kind: string; content: string }
  | { type: "image"; url: string | null; dataBase64: string | null; mime: string }
  | { type: "divider" };
EOF

# Exhaustive renderer switch. \`assertNever\` makes a missing variant a TS compile
# error — the same exhaustiveness guarantee the Rust match site has.
cat > "$REACT_DIR/src/ContentBlockView.tsx" << EOF
$TS_MARK
import type { ContentBlock } from "./content-block";

function assertNever(x: never): never {
  throw new Error("unhandled ContentBlock variant: " + JSON.stringify(x));
}

export interface ContentBlockViewProps {
  block: ContentBlock;
}

/**
 * Renders one ContentBlock. Exhaustive over all 11 variants — adding a variant to
 * the union without a case here is a TypeScript compile error (assertNever).
 * Styling is intentionally minimal/token-driven; consuming apps theme via shadcn
 * CSS vars. This is the presentational layer (no data fetching, no invoke()).
 */
export function ContentBlockView({ block }: ContentBlockViewProps) {
  switch (block.type) {
    case "text":
      return <p className="gen-ui-text">{block.text}</p>;
    case "thinking":
      return <p className="gen-ui-thinking" data-role="thinking">{block.text}</p>;
    case "code":
      return (
        <pre className="gen-ui-code" data-lang={block.language}>
          <code>{block.code}</code>
        </pre>
      );
    case "citation":
      return (
        <blockquote className="gen-ui-citation" cite={block.source}>
          {block.quote}
        </blockquote>
      );
    case "memory":
      return (
        <div className="gen-ui-memory" data-op={block.operation}>
          <span className="gen-ui-memory-key">{block.key}</span>
          {block.value !== null ? <span className="gen-ui-memory-value">{block.value}</span> : null}
        </div>
      );
    case "toolUse":
      return (
        <div className="gen-ui-tool-use" data-tool={block.name} data-id={block.id}>
          {block.name}
        </div>
      );
    case "toolResult":
      return (
        <div className="gen-ui-tool-result" data-error={block.isError} data-tool-use-id={block.toolUseId}>
          {block.outputJson}
        </div>
      );
    case "skill":
      return (
        <div className="gen-ui-skill" data-status={block.status}>
          {block.name}
        </div>
      );
    case "artifact":
      return (
        <div className="gen-ui-artifact" data-kind={block.kind} data-id={block.id}>
          {block.content}
        </div>
      );
    case "image":
      return (
        <img
          className="gen-ui-image"
          alt=""
          src={block.url ?? (block.dataBase64 ? \`data:\${block.mime};base64,\${block.dataBase64}\` : undefined)}
        />
      );
    case "divider":
      return <hr className="gen-ui-divider" />;
    default:
      return assertNever(block);
  }
}
EOF

cat > "$REACT_DIR/src/index.ts" << EOF
$TS_MARK
export type { ContentBlock } from "./content-block";
export { ContentBlockView } from "./ContentBlockView";
export type { ContentBlockViewProps } from "./ContentBlockView";
EOF

cat > "$REACT_DIR/README.md" << 'EOF'
# @prometheus-ags/gen-ui-react

ContentBlock React 19 components for the TJ-ARCH-MOB-001 hybrid architecture.

`ContentBlockView` renders one `ContentBlock` — the cross-platform UI contract
produced by the shared Rust core (`gen_ui_core`). The type mirrors
`gen_ui_types::ContentBlock` exactly; the render switch is exhaustive over all 11
variants (a missing case is a TypeScript compile error).

Presentational only: no data fetching, no `invoke()`. Feed it blocks from a
Zustand store that owns the stream subscription.

```tsx
import { ContentBlockView, type ContentBlock } from "@prometheus-ags/gen-ui-react";

function Transcript({ blocks }: { blocks: ContentBlock[] }) {
  return <>{blocks.map((b, i) => <ContentBlockView key={i} block={b} />)}</>;
}
```
EOF
ok "npm: @prometheus-ags/gen-ui-react (ContentBlock components, exhaustive switch)"

# ═══════════════════════════════════════════════════════════════════════════
# @prometheus-ags/gen-ui-wasm — npm wrapper around wasm-pack output
# ═══════════════════════════════════════════════════════════════════════════
WASM_PKG_DIR="$ROOT/packages/gen-ui-wasm"
mkdir -p "$WASM_PKG_DIR/src"

cat > "$WASM_PKG_DIR/package.json" << 'EOF'
{
  "name": "@prometheus-ags/gen-ui-wasm",
  "version": "0.1.0",
  "description": "Web/WASM surface of gen_ui_core — shared protocol adapters (A2UI ContentBlock folding) compiled to WebAssembly.",
  "license": "MIT OR Apache-2.0",
  "type": "module",
  "main": "./src/index.js",
  "types": "./src/index.d.ts",
  "exports": {
    ".": {
      "types": "./src/index.d.ts",
      "import": "./src/index.js"
    }
  },
  "files": ["src", "pkg"],
  "sideEffects": ["./pkg/*"],
  "scripts": {
    "build:wasm": "bash ../../rust/crates/gen_ui_wasm/build-wasm.sh ../../packages/gen-ui-wasm/pkg",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "typescript": "^5.6.0"
  },
  "publishConfig": {
    "access": "public"
  }
}
EOF

# Thin re-export around the wasm-pack pkg/ output. \`build:wasm\` populates pkg/.
cat > "$WASM_PKG_DIR/src/index.ts" << EOF
$TS_MARK
// Re-export the wasm-pack bundler output. Populate pkg/ first:
//   npm run build:wasm   (runs rust/crates/gen_ui_wasm/build-wasm.sh)
// The generated pkg/ carries its own .d.ts; this wrapper gives a stable package
// name + a place to add JS-side ergonomics later.
export * from "../pkg/gen_ui_wasm";
EOF

cat > "$WASM_PKG_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "declaration": true,
    "outDir": "dist",
    "skipLibCheck": true,
    "allowJs": true
  },
  "include": ["src"]
}
EOF

cat > "$WASM_PKG_DIR/README.md" << 'EOF'
# @prometheus-ags/gen-ui-wasm

The web/WASM surface of `gen_ui_core`. It exposes the shared `gen_ui_protocol`
adapters — so a browser app folds an A2UI event stream into `ContentBlock`s with
the exact same Rust logic the native surfaces use (no re-implementing protocol
logic in TypeScript).

## Build

```bash
npm run build:wasm   # wasm-pack (bundler) + wasm-opt -Oz -> ./pkg
```

## Use (with @prometheus-ags/gen-ui-react)

```ts
import init, { WasmA2uiAdapter } from "@prometheus-ags/gen-ui-wasm";
await init();
const adapter = new WasmA2uiAdapter("run-123");
const a2uiEvents = adapter.ingest({ type: "text_delta", index: 0, delta: "hi" });
```
EOF
ok "npm: @prometheus-ags/gen-ui-wasm (wasm-pack wrapper)"

# ═══════════════════════════════════════════════════════════════════════════
# @prometheus-ags/tauri-plugin-gen-ui — guest-js bindings (npm)
# ═══════════════════════════════════════════════════════════════════════════
GUEST_DIR="$ROOT/rust/crates/tauri-plugin-gen-ui/guest-js"
mkdir -p "$GUEST_DIR"

cat > "$GUEST_DIR/package.json" << 'EOF'
{
  "name": "@prometheus-ags/tauri-plugin-gen-ui",
  "version": "0.1.0",
  "description": "Guest-JS bindings for tauri-plugin-gen-ui: typed invoke() wrappers + event listeners for the gen_ui_core intent surface.",
  "license": "MIT OR Apache-2.0",
  "type": "module",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@tauri-apps/api": "^2.0.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0"
  },
  "publishConfig": {
    "access": "public"
  }
}
EOF

cat > "$GUEST_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "declaration": true,
    "outDir": "dist",
    "rootDir": "src",
    "skipLibCheck": true
  },
  "include": ["src"]
}
EOF

mkdir -p "$GUEST_DIR/src"
# Typed invoke wrappers. LAYER CONTRACT: import these ONLY from Zustand stores.
cat > "$GUEST_DIR/src/index.ts" << EOF
$TS_MARK
// Guest bindings for tauri-plugin-gen-ui. Typed wrappers over the plugin's
// commands + typed listeners for its event channels.
//
// LAYER CONTRACT (TJ-ARCH-MOB-001): call these ONLY from Zustand stores — never
// from a React component or hook. Components import hooks; hooks compose stores;
// stores own invoke()/listen().
import { invoke } from "@tauri-apps/api/core";
import { listen, type UnlistenFn } from "@tauri-apps/api/event";

// Command names are prefixed by the plugin ("gen-ui") — Tauri maps them to
// "plugin:gen-ui|<command>".
const cmd = (name: string) => \`plugin:gen-ui|\${name}\`;

// --- Mirrored gen_ui_types shapes (kept in lockstep with the Rust seams) -----
export interface EntityRecord {
  id: string;
  entityType: string;
  dataJson: string;
}
export interface ListResult {
  items: EntityRecord[];
  nextCursor: string | null;
}
export type FilterOp = "eq" | "ne" | "lt" | "lte" | "gt" | "gte" | "in" | "like";
export interface FilterSpec {
  field: string;
  op: FilterOp;
  valueJson: string;
}
export interface SortSpec {
  field: string;
  descending: boolean;
}
export interface ViewDescriptor {
  entityType: string;
  filters: FilterSpec[];
  sorts: SortSpec[];
  limit: number | null;
  cursor: string | null;
}

// --- Command wrappers --------------------------------------------------------
export function chatSend(threadId: string, message: string): Promise<string> {
  return invoke<string>(cmd("chat_send"), { threadId, message });
}
export function entityList(view: ViewDescriptor): Promise<ListResult> {
  return invoke<ListResult>(cmd("entity_list"), { view });
}
export function entityGet(entityType: string, id: string): Promise<EntityRecord | null> {
  return invoke<EntityRecord | null>(cmd("entity_get"), { entityType, id });
}
export function entityCreate(record: EntityRecord): Promise<EntityRecord> {
  return invoke<EntityRecord>(cmd("entity_create"), { record });
}
export function entityUpdate(record: EntityRecord): Promise<EntityRecord> {
  return invoke<EntityRecord>(cmd("entity_update"), { record });
}
export function entityDelete(entityType: string, id: string): Promise<void> {
  return invoke<void>(cmd("entity_delete"), { entityType, id });
}
export function memorySearch(query: string, k: number): Promise<string[]> {
  return invoke<string[]>(cmd("memory_search"), { query, k });
}
export function graphExpand(entityId: string, depth: number): Promise<string[]> {
  return invoke<string[]>(cmd("graph_expand"), { entityId, depth });
}

// --- Event channels (mirror gen_ui_ffi StreamSink feeds) ---------------------
export const CHAT_EVENT = "gen-ui://chat-event";
export const ENTITY_CHANGE = "gen-ui://entity-change";
export const SYNC_STATUS = "gen-ui://sync-status";

export function onChatEvent<T>(handler: (payload: T) => void): Promise<UnlistenFn> {
  return listen<T>(CHAT_EVENT, (e) => handler(e.payload));
}
export function onEntityChange<T>(handler: (payload: T) => void): Promise<UnlistenFn> {
  return listen<T>(ENTITY_CHANGE, (e) => handler(e.payload));
}
export function onSyncStatus<T>(handler: (payload: T) => void): Promise<UnlistenFn> {
  return listen<T>(SYNC_STATUS, (e) => handler(e.payload));
}
EOF

cat > "$GUEST_DIR/README.md" << 'EOF'
# @prometheus-ags/tauri-plugin-gen-ui

Guest-JS bindings for `tauri-plugin-gen-ui`. Typed `invoke()` wrappers + event
listeners for the `gen_ui_core` intent surface (chat, entity CRUD, memory/graph).

**Layer contract (TJ-ARCH-MOB-001):** import these only from Zustand stores —
never from a React component or hook.
EOF
ok "npm: @prometheus-ags/tauri-plugin-gen-ui (guest-js bindings)"

# ═══════════════════════════════════════════════════════════════════════════
# gen_ui_flutter — pub.dev FFI plugin package
# ═══════════════════════════════════════════════════════════════════════════
FLUTTER_FFI="$ROOT/flutter_packages/gen_ui_flutter"
mkdir -p "$FLUTTER_FFI/lib/src"

cat > "$FLUTTER_FFI/pubspec.yaml" << 'EOF'
# TJ-ARCH-MOB-001 compliant
name: gen_ui_flutter
description: Flutter FFI plugin exposing gen_ui_core (Rust) via flutter_rust_bridge — chat, entity CRUD, memory/graph-RAG intents + ContentBlock streams.
version: 0.1.0
publish_to: none # set to https://pub.dev when ready to publish
environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.29.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_rust_bridge: ^2.12.0

dev_dependencies:
  flutter_lints: ^5.0.0

flutter:
  plugin:
    platforms:
      android:
        ffiPlugin: true
      ios:
        ffiPlugin: true
      macos:
        ffiPlugin: true
EOF

cat > "$FLUTTER_FFI/lib/gen_ui_flutter.dart" << EOF
$DART_MARK
/// gen_ui_flutter — public surface. Re-exports the flutter_rust_bridge generated
/// bindings (chat/entity/memory intents + ContentBlock event streams) plus the
/// init helper. The generated code lives in the host app's lib/bridge (produced
/// by \`flutter_rust_bridge_codegen generate\`); this package wraps the ergonomics.
library;

export 'src/gen_ui.dart';
EOF

cat > "$FLUTTER_FFI/lib/src/gen_ui.dart" << EOF
$DART_MARK
/// Entry point + re-export shim for the generated bridge.
///
/// The frb-generated \`GenUiCore\` class (see rust/flutter_rust_bridge.yaml,
/// dart_entrypoint_class_name) is produced into the host app. Riverpod providers
/// wrap the async intent calls; FFI providers MUST opt out of Riverpod 3 auto-retry
/// (retry: (_, __) => null) so Rust Terminal errors aren't silently re-invoked.
///
/// Intent surface (mirrors crates/gen_ui_ffi/src/api):
///   * initCore(workerThreads)            — call once at startup
///   * chatSend(threadId, message) -> runId
///   * chatEvents(runId)     -> \`Stream<A2uiEvent>\`   (fold into ContentBlocks)
///   * entityList/Get/Create/Update/Delete
///   * entityChanges()       -> \`Stream<ChangeEvent>\` (bridge to ref.invalidate)
///   * syncStatus()          -> \`Stream<SyncStatus>\`  (drive the sync chip)
///   * memorySearch(query, k) / graphExpand(entityId, depth)
///
/// This file is intentionally a documentation + re-export seam: the concrete
/// bindings are generated, and the example app (C-010) wires the providers.
class GenUiFlutter {
  const GenUiFlutter._();
}
EOF

cat > "$FLUTTER_FFI/analysis_options.yaml" << 'EOF'
include: package:flutter_lints/flutter.yaml
EOF

cat > "$FLUTTER_FFI/README.md" << 'EOF'
# gen_ui_flutter

Flutter FFI plugin exposing `gen_ui_core` (Rust) via `flutter_rust_bridge` 2.12.

All networking, inference, MCP, persistence and agent logic lives in Rust
(`gen_ui_core`) — this plugin is the thin FFI surface. Never re-implement core
logic in Dart.

Generate bindings from the hybrid project root:

```bash
flutter_rust_bridge_codegen generate --config-file rust/flutter_rust_bridge.yaml
```

Wrap the async intent calls in Riverpod providers, and **opt FFI providers out of
Riverpod 3 automatic retry** (`retry: (_, __) => null`).
EOF
ok "pub.dev: gen_ui_flutter (FFI plugin skeleton)"

# ═══════════════════════════════════════════════════════════════════════════
# gen_ui_widgets — pub.dev ContentBlock widget set
# ═══════════════════════════════════════════════════════════════════════════
FLUTTER_WIDGETS="$ROOT/flutter_packages/gen_ui_widgets"
mkdir -p "$FLUTTER_WIDGETS/lib/src"

cat > "$FLUTTER_WIDGETS/pubspec.yaml" << 'EOF'
# TJ-ARCH-MOB-001 compliant
name: gen_ui_widgets
description: ContentBlock widget set for gen_ui — an exhaustive Flutter renderer over the 11-variant ContentBlock contract (shadcn_flutter-compatible).
version: 0.1.0
publish_to: none # set to https://pub.dev when ready to publish
environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.29.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_lints: ^5.0.0
EOF

# The ContentBlock sealed class mirrors the Rust enum. In the real app these come
# from the frb-generated bindings (or a freezed mirror); here we define a minimal
# sealed hierarchy so the exhaustive switch compiles standalone and demonstrates
# the contract. C-010 swaps in the generated union.
cat > "$FLUTTER_WIDGETS/lib/src/content_block.dart" << EOF
$DART_MARK
/// ContentBlock — the cross-platform UI contract, mirrored from gen_ui_types.
/// In the host app this is the frb-generated union; this sealed hierarchy lets
/// the widget package compile and be tested standalone. Dart's exhaustive
/// switch on a sealed type is a compile error if a variant is unhandled — the
/// same guarantee the Rust match site has.
sealed class ContentBlock {
  const ContentBlock();
}

class TextBlock extends ContentBlock {
  final String text;
  const TextBlock(this.text);
}

class ThinkingBlock extends ContentBlock {
  final String text;
  const ThinkingBlock(this.text);
}

class CodeBlock extends ContentBlock {
  final String language;
  final String code;
  const CodeBlock(this.language, this.code);
}

class CitationBlock extends ContentBlock {
  final String source;
  final String quote;
  const CitationBlock(this.source, this.quote);
}

class MemoryBlock extends ContentBlock {
  final String operation;
  final String key;
  final String? value;
  const MemoryBlock(this.operation, this.key, this.value);
}

class ToolUseBlock extends ContentBlock {
  final String id;
  final String name;
  final String inputJson;
  const ToolUseBlock(this.id, this.name, this.inputJson);
}

class ToolResultBlock extends ContentBlock {
  final String toolUseId;
  final String outputJson;
  final bool isError;
  const ToolResultBlock(this.toolUseId, this.outputJson, this.isError);
}

class SkillBlock extends ContentBlock {
  final String name;
  final String status;
  const SkillBlock(this.name, this.status);
}

class ArtifactBlock extends ContentBlock {
  final String id;
  final String kind;
  final String content;
  const ArtifactBlock(this.id, this.kind, this.content);
}

class ImageBlock extends ContentBlock {
  final String? url;
  final String? dataBase64;
  final String mime;
  const ImageBlock(this.url, this.dataBase64, this.mime);
}

class DividerBlock extends ContentBlock {
  const DividerBlock();
}
EOF

cat > "$FLUTTER_WIDGETS/lib/src/content_block_view.dart" << EOF
$DART_MARK
import 'package:flutter/material.dart';
import 'content_block.dart';

/// Renders one ContentBlock. Exhaustive over all 11 variants: Dart's switch on a
/// sealed class is a compile error if a case is missing — no default branch.
/// Presentational only (no FFI calls, no providers). Feed it blocks a
/// ChatNotifier folded from the chatEvents stream.
class ContentBlockView extends StatelessWidget {
  final ContentBlock block;
  const ContentBlockView({required this.block, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (block) {
      TextBlock(:final text) => Text(text, style: theme.textTheme.bodyMedium),
      ThinkingBlock(:final text) => Opacity(
          opacity: 0.6,
          child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
        ),
      CodeBlock(:final language, :final code) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('[\$language]\n\$code', style: const TextStyle(fontFamily: 'monospace')),
        ),
      CitationBlock(:final source, :final quote) => Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quote, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              Text(source, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      MemoryBlock(:final key, :final value) => ListTile(
          dense: true,
          leading: const Icon(Icons.memory),
          title: Text(key),
          subtitle: value != null ? Text(value) : null,
        ),
      ToolUseBlock(:final name) => Chip(
          avatar: const Icon(Icons.build, size: 16),
          label: Text(name),
        ),
      ToolResultBlock(:final outputJson, :final isError) => Container(
          padding: const EdgeInsets.all(8),
          color: isError ? theme.colorScheme.errorContainer : theme.colorScheme.surfaceContainer,
          child: Text(outputJson),
        ),
      SkillBlock(:final name, :final status) => Chip(
          avatar: const Icon(Icons.extension, size: 16),
          label: Text('\$name · \$status'),
        ),
      ArtifactBlock(:final kind, :final content) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(kind, style: theme.textTheme.labelMedium), Text(content)],
            ),
          ),
        ),
      ImageBlock(:final url) => url != null
          ? Image.network(url)
          : const SizedBox.shrink(),
      DividerBlock() => const Divider(),
    };
  }
}
EOF

cat > "$FLUTTER_WIDGETS/lib/gen_ui_widgets.dart" << EOF
$DART_MARK
/// gen_ui_widgets — ContentBlock widget set for the TJ-ARCH-MOB-001 architecture.
library;

export 'src/content_block.dart';
export 'src/content_block_view.dart';
EOF

cat > "$FLUTTER_WIDGETS/analysis_options.yaml" << 'EOF'
include: package:flutter_lints/flutter.yaml
EOF

cat > "$FLUTTER_WIDGETS/README.md" << 'EOF'
# gen_ui_widgets

ContentBlock widget set for the TJ-ARCH-MOB-001 hybrid architecture. `ContentBlockView`
renders one `ContentBlock` — the cross-platform UI contract from the shared Rust
core. The render `switch` is exhaustive over all 11 variants; because `ContentBlock`
is a sealed class, a missing case is a Dart compile error (no default branch).

Presentational only — no FFI calls, no providers. Feed it blocks folded from the
`chatEvents` stream by a `ChatNotifier`.
EOF
ok "pub.dev: gen_ui_widgets (ContentBlock widgets, exhaustive sealed switch)"

echo ""
echo -e "${GREEN}✅ Publishable package skeletons scaffolded${NC}"
echo ""
echo "  npm:      packages/gen-ui-react · packages/gen-ui-wasm · rust/crates/tauri-plugin-gen-ui/guest-js"
echo "  pub.dev:  flutter_packages/gen_ui_flutter · flutter_packages/gen_ui_widgets"
echo ""
