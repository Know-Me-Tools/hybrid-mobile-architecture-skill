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
  final void Function({required String messageId, required ContentBlock block})
      onBlock;
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
