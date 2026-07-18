// TJ-ARCH-MOB-001 compliant — C-130: the trusted-device roster, stored IN
// the vault Loro doc so pairing/revocation converge like any other vault
// write (references/sync/peer-crdt.md: "each device keeps a signed roster
// of trusted peers inside the vault doc itself, so the roster syncs too").
import type { LoroDoc } from 'loro-crdt'

const ROSTER_MAP = 'device_roster'

export interface RosterEntry {
  deviceId: string
  publicKey: string // base64
  pairedAt: string
}

/** Add (or replace) a rostered device. Called on successful pairing. */
export function addToRoster(doc: LoroDoc, entry: RosterEntry): void {
  doc.getMap(ROSTER_MAP).set(entry.deviceId, JSON.stringify(entry))
  doc.commit()
}

/** Revoke a device. Propagates to every peer via the normal CRDT delta path. */
export function revokeFromRoster(doc: LoroDoc, deviceId: string): void {
  doc.getMap(ROSTER_MAP).delete(deviceId)
  doc.commit()
}

export function getRosterEntry(doc: LoroDoc, deviceId: string): RosterEntry | undefined {
  const raw = doc.getMap(ROSTER_MAP).get(deviceId)
  return typeof raw === 'string' ? (JSON.parse(raw) as RosterEntry) : undefined
}

export function listRoster(doc: LoroDoc): RosterEntry[] {
  const map = doc.getMap(ROSTER_MAP)
  const entries: RosterEntry[] = []
  for (const key of map.keys()) {
    const raw = map.get(key)
    if (typeof raw === 'string') entries.push(JSON.parse(raw) as RosterEntry)
  }
  return entries
}
