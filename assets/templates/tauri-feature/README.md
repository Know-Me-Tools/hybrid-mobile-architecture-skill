# Tauri/React Feature Module Template

Use `scripts/new-feature.sh <n> tauri` to scaffold this structure.

```
features/<feature-name>/
  api/<feature>Api.ts          ← Rust invoke() wrappers (stores call these)
  stores/<feature>Store.ts     ← Zustand: client-side state (UI, selection, streaming)
  queries/<feature>Queries.ts  ← TanStack Query: server-side state (lists, details)
  hooks/use<Feature>.ts        ← Composed hook: what components import
  components/<Feature>*.tsx    ← React components (import only hooks)
  types.ts                     ← Feature-local TypeScript types
  index.ts                     ← Public API for the feature
```

## Layer contract

```
Component → Hook → Store → API (Rust invoke)
                 ↘
                  TanStack Query → API (Rust invoke)
```

**Never:**
- `import ... from '../stores'` in a component
- `invoke()` in a component or hook
- `fetch()` in a component or hook
- `useQuery` directly in a component (wrap in feature hook)
