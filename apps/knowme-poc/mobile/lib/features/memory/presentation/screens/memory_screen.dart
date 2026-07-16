// TJ-ARCH-MOB-001 compliant
// Memory / graph-RAG panel: ingest arbitrary text into the on-device graph,
// then run a hybrid search and render the ranked hits. Both actions flow through
// MemoryNotifier → bridge facade → Rust gen_ui_db. Presentation only; no query
// logic lives here. Ingest and search each track local pending state — Riverpod
// 3.3.2's Mutation API exists internally but is not on the public export surface
// yet (still experimental), so this uses the always-available local-state pattern
// (FFI errors are still terminal — no silent retry — that's enforced in the notifier).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/sync_chip.dart';
import '../../../../core/theme/tokens.dart';
import '../providers/memory_notifier.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});
  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final _ingestController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isIngesting = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _ingestController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(memoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: SyncChip()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ingest', style: T.uiMd.copyWith(color: T.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ingestController,
                        decoration: const InputDecoration(
                          hintText: 'Add a memory…',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _isIngesting ? null : (_) => _ingest(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isIngesting ? null : _ingest,
                      child: _isIngesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ingest'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Search', style: T.uiMd.copyWith(color: T.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Hybrid graph-RAG search…',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _isSearching ? null : (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSearching ? null : _search,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: result.hits.isEmpty
                ? Center(
                    child: Text(
                      result.query.isEmpty
                          ? 'No search yet'
                          : 'No hits for "${result.query}"',
                      style: T.uiMd.copyWith(color: T.textTertiary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: result.hits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final hit = result.hits[i];
                      return ListTile(
                        leading: const Icon(Icons.memory),
                        title: Text(hit.name),
                        subtitle:
                            hit.snippet == null ? null : Text(hit.snippet!),
                        trailing: Text(
                          hit.score.toStringAsFixed(3),
                          style: T.uiMd.copyWith(color: T.textTertiary),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _ingest() async {
    final text = _ingestController.text.trim();
    if (text.isEmpty) return;
    _ingestController.clear();
    setState(() => _isIngesting = true);
    try {
      await ref.read(memoryProvider.notifier).ingest(text);
    } finally {
      if (mounted) setState(() => _isIngesting = false);
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      await ref.read(memoryProvider.notifier).search(query);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }
}
