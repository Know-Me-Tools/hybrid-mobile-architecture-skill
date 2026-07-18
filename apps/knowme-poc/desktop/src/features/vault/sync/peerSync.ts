// TJ-ARCH-MOB-001 compliant — the vault peer-sync protocol
// (references/sync/peer-crdt.md): exchange version vectors, send
// export_updates_since deltas both ways, converge commutatively, repeat on
// mutation (debounced, delta-only). Transport-agnostic over VaultDuplex.
//
// C-130: protocol v2 adds a challenge-response handshake BEFORE any
// hello/delta is processed. Both sides challenge each other (mutual auth);
// neither side's hello/delta is honored until its peer has proven possession
// of a rostered device key. Unauthenticated frames are dropped, not queued —
// there is no partial trust state.
import { VersionVector } from 'loro-crdt'
import type { VaultRepository } from '../stores/vaultStore'
import { getRosterEntry } from './roster'
import type { DeviceKeyPair } from './deviceAuth'
import { verifySignature } from './deviceAuth'
import { encodeFrames, FrameAssembler, type VaultDuplex } from './duplex'

const BROADCAST_DEBOUNCE_MS = 100
const NONCE_BYTES = 32

/** One live pairing session between this device's vault and one peer. */
export class VaultPeerSession {
  private readonly assembler = new FrameAssembler()
  private peerVersion: VersionVector | null = null
  private nextMsgId = 1
  private broadcastTimer: ReturnType<typeof setTimeout> | null = null
  private readonly unsubscribe: () => void

  /** Nonce THIS device sent the peer, awaiting their signed response. */
  private outstandingNonce: Uint8Array | null = null
  /** Whether the peer has proven possession of a rostered key. Nothing from
   * `onFrame` other than `challenge`/`response` is honored until this flips. */
  private peerAuthenticated = false
  /** Serializes frame processing: `challenge`/`response` handling awaits a
   * signature (async), so without this a `hello` delivered microtasks later
   * — but before that await resolves — would see `peerAuthenticated` still
   * false and be dropped instead of waiting. Every frame chains onto the
   * same promise, so processing order matches DELIVERY order exactly. */
  private processingChain: Promise<void> = Promise.resolve()

  constructor(
    private readonly vault: VaultRepository,
    private readonly duplex: VaultDuplex,
    private readonly deviceKey: DeviceKeyPair,
  ) {
    duplex.onFrame((frame) => {
      this.processingChain = this.processingChain.then(() => this.onFrame(frame))
    })
    // Local commits propagate as deltas (debounced to batch mutation bursts) —
    // but only once the peer is authenticated (queued otherwise, see scheduleBroadcast).
    this.unsubscribe = this.vault.doc.subscribe((event) => {
      if (event.by === 'local') this.scheduleBroadcast()
    })
    this.sendChallenge()
  }

  close(): void {
    if (this.broadcastTimer) clearTimeout(this.broadcastTimer)
    this.unsubscribe()
    this.duplex.close()
  }

  private send(message: Parameters<typeof encodeFrames>[0]): void {
    for (const frame of encodeFrames(message, this.nextMsgId++)) {
      this.duplex.send(frame)
    }
  }

  private sendChallenge(): void {
    const nonce = crypto.getRandomValues(new Uint8Array(NONCE_BYTES))
    this.outstandingNonce = nonce
    this.send({ kind: 'challenge', nonce, deviceId: this.deviceKey.deviceId })
  }

  private sendHello(): void {
    this.send({ kind: 'hello', versionVector: this.vault.doc.version().encode() })
  }

  private sendDeltaSince(peerVersion: VersionVector | null): void {
    const update = peerVersion
      ? this.vault.doc.export({ mode: 'update', from: peerVersion })
      : this.vault.doc.export({ mode: 'update' })
    if (update.length > 0) this.send({ kind: 'delta', update })
    this.peerVersion = this.vault.doc.version()
  }

  private scheduleBroadcast(): void {
    if (!this.peerAuthenticated) return // nothing to send to an unproven peer
    if (this.broadcastTimer) clearTimeout(this.broadcastTimer)
    this.broadcastTimer = setTimeout(() => this.sendDeltaSince(this.peerVersion), BROADCAST_DEBOUNCE_MS)
  }

  private async onFrame(frame: Uint8Array): Promise<void> {
    const message = this.assembler.push(frame)
    if (!message) return

    if (message.kind === 'challenge') {
      const signature = await this.deviceKey.sign(message.nonce)
      this.send({
        kind: 'response',
        nonce: message.nonce,
        deviceId: this.deviceKey.deviceId,
        publicKey: this.deviceKey.publicKey,
        signature,
      })
      return
    }

    if (message.kind === 'response') {
      if (!this.outstandingNonce || !bytesEqual(this.outstandingNonce, message.nonce)) {
        return // not our nonce — replay or stale response, drop
      }
      const rostered = getRosterEntry(this.vault.doc, message.deviceId)
      if (!rostered) return // unrostered device — refused, not queued
      // The peer's claimed public key must match the roster entry — a valid
      // signature from a DIFFERENT key than the roster's is not proof of
      // membership, it is proof of possessing some other key.
      const rosteredKeyBytes = base64ToBytes(rostered.publicKey)
      if (!bytesEqual(rosteredKeyBytes, message.publicKey)) return
      const verified = await verifySignature(message.publicKey, message.nonce, message.signature)
      if (!verified) return

      this.outstandingNonce = null
      this.peerAuthenticated = true
      this.sendHello()
      return
    }

    // Everything below requires an authenticated peer — fail closed.
    if (!this.peerAuthenticated) return

    if (message.kind === 'hello') {
      const theirs = VersionVector.decode(message.versionVector)
      this.sendDeltaSince(theirs)
      return
    }
    // Delta: commutative import; convergence needs no ordering.
    this.vault.doc.import(message.update)
    this.peerVersion = this.vault.doc.version()
  }
}

function bytesEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false
  return true
}
function base64ToBytes(b64: string): Uint8Array {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0))
}
