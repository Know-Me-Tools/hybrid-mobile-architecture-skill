// TJ-ARCH-MOB-001 compliant — the vault is `local`-class: NEVER server-synced.
// One Loro doc per vault (references/sync/peer-crdt.md): maps profile /
// preferences / agent_facts. Persisted as encoded snapshots in _vault_state;
// the doc is the truth, the row is a cache. Feature code and agents use the
// typed facade — nobody touches Loro APIs outside this module and sync/.
import { LoroDoc } from 'loro-crdt'
import type { PGlite } from '@electric-sql/pglite'

export const VAULT_DOC_ID = 'user-vault'
/** Debounce for snapshot persistence after a mutation burst. */
const SNAPSHOT_DEBOUNCE_MS = 250

export interface VaultFact {
  key: string
  value: string
  learnedAt: string
}

/** Typed facade over the vault doc. Plain values in/out; CRDT stays inside. */
export class VaultRepository {
  private saveTimer: ReturnType<typeof setTimeout> | null = null

  constructor(
    readonly doc: LoroDoc,
    private readonly persist: (snapshot: Uint8Array, versionVector: Uint8Array) => Promise<void>,
  ) {
    // Any committed local change schedules a snapshot save (debounced).
    this.doc.subscribe(() => this.scheduleSave())
  }

  getProfileField(field: string): string | undefined {
    const value = this.doc.getMap('profile').get(field)
    return typeof value === 'string' ? value : undefined
  }

  setProfileField(field: string, value: string): void {
    this.doc.getMap('profile').set(field, value)
    this.doc.commit()
  }

  getPreference(key: string): string | undefined {
    const value = this.doc.getMap('preferences').get(key)
    return typeof value === 'string' ? value : undefined
  }

  setPreference(key: string, value: string): void {
    this.doc.getMap('preferences').set(key, value)
    this.doc.commit()
  }

  /** Agent-learned facts about the user (client-side agent data). */
  addAgentFact(fact: VaultFact): void {
    this.doc.getMap('agent_facts').set(fact.key, JSON.stringify(fact))
    this.doc.commit()
  }

  agentFacts(): VaultFact[] {
    const map = this.doc.getMap('agent_facts')
    const facts: VaultFact[] = []
    for (const key of map.keys()) {
      const raw = map.get(key)
      if (typeof raw === 'string') facts.push(JSON.parse(raw) as VaultFact)
    }
    return facts
  }

  async flush(): Promise<void> {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
      this.saveTimer = null
    }
    await this.persist(
      this.doc.export({ mode: 'snapshot' }),
      this.doc.version().encode(),
    )
  }

  private scheduleSave(): void {
    if (this.saveTimer) clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => {
      void this.flush()
    }, SNAPSHOT_DEBOUNCE_MS)
  }
}

/** Additive DDL for the local vault row. NOT a PEM entity, NOT in any SyncScope. */
export const VAULT_STATE_DDL = `
CREATE TABLE IF NOT EXISTS _vault_state (
  doc_id text PRIMARY KEY,
  crdt_state bytea NOT NULL,
  version_vector bytea NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);`

/** Open (or create) the vault against a PGlite store. */
export async function openVault(db: PGlite): Promise<VaultRepository> {
  await db.exec(VAULT_STATE_DDL)
  const doc = new LoroDoc()
  const existing = await db.query<{ crdt_state: Uint8Array }>(
    'SELECT crdt_state FROM _vault_state WHERE doc_id = $1',
    [VAULT_DOC_ID],
  )
  const row = existing.rows[0]
  if (row) doc.import(new Uint8Array(row.crdt_state))
  return new VaultRepository(doc, async (snapshot, versionVector) => {
    await db.query(
      `INSERT INTO _vault_state (doc_id, crdt_state, version_vector, updated_at)
       VALUES ($1, $2, $3, now())
       ON CONFLICT (doc_id) DO UPDATE
         SET crdt_state = $2, version_vector = $3, updated_at = now()`,
      [VAULT_DOC_ID, snapshot, versionVector],
    )
  })
}
