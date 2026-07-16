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
