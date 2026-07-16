// TJ-ARCH-MOB-001 compliant — all Tauri IPC lives in this store module.
import { isTauri } from '@tauri-apps/api/core'
import {
  entityGet,
  entityList,
  entityRuntimeStart,
  entityRuntimeStop,
  type EntityRecord as PluginEntityRecord,
} from '@prometheus-ags/tauri-plugin-gen-ui'
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

// The plugin's wire shape ({id, entityType, dataJson}) is schema-agnostic —
// dataJson is the entity payload as a JSON string (see gen_ui_types::transport
// and the PEM Dart mirror's identical dataJson: String pattern). Adapt it into
// the row shape PEM's transport expects; tenant scoping is the caller's job.
function toEntityRow(record: PluginEntityRecord, tenantId: string): EntityRow {
  const data = JSON.parse(record.dataJson) as Record<string, unknown>
  return { ...data, id: record.id, tenant_id: tenantId }
}

function tauriTransport(entityType: string, tenantId: string): EntityTransport<EntityRow> {
  return {
    identify: (row) => row.id,
    authoritative: true,
    // The plugin's ViewDescriptor filters/sorts/pagination land with the real
    // entity-view UI (C-104+) — list() ignores the PEM ListQuery for now and
    // fetches everything, matching this transport's current pre-C-104 scope.
    list: async () => {
      const result = await entityList({ entityType, filters: [], sorts: [], limit: null, cursor: null })
      const rows = result.items.map((r) => toEntityRow(r, tenantId))
      return { rows, total: rows.length, nextCursor: result.nextCursor }
    },
    get: async (id) => {
      const record = await entityGet(entityType, id)
      return record ? toEntityRow(record, tenantId) : null
    },
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
    registerEntityTransport('Project', tauriTransport('projects', tenantId))
    registerEntityTransport('Note', tauriTransport('notes', tenantId))
    await entityRuntimeStart(tenantId)
    return () => { void entityRuntimeStop() }
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
