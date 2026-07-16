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
          if (m.id == messageId)
            m.copyWith(content: [...m.content, block])
          else
            m,
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
    state =
        state.copyWith(messages: [...state.messages, userMsg, assistantMsg]);

    final runId = await bridge.chatSend(state.threadId, text);
    if (!ref.mounted) return; // provider paused/disposed while awaiting

    final driver = A2uiContentDriver(
      messageId: assistantId,
      onBlock: streamBlock,
      onFinalize: finalizeMessage,
      onError: (id, msg) =>
          streamBlock(messageId: id, block: TextBlock('⚠️ $msg')),
    )..connect(bridge.chatEvents(runId));
    _drivers[assistantId] = driver;
    ref.onDispose(() => driver.dispose());
  }

  /// Test/utility seam: fold an already-open stream (no FFI send). Used by the
  /// boundary test to drive canned Rust-shaped events through the real fold path.
  Future<void> foldStream(String messageId, Stream<A2uiEvent> stream) async {
    if (!state.messages.any((m) => m.id == messageId)) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: messageId,
            role: 'assistant',
            content: const [],
            isStreaming: true,
          ),
        ],
      );
    }
    final driver = A2uiContentDriver(
      messageId: messageId,
      onBlock: streamBlock,
      onFinalize: finalizeMessage,
    )..connect(stream);
    _drivers[messageId] = driver;
  }
}
