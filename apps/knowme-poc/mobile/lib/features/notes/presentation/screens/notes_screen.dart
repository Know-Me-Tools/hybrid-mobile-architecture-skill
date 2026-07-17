// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notes_provider.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final action = ref.watch(notesActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: action.isLoading
            ? null
            : () => ref.read(notesActionsProvider.notifier).create(),
        child: const Icon(Icons.add),
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (result) => ListView(
          children: [
            for (final note in result)
              ListTile(
                title: Text(note.title),
                subtitle: Text(note.id, style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: action.isLoading
                      ? null
                      : () => ref
                          .read(notesActionsProvider.notifier)
                          .delete(note.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
