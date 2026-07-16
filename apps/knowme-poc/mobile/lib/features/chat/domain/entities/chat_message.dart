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

  const ChatState.initial()
      : messages = const [],
        threadId = 'default';

  ChatState copyWith({List<ChatMessage>? messages}) =>
      ChatState(messages: messages ?? this.messages, threadId: threadId);
}
