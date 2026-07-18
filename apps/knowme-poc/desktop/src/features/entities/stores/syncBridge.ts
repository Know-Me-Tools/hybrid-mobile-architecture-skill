// TJ-ARCH-MOB-001 compliant — C-126: the app-side PEM scope bridge.
// ADR-LFS-2 (references/sync/decisions.md): PEM's canonical sync adapter is
// "local-store transports hydrated by the sync engine" — no bespoke socket.
// This module supplies exactly that on the PGlite web/webview tier using
// PEM's own public surface (toSQLClauses, useGraphStore) plus PGlite's `live`
// extension for table-change notification. It does not open a second
// transport abstraction; it wires the frozen local store to PEM's graph.
import type { PGlite } from '@electric-sql/pglite'
import type { LiveNamespace, LiveQuery } from '@electric-sql/pglite/live'
export type { LiveNamespace } from '@electric-sql/pglite/live'
import { toSQLClauses, useGraphStore, type ListQuery, type ViewDescriptor } from '@prometheus-ags/prometheus-entity-management'

/** PGlite instance augmented with the `live` extension (see PGlite.create extensions.live). */
export interface LivePGlite extends PGlite {
  live: LiveNamespace
}

/**
 * Compile a PEM ListQuery into the SQL this tenant-scoped table needs.
 * PEM's own `toSQLClauses` handles filter/sort; tenant scoping and
 * limit/cursor are appended here because those are transport-local concerns
 * (tenant predicate is never client-supplied — LFS-INV-7 applies to local
 * queries too: never widen a query past the tenant boundary).
 */
export function compileListQuery(
  table: string,
  tenantId: string,
  query: ListQuery,
): { sql: string; params: unknown[] } {
  const view: ViewDescriptor = { filter: query.filter ?? undefined, sort: query.sort ?? undefined }
  const { where, orderBy, params } = toSQLClauses(view)
  // toSQLClauses returns the literal string "TRUE" for an empty filter — never
  // interpolate it away, just AND the tenant predicate onto it (LFS-INV-7: the
  // tenant predicate is never optional, even locally).
  const tenantParamIndex = params.length + 1
  const whereClause = `(${where}) AND tenant_id = $${tenantParamIndex}`
  const allParams = [...params, tenantId]

  let sql = `SELECT * FROM ${table} WHERE ${whereClause}`
  if (orderBy) sql += ` ORDER BY ${orderBy}`
  else sql += ' ORDER BY updated_at DESC'

  if (typeof query.limit === 'number') {
    allParams.push(query.limit)
    sql += ` LIMIT $${allParams.length}`
  }
  if (typeof query.cursor === 'number') {
    allParams.push(query.cursor)
    sql += ` OFFSET $${allParams.length}`
  }
  return { sql, params: allParams }
}

interface TableSubscription {
  unsubscribe: () => void
}

/**
 * Subscribe a synced table to PGlite's `live` extension so any local row
 * change (including rows a scope stream writes) invalidates the PEM graph
 * for that entity type. Feature code never has to know sync happened —
 * the table changing IS the signal (the bridge this change exists to build).
 *
 * `invalidate` is injectable (defaults to the real store) so tests can pass a
 * plain function instead of mutating the module-singleton zustand store.
 */
export function bridgeTableToGraph(
  db: Pick<LivePGlite, 'live'>,
  table: string,
  entityType: string,
  tenantId: string,
  invalidate: (entityType: string) => void = (type) => useGraphStore.getState().invalidateType(type),
): TableSubscription {
  let live: LiveQuery<Record<string, unknown>> | null = null
  let disposed = false

  const attach = async () => {
    live = await db.live.query<Record<string, unknown>>(
      `SELECT id FROM ${table} WHERE tenant_id = $1`,
      [tenantId],
      () => {
        // Guard against a callback that fires after unsubscribe() ran —
        // some live-query implementations may deliver one in-flight
        // notification before teardown completes.
        if (disposed) return
        // The live query only needs to fire — PEM re-fetches via the
        // registered transport, which now honors the real ListQuery
        // (compileListQuery) instead of re-deriving rows here.
        invalidate(entityType)
      },
    )
    if (disposed) live.unsubscribe()
  }
  void attach()

  return {
    unsubscribe: () => {
      disposed = true
      live?.unsubscribe()
    },
  }
}
