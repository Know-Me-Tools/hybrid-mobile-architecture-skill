// TJ-ARCH-MOB-001 compliant — all Tauri IPC lives in this store module.
import { invoke, isTauri } from '@tauri-apps/api/core'
import { PGlite } from '@electric-sql/pglite'
import {
  createPGlitePersistenceAdapter,
  registerEntityFromSql,
  registerEntityTransport,
  startLocalFirstGraph,
  type EntityTransport,
  type LocalFirstGraphRuntime,
} from '@prometheus-ags/prometheus-entity-management'
import schemaSql from '../schema.sql?raw'

export interface EntityRow { id: string; tenant_id: string; [key: string]: unknown }
let runtime: LocalFirstGraphRuntime | null = null

function tauriTransport(entityType: string): EntityTransport<EntityRow> {
  return {
    identify: (row) => row.id,
    authoritative: true,
    list: (query) => invoke('entity_list', { view: { entityType, ...query } }),
    get: (id) => invoke('entity_get', { entityType, id }),
  }
}

function pgliteTransport(db: PGlite, table: string, tenantId: string): EntityTransport<EntityRow> {
  return {
    identify: (row) => row.id,
    authoritative: true,
    list: async ({ limit = 100 }) => {
      const result = await db.query<EntityRow>(
        `SELECT * FROM ${table} WHERE tenant_id = $1 ORDER BY updated_at DESC LIMIT $2`,
        [tenantId, limit],
      )
      return { rows: result.rows, total: result.rows.length, nextCursor: null }
    },
    get: async (id) => {
      const result = await db.query<EntityRow>(
        `SELECT * FROM ${table} WHERE tenant_id = $1 AND id = $2 LIMIT 1`, [tenantId, id],
      )
      return result.rows[0] ?? null
    },
  }
}

export async function startEntityRuntime(tenantId: string): Promise<() => void> {
  const [projectsDdl, notesDdl] = schemaSql.split(';').filter((sql) => sql.includes('CREATE TABLE'))
  if (!projectsDdl || !notesDdl) throw new Error('shared entity DDL is incomplete')
  registerEntityFromSql({ entityType: 'Project', createTableSql: projectsDdl })
  registerEntityFromSql({ entityType: 'Note', createTableSql: notesDdl })

  if (isTauri()) {
    registerEntityTransport('Project', tauriTransport('projects'))
    registerEntityTransport('Note', tauriTransport('notes'))
    await invoke<void>('entity_runtime_start', { tenantId })
    return () => { void invoke<void>('entity_runtime_stop') }
  }

  const db = await PGlite.create('idb://gen-ui', { relaxedDurability: true })
  await db.exec(schemaSql)
  registerEntityTransport('Project', pgliteTransport(db, 'projects', tenantId))
  registerEntityTransport('Note', pgliteTransport(db, 'notes', tenantId))
  runtime = startLocalFirstGraph({
    storage: await createPGlitePersistenceAdapter(db),
    key: `tenant:${tenantId}`,
    replayPendingActions: true,
  })
  return () => { runtime?.dispose(); runtime = null; void db.close() }
}
