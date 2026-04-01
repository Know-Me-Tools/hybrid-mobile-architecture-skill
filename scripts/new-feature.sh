#!/usr/bin/env bash
# scripts/new-feature.sh
# Scaffold a new feature module following clean architecture.
# Usage: bash scripts/new-feature.sh <feature-name> <platform: flutter|tauri> [project-root]
# Example: bash scripts/new-feature.sh memory-browser flutter ./mobile

set -euo pipefail

FEATURE="${1:-my-feature}"
PLATFORM="${2:-flutter}"
ROOT="${3:-.}"
SNAKE="$(echo "$FEATURE" | tr '-' '_' | tr '[:upper:]' '[:lower:]')"
PASCAL="$(echo "$FEATURE" | sed -E 's/(^|[-_])([a-z])/\U\2/g')"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }

echo ""
echo -e "${CYAN}── New feature module: $FEATURE ($PLATFORM)${NC}"

if [[ "$PLATFORM" == "flutter" ]]; then
  FEAT_DIR="$ROOT/lib/features/$SNAKE"
  step "Creating Flutter feature: $FEAT_DIR"
  mkdir -p "$FEAT_DIR"/{data/{repositories,datasources,models},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}

  # Domain entity
  cat > "$FEAT_DIR/domain/entities/${SNAKE}_entity.dart" << EOF
// TJ-ARCH-MOB-001 compliant
import 'package:freezed_annotation/freezed_annotation.dart';
part '${SNAKE}_entity.freezed.dart';

@freezed
class ${PASCAL}Entity with _\$${PASCAL}Entity {
  const factory ${PASCAL}Entity({
    required String id,
    // TODO: add entity fields
  }) = _${PASCAL}Entity;
}
EOF
  ok "domain/entities/${SNAKE}_entity.dart"

  # Domain repository interface
  cat > "$FEAT_DIR/domain/repositories/${SNAKE}_repository.dart" << EOF
// TJ-ARCH-MOB-001 compliant
import '../entities/${SNAKE}_entity.dart';

abstract interface class ${PASCAL}Repository {
  Future<List<${PASCAL}Entity>> getAll();
  Future<${PASCAL}Entity?> getById(String id);
  Future<void> save(${PASCAL}Entity entity);
  Future<void> delete(String id);
}
EOF
  ok "domain/repositories/${PASCAL}Repository"

  # Data model (DTO)
  cat > "$FEAT_DIR/data/models/${SNAKE}_model.dart" << EOF
// TJ-ARCH-MOB-001 compliant
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/${SNAKE}_entity.dart';
part '${SNAKE}_model.freezed.dart';
part '${SNAKE}_model.g.dart';

@freezed
class ${PASCAL}Model with _\$${PASCAL}Model {
  const factory ${PASCAL}Model({
    required String id,
    // TODO: add model fields matching DTO
  }) = _${PASCAL}Model;

  factory ${PASCAL}Model.fromJson(Map<String, dynamic> json) =>
      _\$${PASCAL}ModelFromJson(json);
}

extension ${PASCAL}ModelX on ${PASCAL}Model {
  ${PASCAL}Entity toEntity() => ${PASCAL}Entity(id: id);
}
EOF
  ok "data/models/${PASCAL}Model"

  # Data repository implementation
  cat > "$FEAT_DIR/data/repositories/${SNAKE}_repository_impl.dart" << EOF
// TJ-ARCH-MOB-001 compliant
import '../../domain/entities/${SNAKE}_entity.dart';
import '../../domain/repositories/${SNAKE}_repository.dart';

class ${PASCAL}RepositoryImpl implements ${PASCAL}Repository {
  // TODO: inject datasource dependencies

  @override
  Future<List<${PASCAL}Entity>> getAll() async {
    // TODO: fetch from datasource, convert to entities
    return [];
  }

  @override
  Future<${PASCAL}Entity?> getById(String id) async => null;

  @override
  Future<void> save(${PASCAL}Entity entity) async {}

  @override
  Future<void> delete(String id) async {}
}
EOF
  ok "data/repositories/${PASCAL}RepositoryImpl"

  # Riverpod provider
  cat > "$FEAT_DIR/presentation/providers/${SNAKE}_provider.dart" << EOF
// TJ-ARCH-MOB-001 compliant
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/${SNAKE}_repository_impl.dart';
import '../../domain/entities/${SNAKE}_entity.dart';
part '${SNAKE}_provider.g.dart';

@riverpod
${PASCAL}RepositoryImpl ${SNAKE}Repository(Ref ref) => ${PASCAL}RepositoryImpl();

@riverpod
class ${PASCAL}Notifier extends _\$${PASCAL}Notifier {
  @override
  FutureOr<List<${PASCAL}Entity>> build() async {
    return ref.watch(${SNAKE}RepositoryProvider).getAll();
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
EOF
  ok "presentation/providers/${PASCAL}Notifier (Riverpod)"

  # Screen
  cat > "$FEAT_DIR/presentation/screens/${SNAKE}_screen.dart" << EOF
// TJ-ARCH-MOB-001 compliant
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/${SNAKE}_provider.dart';

class ${PASCAL}Screen extends ConsumerWidget {
  const ${PASCAL}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${SNAKE}NotifierProvider);
    return Scaffold(
      appBar: AppBar(title: Text('$PASCAL')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No items'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => ListTile(title: Text(items[i].id)),
              ),
      ),
    );
  }
}
EOF
  ok "presentation/screens/${PASCAL}Screen"

  echo ""
  ok "Flutter feature '$FEATURE' scaffolded in $FEAT_DIR"
  echo ""
  echo "  Next: dart run build_runner build"

elif [[ "$PLATFORM" == "tauri" ]]; then
  FEAT_DIR="$ROOT/src/features/$SNAKE"
  step "Creating Tauri/React feature: $FEAT_DIR"
  mkdir -p "$FEAT_DIR"/{api,stores,queries,hooks,components}

  # Types
  cat > "$FEAT_DIR/types.ts" << EOF
// TJ-ARCH-MOB-001 compliant
export interface ${PASCAL}Entity {
  id: string;
  // TODO: add entity fields
}

export interface ${PASCAL}CreateInput {
  // TODO: add create fields
}

export interface ${PASCAL}UpdateInput {
  id: string;
  // TODO: add update fields
}
EOF
  ok "types.ts"

  # API layer (store calls these — never components or hooks)
  cat > "$FEAT_DIR/api/${SNAKE}Api.ts" << EOF
// TJ-ARCH-MOB-001 compliant — API layer (called only from stores)
import { invoke } from '@tauri-apps/api/core';
import type { ${PASCAL}Entity, ${PASCAL}CreateInput } from '../types';

export const ${SNAKE}Api = {
  getAll: () => invoke<${PASCAL}Entity[]>('${SNAKE}_get_all'),
  getById: (id: string) => invoke<${PASCAL}Entity>('${SNAKE}_get_by_id', { id }),
  create: (input: ${PASCAL}CreateInput) => invoke<${PASCAL}Entity>('${SNAKE}_create', { input }),
  delete: (id: string) => invoke<void>('${SNAKE}_delete', { id }),
};
EOF
  ok "api/${SNAKE}Api.ts"

  # Zustand store (client-side state)
  cat > "$FEAT_DIR/stores/${SNAKE}Store.ts" << EOF
// TJ-ARCH-MOB-001 compliant — Zustand store (client-side state)
// Components NEVER import this directly — use hooks instead
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { subscribeWithSelector } from 'zustand/middleware';
import { ${SNAKE}Api } from '../api/${SNAKE}Api';
import type { ${PASCAL}Entity } from '../types';

interface ${PASCAL}State {
  selectedId: string | null;
  filter: string;
}

interface ${PASCAL}Actions {
  setSelectedId: (id: string | null) => void;
  setFilter: (filter: string) => void;
  delete: (id: string, onSuccess?: () => void) => Promise<void>;
}

export const use${PASCAL}Store = create<${PASCAL}State & ${PASCAL}Actions>()(
  subscribeWithSelector(
    immer((set) => ({
      selectedId: null,
      filter: '',

      setSelectedId: (id) => set((s) => { s.selectedId = id; }),
      setFilter: (filter) => set((s) => { s.filter = filter; }),

      // Store calls API — never a component or hook
      delete: async (id, onSuccess) => {
        await ${SNAKE}Api.delete(id);
        set((s) => { if (s.selectedId === id) s.selectedId = null; });
        onSuccess?.();
      },
    }))
  )
);
EOF
  ok "stores/${SNAKE}Store.ts (Zustand)"

  # TanStack Query hooks (server-side state)
  cat > "$FEAT_DIR/queries/${SNAKE}Queries.ts" << EOF
// TJ-ARCH-MOB-001 compliant — TanStack Query (server-side state)
// Used by feature hooks — not directly by components
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ${SNAKE}Api } from '../api/${SNAKE}Api';
import type { ${PASCAL}CreateInput } from '../types';

export const ${SNAKE}Keys = {
  all:    ['${SNAKE}'] as const,
  lists:  () => [...${SNAKE}Keys.all, 'list'] as const,
  detail: (id: string) => [...${SNAKE}Keys.all, 'detail', id] as const,
};

export function use${PASCAL}List() {
  return useQuery({
    queryKey: ${SNAKE}Keys.lists(),
    queryFn:  ${SNAKE}Api.getAll,
    staleTime: 30_000,
  });
}

export function use${PASCAL}Detail(id: string) {
  return useQuery({
    queryKey: ${SNAKE}Keys.detail(id),
    queryFn:  () => ${SNAKE}Api.getById(id),
    enabled:  !!id,
  });
}

export function useCreate${PASCAL}() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: ${PASCAL}CreateInput) => ${SNAKE}Api.create(input),
    onSuccess: () => qc.invalidateQueries({ queryKey: ${SNAKE}Keys.lists() }),
  });
}

export function useDelete${PASCAL}() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => ${SNAKE}Api.delete(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ${SNAKE}Keys.lists() }),
  });
}
EOF
  ok "queries/${SNAKE}Queries.ts (TanStack Query)"

  # Feature hook (what components actually use)
  cat > "$FEAT_DIR/hooks/use${PASCAL}.ts" << EOF
// TJ-ARCH-MOB-001 compliant — Feature hook
// This is the ONLY thing components import from this feature for state/actions
import { use${PASCAL}Store } from '../stores/${SNAKE}Store';
import { use${PASCAL}List, useCreate${PASCAL}, useDelete${PASCAL} } from '../queries/${SNAKE}Queries';

export function use${PASCAL}() {
  const { data: items = [], isLoading, error } = use${PASCAL}List();
  const { mutate: create, isPending: isCreating } = useCreate${PASCAL}();
  const { mutate: deleteFn } = useDelete${PASCAL}();

  // Client-side state from Zustand (via store)
  const selectedId = use${PASCAL}Store((s) => s.selectedId);
  const filter     = use${PASCAL}Store((s) => s.filter);
  const setFilter  = use${PASCAL}Store((s) => s.setFilter);
  const select     = use${PASCAL}Store((s) => s.setSelectedId);

  const filteredItems = filter
    ? items.filter((item) => item.id.toLowerCase().includes(filter.toLowerCase()))
    : items;

  return {
    items: filteredItems,
    isLoading,
    error,
    isCreating,
    selectedId,
    filter,
    setFilter,
    select,
    create,
    delete: deleteFn,
  };
}
EOF
  ok "hooks/use${PASCAL}.ts (composed hook)"

  # Component (uses only the hook)
  cat > "$FEAT_DIR/components/${PASCAL}List.tsx" << EOF
// TJ-ARCH-MOB-001 compliant — Component (imports only hook, never stores)
import { use${PASCAL} } from '../hooks/use${PASCAL}';

export function ${PASCAL}List() {
  const { items, isLoading, error, filter, setFilter, select } = use${PASCAL}();

  if (isLoading) return <div className="p-4 text-muted-foreground">Loading...</div>;
  if (error)     return <div className="p-4 text-destructive">Error loading ${FEATURE}</div>;

  return (
    <div className="flex flex-col gap-2">
      <input
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        placeholder="Filter..."
        className="px-3 py-2 rounded-md border border-border bg-surface text-sm"
      />
      {items.length === 0 ? (
        <p className="text-muted-foreground text-sm">No items found.</p>
      ) : (
        items.map((item) => (
          <button
            key={item.id}
            onClick={() => select(item.id)}
            className="text-left px-3 py-2 rounded-md hover:bg-accent text-sm"
          >
            {item.id}
          </button>
        ))
      )}
    </div>
  );
}
EOF
  ok "components/${PASCAL}List.tsx"

  # Feature index
  cat > "$FEAT_DIR/index.ts" << EOF
// Feature public API — only export what other features/routes need
export { ${PASCAL}List } from './components/${PASCAL}List';
export { use${PASCAL} } from './hooks/use${PASCAL}';
export type { ${PASCAL}Entity } from './types';
EOF
  ok "index.ts (feature public API)"

  echo ""
  ok "Tauri/React feature '$FEATURE' scaffolded in $FEAT_DIR"
  echo ""
  echo "  Architecture enforced:"
  echo "    Component → Hook → Store + TanStack Query → API (Rust invoke)"
  echo "  Add Rust commands in src-tauri/src/commands.rs"

else
  echo "Unknown platform: $PLATFORM. Use 'flutter' or 'tauri'."
  exit 1
fi
