// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gen_ui_widgets/gen_ui_widgets.dart';

import '../../../../shared/widgets/sync_chip.dart';
import '../providers/chat_notifier.dart';

/// Chat surface. Renders each message's ContentBlocks with the shared
/// ContentBlockView (exhaustive over all 11 variants — a compile-time contract).
/// Send tracks its own local pending state — Riverpod 3.3.2's Mutation API exists
/// internally (riverpod/src/core/mutations.dart) but is NOT part of the public
/// export surface yet (still experimental per the Riverpod 3 release notes), so
/// this uses the always-available local-state pattern instead of an unstable API.

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat'), actions: const [
        Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: SyncChip()))
      ]),
      body: Column(children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final msg = state.messages[i];
              return Column(
                crossAxisAlignment: msg.role == 'user'
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  for (final block in msg.content)
                    ContentBlockView(block: block),
                  if (msg.isStreaming)
                    const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))),
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
                  decoration: const InputDecoration(
                      hintText: 'Message…', border: OutlineInputBorder()),
                  onSubmitted: _isSending ? null : (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _isSending = true);
    try {
      await ref.read(chatProvider.notifier).sendMessage(text);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
