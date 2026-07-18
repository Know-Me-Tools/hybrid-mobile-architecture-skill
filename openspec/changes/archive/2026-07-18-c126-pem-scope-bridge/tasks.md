# Tasks — c126-pem-scope-bridge

- [ ] 1.1 Wire PGlite `live` extension into entityRuntime.ts; live query per synced table triggers PEM graph invalidation (no manual sync-awareness in feature code)
- [ ] 1.2 pgliteTransport: compile PEM's ListQuery (filters/sorts/limit/cursor) into parameterized SQL instead of fetch-everything
- [ ] 1.3 One-queue unification: mutation path writes local row + enqueues on _operation_queue via a single store API; PEM pending-action state derives from queue rows, not a parallel JS array
- [ ] 1.4 Behavior tests (vitest against real PGlite): live invalidation fires on row change; ListQuery filters/sorts/limit/cursor produce correct SQL and results; queue-derived pending state reflects enqueue/drain
- [x] 1.5 tsc + eslint clean; spec delta; openspec validate
