// TJ-ARCH-MOB-001 compliant
// The FFI facade. Every call here delegates to gen_ui_core (Rust).
//
// Do NOT add networking, inference, or persistence logic here. This file is a
// pass-through to Rust; business logic living in Dart violates the architecture.
import 'dart:async';
import 'dart:convert';

import 'a2ui/a2ui_event.dart';
import 'package:prometheus_entity_management/prometheus_entity_management.dart';

import 'frb_generated.dart';
import 'api/chat.dart' as ffi_chat;
import 'api/streams.dart' as ffi_streams;

/// `dataDir` has no corresponding Rust parameter yet (`init_core` only takes
/// `worker_threads`, which `GenUiCore.init()` always passes as its default
/// `null`) — kept as an accepted-but-unused param so call sites don't need to
/// change when platform-specific data-dir wiring lands.
Future<void> initRustBridge({String? dataDir}) async {
  final _ = dataDir;
  await GenUiCore.init();
}

Future<void> setApiKey(String key) async {
  // No corresponding Rust function yet — secrets are resolved via
  // gen_ui_agent::SecretResolver (platform keychain), not passed from Dart.
}

/// chat_send(thread_id, message) -> run_id. Terminal on Rust error: `CoreError`
/// (e.g. "no provider configured") surfaces as a thrown Dart exception, per
/// frb's built-in `Result<T, E: std::error::Error>` handling (see
/// gen_ui_ffi::api::chat's module doc for why this needed spelling out
/// `Result<T, CoreError>` instead of the `CoreResult<T>` alias).
Future<String> chatSend(String threadId, String message) =>
    ffi_chat.chatSend(threadId: threadId, message: message);

/// chat_events(run_id) -> Stream<A2uiEvent>. The wire carries JSON `String`s
/// (see gen_ui_ffi::api::streams's module doc for why — the freezed/
/// riverpod_generator dependency conflict blocks native frb type mirroring
/// for enums with data-carrying variants); decode each with the hand-written
/// `A2uiEvent.fromWire`, which mirrors gen_ui_types::events::A2uiEvent's
/// `{"type": "...", ...}` serde shape.
Stream<A2uiEvent> chatEvents(String runId) => ffi_streams
    .chatEvents(runId: runId)
    .map((json) => A2uiEvent.fromWire(jsonDecode(json) as Map<String, dynamic>));

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
