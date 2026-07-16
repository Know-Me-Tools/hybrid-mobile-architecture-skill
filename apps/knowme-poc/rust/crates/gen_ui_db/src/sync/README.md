# gen_ui_db::sync — read-path + write-path local-first sync (C-005)

Native (desktop/mobile) uses the Rust engine in this module. Web uses
`@electric-sql/pglite-sync` on the JS side — the Rust engine is compiled out on
`wasm32` (see `mod.rs`).

## Web path — `@electric-sql/pglite-sync` (JS)

The browser holds a PGlite database and subscribes to the same Electric shapes the
Rust consumer reads. Configure it in the web app (NOT in Rust):

```ts
import { PGlite } from '@electric-sql/pglite'
import { electricSync } from '@electric-sql/pglite-sync'

const pg = await PGlite.create({
  dataDir: 'idb://gen-ui',        // relaxedDurability + multi-tab worker per analysis §2
  extensions: { electric: electricSync() },
})

// One syncShapeToTable per synced table. Table/columns MUST already exist
// (boot order invariant: migrations → seeds → shapes attach).
const sub = await pg.electric.syncShapeToTable({
  shape: { url: `${ELECTRIC_URL}/v1/shape`, params: { table: 'entities' } },
  table: 'entities',
  primaryKey: ['id'],
  shapeKey: 'entities',           // persisted so a reload resumes from the stored offset
})

// Writes go through the app API (forge Quarry), never straight to Electric —
// Electric is read-path only. Mirror the Rust write-queue contract:
//   idempotent key per mutation, retry with backoff, surface poison to the UI.
```

Keep the web shape list identical to `SyncConfig::shapes` on native so both surfaces
converge on the same rows. The write-path API (forge Quarry) and its idempotency
contract are shared across surfaces.
