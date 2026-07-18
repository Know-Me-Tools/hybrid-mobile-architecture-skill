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

const flush = async (rounds = 20) => {
  for (let i = 0; i < rounds; i++) {
    await new Promise((resolve) => setTimeout(resolve, 25))
  }
}

function inMemoryVault(): VaultRepository {
  return new VaultRepository(new LoroDoc(), async () => {})
}

describe('vault peer sync', () => {
  test('two paired devices converge in both directions', async () => {
    const deviceA = inMemoryVault()
    const deviceB = inMemoryVault()
    deviceA.setProfileField('displayName', 'Travis')
    deviceB.setPreference('theme', 'dark')

    const [endA, endB] = memoryDuplexPair()
    const sessionA = new VaultPeerSession(deviceA, endA)
    const sessionB = new VaultPeerSession(deviceB, endB)
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
