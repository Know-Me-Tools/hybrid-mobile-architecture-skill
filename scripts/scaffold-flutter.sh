#!/usr/bin/env bash
# scripts/scaffold-flutter.sh — v2 (C-010)
# Scaffold a Flutter + Rust FFI mobile app: Riverpod 3.3.2, clean architecture,
# shadcn_flutter, wired to the three pub.dev packages (gen_ui_flutter FFI plugin,
# gen_ui_widgets ContentBlock set, prometheus_entity_management).
#
# Usage: bash scripts/scaffold-flutter.sh <output-dir> <app-name>
#
# The example app is a WORKING vertical slice (not stubs): a chat feature whose
# ChatNotifier folds the Rust A2uiEvent stream into ContentBlocks via
# A2uiContentDriver, a Mutations-API send flow, an entity-CRUD demo backed by
# prometheus_entity_management, and a sync-status chip driven by the Rust
# SyncStatus stream. Every FFI-backed provider opts out of Riverpod 3 auto-retry.
#
# Package deps resolve to ../flutter_packages/* (emitted by scaffold-packages.sh).
# In the hybrid flow those are scaffolded before pub get; standalone runs print
# the follow-up. Nothing here re-implements networking/inference/persistence in
# Dart — that all lives in gen_ui_core (Rust) behind the FFI seam.

set -euo pipefail

OUT="${1:-mobile}"
APP_NAME="${2:-my_app}"
SNAKE_NAME="$(echo "$APP_NAME" | tr '-' '_' | tr '[:upper:]' '[:lower:]')"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }

MARK="// TJ-ARCH-MOB-001 compliant"

step "Creating Flutter app: $APP_NAME"
flutter create \
  --org ai.prometheusags \
  --template app \
  --platforms ios,android,macos \
  --no-pub \
  "$OUT"

cd "$OUT"

# ── pubspec.yaml — Riverpod 3.3.2, frb 2.12, path-dep the three packages ─────
step "Writing pubspec.yaml (Riverpod 3.3.2 / frb 2.12)"
cat > pubspec.yaml << PUBEOF
name: ${SNAKE_NAME}
description: "${APP_NAME} — Hybrid mobile application (Prometheus AGS / TJ-ARCH-MOB-001)"
publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.29.0"

dependencies:
  flutter:
    sdk: flutter

  # ── Shared Prometheus packages (published to pub.dev; path deps in-repo) ──
  gen_ui_flutter:
    path: ../flutter_packages/gen_ui_flutter
  gen_ui_widgets:
    path: ../flutter_packages/gen_ui_widgets
  prometheus_entity_management:
    path: ../flutter_packages/prometheus_entity_management

  # ── State management (Riverpod 3) ────────────────────────────────────────
  flutter_riverpod: ^3.3.2
  riverpod_annotation: ^4.0.3
  riverpod_sqflite: ^0.2.0     # offline provider-cache persistence (Riverpod 3)

  # ── Models ───────────────────────────────────────────────────────────────
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # ── FFI bridge ───────────────────────────────────────────────────────────
  flutter_rust_bridge: ^2.12.0

  # ── UI components (shadcn/ui equivalent) ─────────────────────────────────
  shadcn_flutter: ^0.1.6

  # ── Navigation ───────────────────────────────────────────────────────────
  go_router: ^15.0.0

  # ── Markdown + code highlighting ─────────────────────────────────────────
  markdown_widget: ^2.3.2+6
  flutter_highlight: ^0.7.0
  highlight: ^0.7.0

  # ── Typography / motion ──────────────────────────────────────────────────
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0

  # ── Storage / auth ───────────────────────────────────────────────────────
  flutter_secure_storage: ^9.2.2
  supabase_flutter: ^2.8.0

  # ── Utilities ────────────────────────────────────────────────────────────
  gap: ^3.0.1
  uuid: ^4.5.1
  intl: ^0.19.0
  path_provider: ^2.1.4
  collection: ^1.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^4.0.4
  custom_lint: ^0.7.5
  riverpod_lint: ^4.0.0
  alchemist: ^0.12.0           # deterministic golden tests (VGV workflow) — no mocks

flutter:
  uses-material-design: true
PUBEOF
ok "pubspec.yaml"

# ── analysis_options.yaml ─────────────────────────────────────────────────
cat > analysis_options.yaml << 'EOF'
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "lib/bridge/generated_api.dart"
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_single_quotes: true
    avoid_print: true
    require_trailing_commas: true
    sort_pub_dependencies: false
EOF
ok "analysis_options.yaml"

# ── Directory structure (feature-based clean architecture) ─────────────────
step "Creating feature-based clean architecture"
mkdir -p lib/{app,core/{theme,errors,extensions},shared/{widgets,providers},bridge/{a2ui,agui}}
mkdir -p lib/features/chat/{data/{repositories,datasources,models},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}
mkdir -p lib/features/notes/{data,domain,presentation/{providers,screens}}
mkdir -p lib/features/memory/{data,domain/entities,presentation/{providers,screens}}
mkdir -p lib/features/startup/{data,domain,presentation/{providers,screens}}
mkdir -p test/features/chat test/features/notes test/features/memory test/features/startup

# ═══════════════════════════════════════════════════════════════════════════
# core/theme — design tokens
# ═══════════════════════════════════════════════════════════════════════════
cat > lib/core/theme/tokens.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// Design tokens — travisjames.ai brand system.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class T {
  // Backgrounds
  static const bgPrimary  = Color(0xFF0D0D18);
  static const bgSurface  = Color(0xFF121220);
  static const bgElevated = Color(0xFF181828);
  static const bgOverlay  = Color(0xFF1E1E35);

  // Accents
  static const ember   = Color(0xFFFF6A3D);
  static const violet  = Color(0xFF8B78FF);
  static const cyan    = Color(0xFF22D3EE);
  static const amber   = Color(0xFFF5A623);
  static const green   = Color(0xFF34D399);
  static const red     = Color(0xFFF87171);

  // Text
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9898C0);
  static const textTertiary  = Color(0xFF5E5E88);
  static const textDisabled  = Color(0xFF3A3A60);

  // Typography
  static TextStyle get displayLg => GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.03, color: textPrimary);
  static TextStyle get uiMd      => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary);
  static TextStyle get prose     => GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.75);
  static TextStyle get mono      => GoogleFonts.jetBrainsMono(fontSize: 12.5, fontWeight: FontWeight.w400, color: textPrimary, height: 1.55);
}
EOF
ok "lib/core/theme/tokens.dart"

# ═══════════════════════════════════════════════════════════════════════════
# bridge/ — the FFI seam. All three pieces below are the ONLY places that touch
# the frb-generated bindings. Everything above them is pure Dart + Riverpod.
# ═══════════════════════════════════════════════════════════════════════════

# rust_bridge_provider.dart — init + intent surface facade.
# After `flutter_rust_bridge_codegen generate`, replace the stub bodies with
# calls into generated_api.dart. Names mirror crates/gen_ui_ffi/src/api.
cat > lib/bridge/rust_bridge_provider.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// The FFI facade. Every call here delegates to gen_ui_core (Rust). After running
// `flutter_rust_bridge_codegen generate --config-file rust/flutter_rust_bridge.yaml`
// replace the stub bodies with the generated bindings — the signatures already
// match the Rust api surface (chat_send, chat_events, entity_*, sync_status).
//
// Do NOT add networking, inference, or persistence logic here. This file is a
// pass-through to Rust; business logic living in Dart violates the architecture.
import 'dart:async';

import 'a2ui/a2ui_event.dart';
import 'package:prometheus_entity_management/prometheus_entity_management.dart';

// import 'generated_api.dart' as ffi; // uncomment after codegen

Future<void> initRustBridge({String? dataDir}) async {
  // await ffi.initCore(workerThreads: null, dataDir: dataDir);
}

Future<void> setApiKey(String key) async {
  // await ffi.setApiKey(key: key);
}

/// chat_send(thread_id, message) -> run_id. FFI call; terminal on Rust error.
Future<String> chatSend(String threadId, String message) async {
  // return await ffi.chatSend(threadId: threadId, message: message);
  throw UnimplementedError('run flutter_rust_bridge_codegen generate');
}

/// chat_events(run_id) -> Stream<A2uiEvent>. Fold into ContentBlocks.
Stream<A2uiEvent> chatEvents(String runId) {
  // return ffi.chatEvents(runId: runId).map(A2uiEvent.fromWire);
  return const Stream.empty();
}

/// entity_changes() -> Stream<ChangeEvent>. Bridged to ref.invalidate by PEM.
Stream<ChangeEvent> entityChanges() {
  // return ffi.entityChanges().map((w) => ChangeEvent.fromJson(w));
  return const Stream.empty();
}

/// sync_status() -> Stream<SyncStatus>. Drives the sync chip.
Stream<SyncStatus> syncStatus() {
  // return ffi.syncStatus().map(SyncStatus.fromWire);
  return Stream.value(const SyncStatus.offline());
}

// ── Entity transport intents (wired into PEM's EntityTransport adapter) ──────
Future<ListResult> entityList(ViewDescriptor view) async =>
    throw UnimplementedError('run flutter_rust_bridge_codegen generate');
Future<EntityRecord?> entityGet(String entityType, String id) async =>
    throw UnimplementedError('run flutter_rust_bridge_codegen generate');
Future<EntityRecord> entityCreate(EntityRecord record) async =>
    throw UnimplementedError('run flutter_rust_bridge_codegen generate');
Future<EntityRecord> entityUpdate(EntityRecord record) async =>
    throw UnimplementedError('run flutter_rust_bridge_codegen generate');
Future<void> entityDelete(String entityType, String id) async =>
    throw UnimplementedError('run flutter_rust_bridge_codegen generate');

// ── Memory / graph-RAG intents (gen_ui_db::graph — never raw SurrealQL in Dart) ─
// memory_search / memory_ingest / graph_expand are the ONLY graph surface the UI
// sees. Fusion (vector recall → graph expansion → BM25 → RRF) happens in Rust.

/// memory_ingest(text) -> id. Embeds on-device (fastembed) + upserts in Rust.
Future<String> memoryIngest(String text) async {
  // return await ffi.memoryIngest(text: text);
  throw UnimplementedError('run flutter_rust_bridge_codegen generate');
}

/// memory_search(query, k) -> ranked hits (hybrid vector+graph+BM25 fusion).
Future<List<MemoryHit>> memorySearch(String query, int k) async {
  // return await ffi.memorySearch(query: query, k: k);
  throw UnimplementedError('run flutter_rust_bridge_codegen generate');
}

/// graph_expand(entity_id, depth) -> neighbourhood hits (recursive RELATE walk).
Future<List<MemoryHit>> graphExpand(String entityId, int depth) async {
  // return await ffi.graphExpand(entityId: entityId, depth: depth);
  throw UnimplementedError('run flutter_rust_bridge_codegen generate');
}

/// MemoryHit — Dart mirror of gen_ui_db::graph::EntityHit. `score` is the fused
/// RRF rank; `snippet` is the BM25/context excerpt. In the built app this is the
/// frb-generated type; this plain class lets the memory feature compile/run
/// standalone. serde snake_case at the wire.
class MemoryHit {
  const MemoryHit({
    required this.id,
    required this.name,
    required this.score,
    this.snippet,
  });

  final String id;
  final String name;
  final double score;
  final String? snippet;
}

// ── Startup orchestrator intents (gen_ui_db startup — analysis §1.8) ─────────
// Boot-order invariant: migrations → seeds → shapes. Each step runs in Rust;
// the startup feature sequences these in order and gates the app until ready.

/// run_migrations() — apply the additive schema migration set for this dialect.
Future<void> runMigrations() async {
  // await ffi.runMigrations();
  throw UnimplementedError('run flutter_rust_bridge_codegen generate');
}

/// load_seeds() — copy bundled seed/lookup data on first run (idempotent).
Future<void> loadSeeds() async {
  // await ffi.loadSeeds();
  throw UnimplementedError('run flutter_rust_bridge_codegen generate');
}

/// attach_sync_shapes() — subscribe Electric shapes AFTER migrations+seeds
/// (shapes fail on unknown columns, so this must run last).
Future<void> attachSyncShapes() async {
  // await ffi.attachSyncShapes();
  throw UnimplementedError('run flutter_rust_bridge_codegen generate');
}
EOF
ok "lib/bridge/rust_bridge_provider.dart"

# a2ui/a2ui_event.dart — Dart mirror of gen_ui_types A2uiEvent (frb swaps in the
# generated union at codegen time). Sealed so folding is exhaustive.
cat > lib/bridge/a2ui/a2ui_event.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// A2uiEvent — Dart mirror of gen_ui_types::events::A2uiEvent. In the built app
// this is the frb-generated union; this sealed hierarchy lets the chat feature
// and its tests compile/run standalone. serde tag = "type", snake_case.
import 'package:gen_ui_widgets/gen_ui_widgets.dart';

sealed class A2uiEvent {
  const A2uiEvent();
}

class RunStarted extends A2uiEvent {
  final String runId;
  const RunStarted(this.runId);
}

class BlockEvent extends A2uiEvent {
  final ContentBlock block;
  const BlockEvent(this.block);
}

class RunFinished extends A2uiEvent {
  final String runId;
  const RunFinished(this.runId);
}

class RunError extends A2uiEvent {
  final String message;
  const RunError(this.message);
}
EOF
ok "lib/bridge/a2ui/a2ui_event.dart"

# a2ui/a2ui_content_driver.dart — folds an A2uiEvent stream into ChatNotifier
# calls. Pure Dart, no FFI: it consumes whatever stream it's given.
cat > lib/bridge/a2ui/a2ui_content_driver.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// A2uiContentDriver — connects one run's A2uiEvent stream to a ChatNotifier.
// It appends ContentBlocks as Block events arrive and finalizes the message on
// RunFinished/RunError. No FFI here; feed it the stream from chatEvents().
import 'dart:async';

import 'package:gen_ui_widgets/gen_ui_widgets.dart';
import 'a2ui_event.dart';

class A2uiContentDriver {
  A2uiContentDriver({
    required this.messageId,
    required this.onBlock,
    required this.onFinalize,
    this.onError,
  });

  final String messageId;
  final void Function({required String messageId, required ContentBlock block}) onBlock;
  final void Function(String messageId) onFinalize;
  final void Function(String messageId, String message)? onError;

  StreamSubscription<A2uiEvent>? _sub;

  void connect(Stream<A2uiEvent> stream) {
    _sub = stream.listen((event) {
      switch (event) {
        case RunStarted():
          break;
        case BlockEvent(:final block):
          onBlock(messageId: messageId, block: block);
        case RunFinished():
          onFinalize(messageId);
        case RunError(:final message):
          onError?.call(messageId, message);
          onFinalize(messageId);
      }
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
EOF
ok "lib/bridge/a2ui/a2ui_content_driver.dart"

# ═══════════════════════════════════════════════════════════════════════════
# shared/providers — the FrbEntityTransport adapter (PEM host wiring seam)
# ═══════════════════════════════════════════════════════════════════════════
cat > lib/shared/providers/entity_transport.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// FrbEntityTransport — the host adapter that satisfies PEM's EntityTransport
// seam by delegating to the FFI facade. This is the ONLY EntityTransport impl;
// features consume PEM's providers, never this class directly. Tests override
// entityTransportProvider with a fake at this same boundary — nothing internal
// is mocked (see references/flutter/testing.md).
import 'package:prometheus_entity_management/prometheus_entity_management.dart';

import '../../bridge/rust_bridge_provider.dart' as bridge;

class FrbEntityTransport implements EntityTransport {
  const FrbEntityTransport();

  @override
  Future<ListResult> list(ViewDescriptor view) => bridge.entityList(view);

  @override
  Future<EntityRecord?> get(String entityType, String id) =>
      bridge.entityGet(entityType, id);

  @override
  Future<EntityRecord> create(EntityRecord record) => bridge.entityCreate(record);

  @override
  Future<EntityRecord> update(EntityRecord record) => bridge.entityUpdate(record);

  @override
  Future<void> delete(String entityType, String id) =>
      bridge.entityDelete(entityType, id);

  @override
  Stream<ChangeEvent> changes() => bridge.entityChanges();
}
EOF
ok "lib/shared/providers/entity_transport.dart"

# sync-status provider + chip
cat > lib/shared/providers/sync_status_provider.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:prometheus_entity_management/prometheus_entity_management.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../bridge/rust_bridge_provider.dart' as bridge;

part 'sync_status_provider.g.dart';

/// Read-only event feed from Rust — a stream provider (auto-dispose by default).
/// UI-only in effect, but it reaches the FFI, so retry stays off.
@Riverpod(retry: _noRetry)
Stream<SyncStatus> syncStatus(Ref ref) => bridge.syncStatus();

Duration? _noRetry(int retryCount, Object error) => null;
EOF

cat > lib/shared/widgets/sync_chip.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prometheus_entity_management/prometheus_entity_management.dart';

import '../providers/sync_status_provider.dart';
import '../../core/theme/tokens.dart';

/// A small status chip driven by the Rust SyncStatus stream. Presentational;
/// the exhaustive switch over the sealed SyncStatus is a compile-time contract.
class SyncChip extends ConsumerWidget {
  const SyncChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final (label, color) = switch (status.valueOrNull) {
      SyncOffline() || null => ('offline', T.textTertiary),
      SyncSyncing(:final pendingWrites) => ('syncing · $pendingWrites', T.amber),
      SyncLive() => ('live', T.green),
      SyncError() => ('error', T.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: T.uiMd.copyWith(color: color)),
      ]),
    );
  }
}
EOF
ok "shared: FrbEntityTransport + SyncChip"

# ═══════════════════════════════════════════════════════════════════════════
# features/chat — the vertical slice. ChatNotifier folds A2uiEvent → ContentBlock
# via A2uiContentDriver; send uses the Mutations API; FFI provider opts out of retry.
# ═══════════════════════════════════════════════════════════════════════════

cat > lib/features/chat/domain/entities/chat_message.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:gen_ui_widgets/gen_ui_widgets.dart';

/// One chat message = an ordered list of ContentBlocks folded from a run's
/// A2uiEvent stream. Immutable; ChatNotifier produces new instances on each edit.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isStreaming = false,
  });

  final String id;
  final String role; // 'user' | 'assistant'
  final List<ContentBlock> content;
  final bool isStreaming;

  ChatMessage copyWith({List<ContentBlock>? content, bool? isStreaming}) =>
      ChatMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}

class ChatState {
  const ChatState({this.messages = const [], this.threadId = 'default'});
  final List<ChatMessage> messages;
  final String threadId;

  const ChatState.initial() : messages = const [], threadId = 'default';

  ChatState copyWith({List<ChatMessage>? messages}) =>
      ChatState(messages: messages ?? this.messages, threadId: threadId);
}
EOF

cat > lib/features/chat/presentation/providers/chat_notifier.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// ChatNotifier owns ALL ContentBlock mutations. It sends via the FFI facade,
// then folds the returned A2uiEvent stream into the assistant message using
// A2uiContentDriver. Riverpod 3: guard ref.mounted after awaits; the send flow
// is driven by the Mutations API in the screen. No FFI-driven provider retries.
import 'dart:async';

import 'package:gen_ui_widgets/gen_ui_widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../bridge/a2ui/a2ui_content_driver.dart';
import '../../../../bridge/a2ui/a2ui_event.dart';
import '../../../../bridge/rust_bridge_provider.dart' as bridge;
import '../../domain/entities/chat_message.dart';

part 'chat_notifier.g.dart';

const _uuid = Uuid();

// ChatNotifier.build() is synchronous (never throws), so provider-level retry
// does not apply here. The FFI terminality that matters lives on the async
// FFI-backed providers (entityList/entity/syncStatus) and on the Mutation's
// own error handling — sendMessage runs inside a Mutation, not a build().
@riverpod
class ChatNotifier extends _$ChatNotifier {
  final _drivers = <String, A2uiContentDriver>{};

  @override
  ChatState build() {
    ref.onDispose(() {
      for (final d in _drivers.values) {
        d.dispose();
      }
    });
    return const ChatState.initial();
  }

  /// Append a ContentBlock to a streaming assistant message (sync — no await).
  void streamBlock({required String messageId, required ContentBlock block}) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == messageId) m.copyWith(content: [...m.content, block]) else m,
      ],
    );
  }

  void finalizeMessage(String messageId) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == messageId) m.copyWith(isStreaming: false) else m,
      ],
    );
  }

  /// Send a user message, open the assistant message, and fold its event stream.
  /// Terminal on Rust domain error (retry is off). Called from a Mutation.
  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: [TextBlock(text)],
    );
    final assistantId = _uuid.v4();
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: 'assistant',
      content: const [],
      isStreaming: true,
    );
    state = state.copyWith(messages: [...state.messages, userMsg, assistantMsg]);

    final runId = await bridge.chatSend(state.threadId, text);
    if (!ref.mounted) return; // provider paused/disposed while awaiting

    final driver = A2uiContentDriver(
      messageId: assistantId,
      onBlock: streamBlock,
      onFinalize: finalizeMessage,
      onError: (id, msg) => streamBlock(messageId: id, block: TextBlock('⚠️ $msg')),
    )..connect(bridge.chatEvents(runId));
    _drivers[assistantId] = driver;
    ref.onDispose(() => driver.dispose());
  }

  /// Test/utility seam: fold an already-open stream (no FFI send). Used by the
  /// boundary test to drive canned Rust-shaped events through the real fold path.
  Future<void> foldStream(String messageId, Stream<A2uiEvent> stream) async {
    if (!state.messages.any((m) => m.id == messageId)) {
      state = state.copyWith(messages: [
        ...state.messages,
        ChatMessage(id: messageId, role: 'assistant', content: const [], isStreaming: true),
      ]);
    }
    final driver = A2uiContentDriver(
      messageId: messageId,
      onBlock: streamBlock,
      onFinalize: finalizeMessage,
    )..connect(stream);
    _drivers[messageId] = driver;
  }
}
EOF

cat > lib/features/chat/presentation/screens/chat_screen.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gen_ui_widgets/gen_ui_widgets.dart';

import '../../../../shared/widgets/sync_chip.dart';
import '../providers/chat_notifier.dart';

/// Chat surface. Renders each message's ContentBlocks with the shared
/// ContentBlockView (exhaustive over all 11 variants — a compile-time contract).
/// Send uses the Riverpod 3 Mutations API for first-class pending/error state.
final sendMessageMutation = Mutation<void>();

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatNotifierProvider);
    final sendState = ref.watch(sendMessageMutation);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat'), actions: const [Padding(padding: EdgeInsets.only(right: 12), child: Center(child: SyncChip()))]),
      body: Column(children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final msg = state.messages[i];
              return Column(
                crossAxisAlignment: msg.role == 'user' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  for (final block in msg.content) ContentBlockView(block: block),
                  if (msg.isStreaming) const Padding(padding: EdgeInsets.only(top: 4), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                ],
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Message…', border: OutlineInputBorder()),
                  onSubmitted: sendState.isPending ? null : (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: sendState.isPending ? null : _send,
                icon: sendState.isPending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    sendMessageMutation.run(ref, (tsx) async {
      await tsx.get(chatNotifierProvider.notifier).sendMessage(text);
    });
  }
}
EOF
ok "features/chat (ChatNotifier + A2uiContentDriver + Mutations send)"

# ═══════════════════════════════════════════════════════════════════════════
# features/notes — entity-CRUD demo backed by prometheus_entity_management.
# Shows the families-as-normalization pattern + optimistic edit buffer.
# ═══════════════════════════════════════════════════════════════════════════
cat > lib/features/notes/presentation/screens/notes_screen.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// Notes list — a thin CRUD demo over prometheus_entity_management. The list
// comes from entityListProvider(view) (one family instance per query); creating
// a note calls the transport (FFI → Rust); the ChangeEvent bridge invalidates
// the affected providers. No hand-built Dart store — Riverpod families ARE it.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prometheus_entity_management/prometheus_entity_management.dart';
import 'package:uuid/uuid.dart';

const _notesView = ViewDescriptor(
  entityType: 'note',
  sorts: [SortSpec(field: 'updated_at', descending: true)],
  limit: 100,
);
const _uuid = Uuid();

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mount the change bridge so Rust-emitted invalidations reach these providers.
    ref.watch(entityChangeBridgeProvider);
    final notes = ref.watch(entityListProvider(_notesView));

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(ref),
        child: const Icon(Icons.add),
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (result) => ListView(
          children: [
            for (final rec in result.items)
              ListTile(
                title: Text((jsonDecode(rec.dataJson) as Map)['title']?.toString() ?? rec.id),
                subtitle: Text(rec.id, style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref
                      .read(entityCrudProvider(rec.entityType, rec.id, const {}).notifier)
                      .deleteRecord(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(WidgetRef ref) async {
    final id = _uuid.v4();
    final transport = ref.read(entityTransportProvider);
    await transport.create(EntityRecord(
      id: id,
      entityType: 'note',
      dataJson: jsonEncode({'title': 'New note', 'body': ''}),
    ));
  }
}
EOF
ok "features/notes (PEM entity CRUD demo)"

# ═══════════════════════════════════════════════════════════════════════════
# features/memory — memory / graph-RAG panel. Ingest text → hybrid search over
# the Rust gen_ui_db graph (vector + graph + BM25 → RRF fusion, all in Rust).
# The provider reaches the FFI, so retry stays OFF (Rust domain errors are
# terminal); search runs through the Mutations API for pending/error UI state.
# ═══════════════════════════════════════════════════════════════════════════
cat > lib/features/memory/domain/entities/memory_query.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import '../../../../bridge/rust_bridge_provider.dart' show MemoryHit;

export '../../../../bridge/rust_bridge_provider.dart' show MemoryHit;

/// Immutable result of one hybrid-search run: the query and its ranked hits.
class MemoryResult {
  const MemoryResult({required this.query, required this.hits});
  const MemoryResult.empty() : query = '', hits = const [];

  final String query;
  final List<MemoryHit> hits;
}
EOF

cat > lib/features/memory/presentation/providers/memory_notifier.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// MemoryNotifier owns the memory-panel state. It calls the FFI memory intents
// (ingest / hybrid search) via the bridge facade — never SurrealQL, never a
// second data path. build() is synchronous and never throws, so provider-level
// retry does not apply; the async FFI work runs inside Mutations in the screen,
// whose own error handling is terminal (Rust domain errors don't auto-retry).
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../bridge/rust_bridge_provider.dart' as bridge;
import '../../domain/entities/memory_query.dart';

part 'memory_notifier.g.dart';

/// Default recall breadth for the hybrid search (k in memory_search).
const int kMemoryRecallK = 8;

@riverpod
class MemoryNotifier extends _$MemoryNotifier {
  @override
  MemoryResult build() => const MemoryResult.empty();

  /// Ingest a note into the graph store (embed on-device + upsert, in Rust).
  /// Returns the new record id. Terminal on Rust domain error.
  Future<String> ingest(String text) => bridge.memoryIngest(text);

  /// Run a hybrid search and fold the ranked hits into state. Terminal on error.
  Future<void> search(String query) async {
    final hits = await bridge.memorySearch(query, kMemoryRecallK);
    if (!ref.mounted) return; // provider paused/disposed while awaiting
    applyHits(query, hits);
  }

  /// Fold an already-fetched hit list into state (sync — no await, no FFI).
  /// The boundary seam: search() awaits the FFI, then delegates here. The test
  /// drives real MemoryHits straight through this fold path — nothing internal
  /// is mocked; the only fake is the Rust-shaped hit list.
  void applyHits(String query, List<MemoryHit> hits) {
    state = MemoryResult(query: query, hits: hits);
  }
}
EOF

cat > lib/features/memory/presentation/screens/memory_screen.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// Memory / graph-RAG panel: ingest arbitrary text into the on-device graph,
// then run a hybrid search and render the ranked hits. Both actions flow through
// MemoryNotifier → bridge facade → Rust gen_ui_db. Presentation only; no query
// logic lives here. Ingest and search each use the Riverpod 3 Mutations API for
// first-class pending/error state (FFI errors are terminal — no silent retry).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/sync_chip.dart';
import '../../../../core/theme/tokens.dart';
import '../providers/memory_notifier.dart';

final ingestMemoryMutation = Mutation<String>();
final searchMemoryMutation = Mutation<void>();

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});
  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final _ingestController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _ingestController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(memoryNotifierProvider);
    final ingestState = ref.watch(ingestMemoryMutation);
    final searchState = ref.watch(searchMemoryMutation);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: Center(child: SyncChip()))],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ingest', style: T.uiMd.copyWith(color: T.textSecondary)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ingestController,
                  decoration: const InputDecoration(hintText: 'Add a memory…', border: OutlineInputBorder()),
                  onSubmitted: ingestState.isPending ? null : (_) => _ingest(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: ingestState.isPending ? null : _ingest,
                child: ingestState.isPending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Ingest'),
              ),
            ]),
            const SizedBox(height: 16),
            Text('Search', style: T.uiMd.copyWith(color: T.textSecondary)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Hybrid graph-RAG search…', border: OutlineInputBorder()),
                  onSubmitted: searchState.isPending ? null : (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: searchState.isPending ? null : _search,
                icon: searchState.isPending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
              ),
            ]),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: result.hits.isEmpty
              ? Center(child: Text(result.query.isEmpty ? 'No search yet' : 'No hits for "${result.query}"', style: T.uiMd.copyWith(color: T.textTertiary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: result.hits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final hit = result.hits[i];
                    return ListTile(
                      leading: const Icon(Icons.memory),
                      title: Text(hit.name),
                      subtitle: hit.snippet == null ? null : Text(hit.snippet!),
                      trailing: Text(hit.score.toStringAsFixed(3), style: T.uiMd.copyWith(color: T.textTertiary)),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  void _ingest() {
    final text = _ingestController.text.trim();
    if (text.isEmpty) return;
    _ingestController.clear();
    ingestMemoryMutation.run(ref, (tsx) async {
      return tsx.get(memoryNotifierProvider.notifier).ingest(text);
    });
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    searchMemoryMutation.run(ref, (tsx) async {
      await tsx.get(memoryNotifierProvider.notifier).search(query);
    });
  }
}
EOF
ok "features/memory (ingest → hybrid graph-RAG search)"

# ═══════════════════════════════════════════════════════════════════════════
# features/startup — first-run boot flow demo. Makes the boot-order invariant
# VISIBLE: migrations → seeds → shapes (see analysis §1.8). The actual steps run
# in Rust (gen_ui_db startup orchestrator); this feature drives them via the FFI
# facade and streams progress into a gate that blocks the app until ready.
# ═══════════════════════════════════════════════════════════════════════════
cat > lib/features/startup/domain/startup_phase.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
/// The three ordered boot phases (analysis §1.8). Shapes fail on unknown
/// columns, so the order is an invariant: migrate first, seed second, attach
/// sync shapes last. Kept as an enum so the UI switch is exhaustive.
enum StartupPhase { migrations, seeds, shapes, ready }

extension StartupPhaseLabel on StartupPhase {
  String get label => switch (this) {
        StartupPhase.migrations => 'Applying migrations',
        StartupPhase.seeds => 'Loading seed data',
        StartupPhase.shapes => 'Attaching sync shapes',
        StartupPhase.ready => 'Ready',
      };
  double get progress => switch (this) {
        StartupPhase.migrations => 0.25,
        StartupPhase.seeds => 0.5,
        StartupPhase.shapes => 0.85,
        StartupPhase.ready => 1.0,
      };
}
EOF

cat > lib/features/startup/presentation/providers/startup_notifier.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// StartupNotifier drives the first-run boot sequence and exposes the current
// phase to a gate widget. The real work (schema migrations, seed bundles, sync
// shape attach) runs in Rust's gen_ui_db startup orchestrator over the FFI
// facade; here we sequence the intents in the invariant order and surface
// progress. FFI-backed → retry OFF: a failed migration is terminal, not
// transient, and must be shown, not silently retried.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../bridge/rust_bridge_provider.dart' as bridge;
import '../../domain/startup_phase.dart';

part 'startup_notifier.g.dart';

Duration? _noRetry(int retryCount, Object error) => null;

/// Runs migrations → seeds → shapes once, yielding each phase as it begins and
/// [StartupPhase.ready] when the store is usable. A stream provider so the gate
/// rebuilds per phase; auto-dispose by default. Retry is off — see file header.
@Riverpod(retry: _noRetry)
Stream<StartupPhase> startup(Ref ref) async* {
  yield StartupPhase.migrations;
  await bridge.runMigrations();
  yield StartupPhase.seeds;
  await bridge.loadSeeds();
  yield StartupPhase.shapes;
  await bridge.attachSyncShapes();
  yield StartupPhase.ready;
}
EOF

cat > lib/features/startup/presentation/screens/startup_gate.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
// StartupGate blocks the app shell until the first-run boot sequence reaches
// StartupPhase.ready, rendering the current phase + progress. On error it shows
// the failure (no silent retry — a broken migration must be visible). Once
// ready, it renders [child]. Presentation only.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/startup_phase.dart';
import '../providers/startup_notifier.dart';

class StartupGate extends ConsumerWidget {
  const StartupGate({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(startupProvider);
    return phase.when(
      data: (p) => p == StartupPhase.ready
          ? child
          : _BootScreen(phase: p),
      loading: () => const _BootScreen(phase: StartupPhase.migrations),
      error: (e, _) => _BootError(message: '$e'),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({required this.phase});
  final StartupPhase phase;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(value: phase.progress),
            ),
            const SizedBox(height: 16),
            Text(phase.label, style: T.uiMd.copyWith(color: T.textSecondary)),
          ]),
        ),
      );
}

class _BootError extends StatelessWidget {
  const _BootError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, color: T.red, size: 40),
              const SizedBox(height: 12),
              Text('Startup failed', style: T.uiMd.copyWith(color: T.red)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: T.uiMd.copyWith(color: T.textTertiary)),
            ]),
          ),
        ),
      );
}
EOF
ok "features/startup (first-run migrations → seeds → shapes gate)"

# ═══════════════════════════════════════════════════════════════════════════
# app/ — router + root
# ═══════════════════════════════════════════════════════════════════════════
cat > lib/app/router.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/notes/presentation/screens/notes_screen.dart';
import '../features/memory/presentation/screens/memory_screen.dart';

/// The four KnowMe-slice tabs, in shell order. Adding a destination here is the
/// only edit needed to surface a feature — labels/icons/paths stay in lockstep.
const _tabs = <(String, IconData, String)>[
  ('/chat', Icons.chat_bubble_outline, 'Chat'),
  ('/notes', Icons.note_outlined, 'Notes'),
  ('/memory', Icons.memory, 'Memory'),
];

final appRouter = GoRouter(
  initialLocation: '/chat',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
        GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
        GoRoute(path: '/memory', builder: (_, __) => const MemoryScreen()),
      ],
    ),
  ],
);

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final (_, icon, label) in _tabs)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
EOF
ok "lib/app/router.dart"

cat > lib/main.dart << 'MAINEOF'
// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Staged for the post-codegen bootstrap below (kept imported so uncommenting is
// a one-line change once gen_ui_core is built and frb bindings are generated).
// ignore: unused_import
import 'package:path_provider/path_provider.dart';
import 'package:prometheus_entity_management/prometheus_entity_management.dart';

import 'app/router.dart';
// ignore: unused_import
import 'bridge/rust_bridge_provider.dart';
import 'features/startup/presentation/screens/startup_gate.dart';
import 'shared/providers/entity_transport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialise the Rust runtime BEFORE runApp (uncomment after frb codegen):
  // final dir = await getApplicationDocumentsDirectory();
  // await initRustBridge(dataDir: dir.path);
  // await setApiKey(const String.fromEnvironment('ANTHROPIC_API_KEY'));

  runApp(
    ProviderScope(
      overrides: [
        // Wire PEM's transport seam to the FFI-backed adapter. Everything above
        // this override reaches Rust through the canonical path.
        entityTransportProvider.overrideWithValue(const FrbEntityTransport()),
      ],
      child: const AppRoot(),
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Prometheus Hybrid',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        // StartupGate blocks the router shell until the first-run boot sequence
        // (migrations → seeds → shapes) reaches ready. Then it renders the app.
        home: StartupGate(child: _RouterHost()),
      );
}

class _RouterHost extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        routerConfig: appRouter,
      );
}
MAINEOF
ok "lib/main.dart"

# ═══════════════════════════════════════════════════════════════════════════
# Build scripts (Android .so + iOS XCFramework) — carry over from v1
# ═══════════════════════════════════════════════════════════════════════════
step "Writing native build scripts"
mkdir -p ../scripts/{android,ios}
cat > ../scripts/android/build.sh << 'BEOF'
#!/usr/bin/env bash
# Build gen_ui_core for all Android ABIs, then regenerate the Dart bridge.
set -euo pipefail
PROFILE="${1:-release}"
ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
RUST_DIR="$ROOT/rust"
OUT="$ROOT/mobile/android/app/src/main/jniLibs"
declare -A ABIS=(["arm64-v8a"]="aarch64-linux-android" ["armeabi-v7a"]="armv7-linux-androideabi" ["x86_64"]="x86_64-linux-android")
for ABI in "${!ABIS[@]}"; do
  TARGET="${ABIS[$ABI]}"
  cargo ndk --target "$ABI" --platform 24 -- build --manifest-path "$RUST_DIR/Cargo.toml" --target "$TARGET" $([[ "$PROFILE" == "release" ]] && echo "--release")
  mkdir -p "$OUT/$ABI"
  cp "$RUST_DIR/target/$TARGET/$PROFILE/libgen_ui_core.so" "$OUT/$ABI/"
  echo "✓ $ABI"
done
if command -v flutter_rust_bridge_codegen &>/dev/null; then
  flutter_rust_bridge_codegen generate --config-file "$RUST_DIR/flutter_rust_bridge.yaml"
  echo "✓ Dart bindings generated"
fi
BEOF
chmod +x ../scripts/android/build.sh

cat > ../scripts/ios/build-xcframework.sh << 'BEOF'
#!/usr/bin/env bash
# Build universal XCFramework for iOS device + simulator.
set -euo pipefail
PROFILE="${1:-release}"
ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
RUST_DIR="$ROOT/rust"
BUILD="$ROOT/scripts/ios/build"
FLAGS=(); [[ "$PROFILE" == "release" ]] && FLAGS+=(--release)
mkdir -p "$BUILD"
cargo build --manifest-path "$RUST_DIR/Cargo.toml" --target aarch64-apple-ios "${FLAGS[@]}"
cargo build --manifest-path "$RUST_DIR/Cargo.toml" --target aarch64-apple-ios-sim "${FLAGS[@]}"
cargo build --manifest-path "$RUST_DIR/Cargo.toml" --target x86_64-apple-ios "${FLAGS[@]}"
SIM_FAT="$BUILD/libgen_ui_core_sim.a"
lipo -create \
  "$RUST_DIR/target/aarch64-apple-ios-sim/$PROFILE/libgen_ui_core.a" \
  "$RUST_DIR/target/x86_64-apple-ios/$PROFILE/libgen_ui_core.a" \
  -output "$SIM_FAT"
XCFW="$BUILD/GenUICore.xcframework"
rm -rf "$XCFW"
xcodebuild -create-xcframework \
  -library "$RUST_DIR/target/aarch64-apple-ios/$PROFILE/libgen_ui_core.a" \
  -library "$SIM_FAT" \
  -output "$XCFW"
mkdir -p "$ROOT/mobile/ios/Frameworks"
cp -R "$XCFW" "$ROOT/mobile/ios/Frameworks/"
echo "✓ XCFramework → mobile/ios/Frameworks/"
BEOF
chmod +x ../scripts/ios/build-xcframework.sh
ok "Native build scripts"

# ═══════════════════════════════════════════════════════════════════════════
# Tests — features-first: a few boundary + golden tests (references/flutter/testing.md)
# ═══════════════════════════════════════════════════════════════════════════
step "Writing boundary + golden tests"

# Boundary test: ChatNotifier folds a canned A2uiEvent stream into ContentBlocks.
# The A2uiContentDriver, folding, and ContentBlock types are ALL real — the only
# thing supplied is a canned Rust-shaped stream (no internal mocks).
cat > test/features/chat/chat_flow_test.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_widgets/gen_ui_widgets.dart';

import 'package:MY_APP_SNAKE/bridge/a2ui/a2ui_event.dart';
import 'package:MY_APP_SNAKE/features/chat/domain/entities/chat_message.dart';
import 'package:MY_APP_SNAKE/features/chat/presentation/providers/chat_notifier.dart';

// A fake ONLY at the FFI edge: Rust-shaped A2uiEvents. Nothing internal mocked.
Stream<A2uiEvent> _cannedRun() async* {
  yield const RunStarted('run-1');
  yield const BlockEvent(TextBlock('Hello '));
  yield const BlockEvent(TextBlock('world'));
  yield const RunFinished('run-1');
}

void main() {
  test('ChatNotifier folds an A2uiEvent stream into ContentBlocks', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(chatNotifierProvider.notifier);
    await notifier.foldStream('msg-1', _cannedRun());
    // let the stream drain
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final ChatState state = container.read(chatNotifierProvider);
    final msg = state.messages.firstWhere((m) => m.id == 'msg-1');
    expect(msg.isStreaming, isFalse, reason: 'RunFinished finalizes the message');
    expect(msg.content, hasLength(2));
    expect(msg.content.every((b) => b is TextBlock), isTrue);
  });
}
EOF

# Golden test: ContentBlockView renders representative variants deterministically.
cat > test/features/chat/content_block_golden_test.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_widgets/gen_ui_widgets.dart';

void main() {
  goldenTest(
    'ContentBlockView renders core variants',
    fileName: 'content_block_view',
    builder: () => GoldenTestGroup(
      children: const [
        GoldenTestScenario(name: 'text', child: ContentBlockView(block: TextBlock('Hello world'))),
        GoldenTestScenario(name: 'thinking', child: ContentBlockView(block: ThinkingBlock('reasoning…'))),
        GoldenTestScenario(name: 'code', child: ContentBlockView(block: CodeBlock('dart', 'void main() {}'))),
        GoldenTestScenario(name: 'divider', child: ContentBlockView(block: DividerBlock())),
      ],
    ),
  );
}
EOF

# Boundary test: PEM EntityCrud optimistic save rolls back on transport failure.
# A fake EntityTransport at the FFI boundary; the EditBuffer + rollback are real.
cat > test/features/notes/entity_crud_test.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prometheus_entity_management/prometheus_entity_management.dart';

class _FailingTransport implements EntityTransport {
  @override
  Future<EntityRecord> update(EntityRecord record) async =>
      throw StateError('rust domain error');
  @override
  Future<ListResult> list(ViewDescriptor view) async => const ListResult();
  @override
  Future<EntityRecord?> get(String entityType, String id) async => null;
  @override
  Future<EntityRecord> create(EntityRecord record) async => record;
  @override
  Future<void> delete(String entityType, String id) async {}
  @override
  Stream<ChangeEvent> changes() => const Stream.empty();
}

void main() {
  test('EntityCrud rolls back the edit buffer when the transport fails', () async {
    final container = ProviderContainer(overrides: [
      entityTransportProvider.overrideWithValue(_FailingTransport()),
    ]);
    addTearDown(container.dispose);

    final ctrl = container.read(
      entityCrudProvider('note', 'n1', const {'title': 'Original'}).notifier,
    );
    ctrl.edit('title', 'Edited');
    expect(container.read(entityCrudProvider('note', 'n1', const {'title': 'Original'})).isDirty, isTrue);

    await expectLater(ctrl.save((m) => m.toString()), throwsA(isA<StateError>()));

    final buffer = container.read(entityCrudProvider('note', 'n1', const {'title': 'Original'}));
    expect(buffer.isDirty, isTrue, reason: 'save rolled back — edits are dirty again');
    expect(buffer.value('title'), 'Edited');
  });
}
EOF

# Boundary test: MemoryNotifier folds a Rust-shaped hit list into panel state.
# The fake is ONLY the FFI-edge List<MemoryHit>; the fold + MemoryResult are real.
cat > test/features/memory/memory_search_test.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:MY_APP_SNAKE/bridge/rust_bridge_provider.dart' show MemoryHit;
import 'package:MY_APP_SNAKE/features/memory/domain/entities/memory_query.dart';
import 'package:MY_APP_SNAKE/features/memory/presentation/providers/memory_notifier.dart';

void main() {
  test('MemoryNotifier folds ranked hits into MemoryResult', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(memoryNotifierProvider).hits, isEmpty);

    // Rust-shaped hits at the FFI boundary — the only fake. Nothing else mocked.
    const hits = [
      MemoryHit(id: 'entity:1', name: 'Alpha', score: 0.91, snippet: 'first'),
      MemoryHit(id: 'entity:2', name: 'Beta', score: 0.42),
    ];
    container.read(memoryNotifierProvider.notifier).applyHits('alpha', hits);

    final MemoryResult result = container.read(memoryNotifierProvider);
    expect(result.query, 'alpha');
    expect(result.hits, hasLength(2));
    expect(result.hits.first.name, 'Alpha');
    expect(result.hits.first.score, greaterThan(result.hits.last.score));
  });
}
EOF

# Boundary test: the startup phase order is the boot invariant (migrate→seed→shapes).
# Pure enum contract — no FFI needed; guards the ordering that shapes depend on.
cat > test/features/startup/startup_phase_test.dart << 'EOF'
// TJ-ARCH-MOB-001 compliant
import 'package:flutter_test/flutter_test.dart';

import 'package:MY_APP_SNAKE/features/startup/domain/startup_phase.dart';

void main() {
  test('boot phases are ordered migrations → seeds → shapes → ready', () {
    // The order is an invariant: sync shapes fail on unknown columns, so
    // migrations and seeds MUST precede shape attach (analysis §1.8).
    expect(StartupPhase.values, [
      StartupPhase.migrations,
      StartupPhase.seeds,
      StartupPhase.shapes,
      StartupPhase.ready,
    ]);
    // Progress is monotonic across the boot order.
    final progresses = StartupPhase.values.map((p) => p.progress).toList();
    for (var i = 1; i < progresses.length; i++) {
      expect(progresses[i], greaterThan(progresses[i - 1]));
    }
    expect(StartupPhase.ready.progress, 1.0);
  });
}
EOF

# Substitute the package name into the test import paths.
if command -v sed >/dev/null; then
  for tf in \
    test/features/chat/chat_flow_test.dart \
    test/features/memory/memory_search_test.dart \
    test/features/startup/startup_phase_test.dart; do
    sed -i.bak "s/MY_APP_SNAKE/${SNAKE_NAME}/g" "$tf" && rm -f "$tf.bak"
  done
fi
ok "5 boundary/golden tests (chat fold · ContentBlock golden · PEM rollback · memory fold · boot order)"

# ═══════════════════════════════════════════════════════════════════════════
# pub get — deferred: the path-dep packages are emitted by scaffold-packages.sh.
# In the hybrid flow they exist by the time the root runs pub get; standalone
# runs should scaffold packages first.
# ═══════════════════════════════════════════════════════════════════════════
step "Resolving dependencies"
if [[ -d ../flutter_packages/gen_ui_flutter && -d ../flutter_packages/prometheus_entity_management ]]; then
  flutter pub get && ok "flutter pub get"
  echo ""
  echo -e "${CYAN}Next: run codegen, then the app:${NC}"
  echo "  dart run build_runner build --delete-conflicting-outputs   # riverpod/freezed"
  echo "  # (build gen_ui_core, then) flutter_rust_bridge_codegen generate --config-file ../rust/flutter_rust_bridge.yaml"
  echo "  flutter run"
else
  warn "flutter_packages/* not present yet — skipping pub get."
  warn "Run scaffold-packages.sh (or the hybrid scaffold) first, then:"
  echo "     cd $OUT && flutter pub get && dart run build_runner build --delete-conflicting-outputs"
fi

echo ""
echo -e "${GREEN}✅ Flutter app scaffolded in $OUT/ (Riverpod 3.3.2 · frb 2.12 · PEM-wired)${NC}"
