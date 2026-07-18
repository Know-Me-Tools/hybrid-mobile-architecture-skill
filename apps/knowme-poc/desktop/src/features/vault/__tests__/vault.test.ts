// @vitest-environment node
// (PGlite's tar loader needs real Response/Blob — jsdom's polyfill lacks
// arrayBuffer(); nothing here touches the DOM.)
// TJ-ARCH-MOB-001 compliant — vault boundary tests: two in-process peers over
// the in-memory duplex exercising the public contract (no protocol internals
// mocked): bidirectional convergence, chunked large messages, persistence
// round-trip through PGlite.
import { describe, expect, test } from 'vitest'
import { PGlite } from '@electric-sql/pglite'
import { LoroDoc } from 'loro-crdt'
import { openVault, VaultRepository } from '../stores/vaultStore'
import { VaultPeerSession } from '../sync/peerSync'
import { memoryDuplexPair } from '../sync/memoryDuplex'
import { encodeFrames, FrameAssembler, FRAME_PAYLOAD_BYTES } from '../sync/duplex'
import { loadOrCreateDeviceKey, type DeviceKeyPair } from '../sync/deviceAuth'
import { addToRoster, revokeFromRoster } from '../sync/roster'

const flush = async (rounds = 20) => {
  for (let i = 0; i < rounds; i++) {
    await new Promise((resolve) => setTimeout(resolve, 25))
  }
}

function inMemoryVault(): VaultRepository {
  return new VaultRepository(new LoroDoc(), async () => {})
}

/** In-memory Storage fake — each test gets its own device identity. */
function memoryStorage(): Storage {
  const store = new Map<string, string>()
  return {
    getItem: (k) => store.get(k) ?? null,
    setItem: (k, v) => void store.set(k, v),
    removeItem: (k) => void store.delete(k),
    clear: () => store.clear(),
    key: () => null,
    length: 0,
  } as Storage
}

async function pairMutually(a: VaultRepository, keyA: DeviceKeyPair, b: VaultRepository, keyB: DeviceKeyPair) {
  const now = new Date().toISOString()
  addToRoster(a.doc, { deviceId: keyB.deviceId, publicKey: toB64(keyB.publicKey), pairedAt: now })
  addToRoster(b.doc, { deviceId: keyA.deviceId, publicKey: toB64(keyA.publicKey), pairedAt: now })
}
function toB64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
}

describe('vault peer sync', () => {
  test('two paired devices converge in both directions', async () => {
    const deviceA = inMemoryVault()
    const deviceB = inMemoryVault()
    const keyA = await loadOrCreateDeviceKey(memoryStorage())
    const keyB = await loadOrCreateDeviceKey(memoryStorage())
    await pairMutually(deviceA, keyA, deviceB, keyB)
    deviceA.setProfileField('displayName', 'Travis')
    deviceB.setPreference('theme', 'dark')

    const [endA, endB] = memoryDuplexPair()
    const sessionA = new VaultPeerSession(deviceA, endA, keyA)
    const sessionB = new VaultPeerSession(deviceB, endB, keyB)
    await flush()

    expect(deviceB.getProfileField('displayName')).toBe('Travis')
    expect(deviceA.getPreference('theme')).toBe('dark')

    // Post-pairing mutation propagates (agent writes a learned fact on A).
    deviceA.addAgentFact({ key: 'likes', value: 'espresso', learnedAt: '2026-07-18T00:00:00Z' })
    await flush()
    expect(deviceB.agentFacts().map((f) => f.key)).toContain('likes')

    sessionA.close()
    sessionB.close()
  })

  test('an unrostered peer is rejected — no convergence', async () => {
    const deviceA = inMemoryVault()
    const deviceB = inMemoryVault()
    const keyA = await loadOrCreateDeviceKey(memoryStorage())
    const keyB = await loadOrCreateDeviceKey(memoryStorage())
    // Deliberately NOT paired — B is a stranger to A's roster and vice versa.
    deviceA.setProfileField('displayName', 'Travis')

    const [endA, endB] = memoryDuplexPair()
    const sessionA = new VaultPeerSession(deviceA, endA, keyA)
    const sessionB = new VaultPeerSession(deviceB, endB, keyB)
    await flush()

    expect(deviceB.getProfileField('displayName')).toBeUndefined()

    sessionA.close()
    sessionB.close()
  })

  test('a revoked peer is cut off from further sync', async () => {
    const deviceA = inMemoryVault()
    const deviceB = inMemoryVault()
    const keyA = await loadOrCreateDeviceKey(memoryStorage())
    const keyB = await loadOrCreateDeviceKey(memoryStorage())
    await pairMutually(deviceA, keyA, deviceB, keyB)
    deviceA.setProfileField('displayName', 'Travis')

    const [endA, endB] = memoryDuplexPair()
    let sessionA = new VaultPeerSession(deviceA, endA, keyA)
    let sessionB = new VaultPeerSession(deviceB, endB, keyB)
    await flush()
    expect(deviceB.getProfileField('displayName')).toBe('Travis')
    sessionA.close()
    sessionB.close()

    // Revocation propagated via the roster's own CRDT convergence above;
    // now A revokes B locally and a NEW session must refuse to converge.
    revokeFromRoster(deviceA.doc, keyB.deviceId)
    deviceA.setProfileField('displayName', 'Travis (post-revocation)')

    const [endA2, endB2] = memoryDuplexPair()
    sessionA = new VaultPeerSession(deviceA, endA2, keyA)
    sessionB = new VaultPeerSession(deviceB, endB2, keyB)
    await flush()
    expect(deviceB.getProfileField('displayName')).toBe('Travis') // unchanged

    sessionA.close()
    sessionB.close()
  })

  test('messages larger than one frame chunk and reassemble', () => {
    const big = new Uint8Array(FRAME_PAYLOAD_BYTES * 3 + 17).fill(7)
    const frames = encodeFrames({ kind: 'delta', update: big }, 42)
    expect(frames.length).toBe(4)
    const assembler = new FrameAssembler()
    let out: ReturnType<FrameAssembler['push']> = null
    // Deliver out of order — reassembly must not depend on arrival order.
    for (const frame of [frames[2], frames[0], frames[3], frames[1]]) {
      out = assembler.push(frame)
    }
    expect(out).not.toBeNull()
    expect(out!.kind).toBe('delta')
    expect((out as { update: Uint8Array }).update.length).toBe(big.length)
  })

  test('vault persists and reopens from PGlite', async () => {
    const db = await PGlite.create()
    const vault = await openVault(db)
    vault.setProfileField('displayName', 'Travis')
    vault.setPreference('theme', 'dark')
    await vault.flush()

    const reopened = await openVault(db)
    expect(reopened.getProfileField('displayName')).toBe('Travis')
    expect(reopened.getPreference('theme')).toBe('dark')
    await db.close()
  })
})
