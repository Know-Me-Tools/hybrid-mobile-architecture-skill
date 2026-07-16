// TJ-ARCH-MOB-001 compliant
// A2uiEvent — Dart mirror of gen_ui_types::events::A2uiEvent. Crosses the FFI
// wire as JSON (see gen_ui_ffi::api::streams's module doc: frb type-mirroring
// is blocked for enums with data-carrying variants by a freezed/
// riverpod_generator dependency conflict — chatEvents streams
// Stream<String>, decoded here via A2uiEvent.fromWire), rather than a native
// frb type. serde tag = "type", snake_case, matching Rust's
// `#[serde(tag = "type", rename_all = "snake_case")]`.
import 'package:gen_ui_widgets/gen_ui_widgets.dart';

sealed class A2uiEvent {
  const A2uiEvent();

  /// Decode one `A2uiEvent` from its serde wire shape — e.g.
  /// `{"type": "run_started", "run_id": "..."}`.
  factory A2uiEvent.fromWire(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'run_started' => RunStarted(json['run_id'] as String),
      'block' => BlockEvent(
          ContentBlock.fromWire(json['block'] as Map<String, dynamic>),
        ),
      'run_finished' => RunFinished(json['run_id'] as String),
      'run_error' => RunError(json['message'] as String),
      final unknown =>
        throw FormatException('unknown A2uiEvent type: $unknown'),
    };
  }
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
