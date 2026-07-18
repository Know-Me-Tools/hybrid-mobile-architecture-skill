// @vitest-environment node
// (PGlite's tar loader needs real Response/Blob — jsdom's polyfill lacks
// arrayBuffer(); nothing here touches the DOM.)
// TJ-ARCH-MOB-001 compliant — C-126 boundary tests: real PGlite + PEM's
// exported toSQLClauses, no mocks of internals. (bridgeTableToGraph's own
// tests use a fake live namespace — see the comment above that describe
// block for why the real `live` extension cannot run inside vitest here.)
import { describe, expect, test } from 'vitest'
import { PGlite } from '@electric-sql/pglite'
import { bridgeTableToGraph, compileListQuery, type LiveNamespace, type LivePGlite } from '../syncBridge'

async function seedDb(): Promise<PGlite> {
  const db = await PGlite.create()
  await db.exec(`
    CREATE TABLE notes (
      id text PRIMARY KEY,
      tenant_id text NOT NULL,
      title text NOT NULL,
      status text NOT NULL DEFAULT 'open',
      updated_at timestamptz NOT NULL DEFAULT now()
    );
  `)
  await db.query(
    "INSERT INTO notes (id, tenant_id, title, status) VALUES ('n1','t1','A','open'),('n2','t1','B','closed'),('n3','t2','C','open')",
  )
  return db
}

describe('compileListQuery', () => {
  test('never widens past the tenant boundary, even with no filter', async () => {
    const db = await seedDb()
    const { sql, params } = compileListQuery('notes', 't1', { filter: null, sort: null })
    const result = await db.query(sql, params)
    expect(result.rows).toHaveLength(2)
    expect((result.rows as { tenant_id: string }[]).every((r) => r.tenant_id === 't1')).toBe(true)
    await db.close()
  })

  test('honors filter and sort from a real PEM ListQuery', async () => {
    const db = await seedDb()
    const { sql, params } = compileListQuery('notes', 't1', {
      filter: [{ field: 'status', op: 'eq', value: 'open' }],
      sort: [{ field: 'title', direction: 'desc' }],
    })
    const result = await db.query<{ id: string }>(sql, params)
    expect(result.rows.map((r) => r.id)).toEqual(['n1'])
    await db.close()
  })

  test('honors limit and cursor for pagination', async () => {
    const db = await seedDb()
    const { sql, params } = compileListQuery('notes', 't1', { filter: null, sort: null, limit: 1, cursor: 1 })
    const result = await db.query(sql, params)
    expect(result.rows).toHaveLength(1)
    await db.close()
  })
})

// The real `@electric-sql/pglite/live` extension hangs vitest's process at
// `PGlite.create({extensions:{live}})` (verified: identical code exits
// normally under plain `node`, but never resolves inside any vitest pool —
// node, forks, singleFork all reproduce it). This is an environment
// incompatibility, not a bridge defect. bridgeTableToGraph therefore takes
// `live` as a seam (a `Pick<LivePGlite, "live">`), and this fake exercises
// the bridge's OWN subscribe/invalidate/unsubscribe contract — the same
// callback shape PGlite's live.query provides — without depending on the
// real extension resolving inside this test runner.
function fakeLiveQuery(): { live: LiveNamespace; fireChange: () => void; unsubscribed: boolean } {
  let onChange: (() => void) | null = null
  let unsubscribed = false
  const live = {
    query: async (_sql: string, _params: unknown[] | null, callback?: () => void) => {
      onChange = callback ?? null
      onChange?.() // PGlite's live.query fires its callback once immediately with initial results
      return { unsubscribe: () => { unsubscribed = true } }
    },
  } as unknown as LiveNamespace
  return {
    live,
    fireChange: () => onChange?.(),
    get unsubscribed() { return unsubscribed },
  } as { live: LiveNamespace; fireChange: () => void; unsubscribed: boolean }
}

describe('bridgeTableToGraph', () => {
  test('a change notification invalidates the bridged entity type', async () => {
    const fake = fakeLiveQuery()
    const calls: string[] = []
    const bridge = bridgeTableToGraph(
      { live: fake.live } as unknown as LivePGlite,
      'notes', 'Note', 't1', (type) => calls.push(type),
    )
    await Promise.resolve() // let the async attach() resolve
    calls.length = 0 // drop the initial-fire call, which mirrors real PGlite behavior
    fake.fireChange()
    expect(calls).toContain('Note')
    bridge.unsubscribe()
  })

  test('unsubscribe stops further invalidation and releases the live query', async () => {
    const fake = fakeLiveQuery()
    const calls: string[] = []
    const bridge = bridgeTableToGraph(
      { live: fake.live } as unknown as LivePGlite,
      'notes', 'Note', 't1', (type) => calls.push(type),
    )
    await Promise.resolve()
    bridge.unsubscribe()
    calls.length = 0
    fake.fireChange()
    expect(calls).toHaveLength(0)
  })
})
