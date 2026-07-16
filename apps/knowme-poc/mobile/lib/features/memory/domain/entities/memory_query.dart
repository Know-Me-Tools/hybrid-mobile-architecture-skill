// TJ-ARCH-MOB-001 compliant
import '../../../../bridge/rust_bridge_provider.dart' show MemoryHit;

export '../../../../bridge/rust_bridge_provider.dart' show MemoryHit;

/// Immutable result of one hybrid-search run: the query and its ranked hits.
class MemoryResult {
  const MemoryResult({required this.query, required this.hits});
  const MemoryResult.empty()
      : query = '',
        hits = const [];

  final String query;
  final List<MemoryHit> hits;
}
