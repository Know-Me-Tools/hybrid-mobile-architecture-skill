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
                title: Text(
                    (jsonDecode(rec.dataJson) as Map)['title']?.toString() ??
                        rec.id),
                subtitle: Text(rec.id, style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref
                      .read(entityCrudProvider(rec.entityType, rec.id, const {})
                          .notifier)
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
