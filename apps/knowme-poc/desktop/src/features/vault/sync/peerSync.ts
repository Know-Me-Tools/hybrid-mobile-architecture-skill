// TJ-ARCH-MOB-001 compliant — the vault peer-sync protocol
// (references/sync/peer-crdt.md): exchange version vectors, send
// export_updates_since deltas both ways, converge commutatively, repeat on
// mutation (debounced, delta-only). Transport-agnostic over VaultDuplex.
import { VersionVector } from 'loro-crdt'
import type { VaultRepository } from '../stores/vaultStore'
import { encodeFrames, FrameAssembler, type VaultDuplex } from './duplex'

const BROADCAST_DEBOUNCE_MS = 100

/** One live pairing session between this device's vault and one peer. */
export class VaultPeerSession {
  private readonly assembler = new FrameAssembler()
  private peerVersion: VersionVector | null = null
  private nextMsgId = 1
  private broadcastTimer: ReturnType<typeof setTimeout> | null = null
  private readonly unsubscribe: () => void

  constructor(
    private readonly vault: VaultRepository,
    private readonly duplex: VaultDuplex,
  ) {
    duplex.onFrame((frame) => this.onFrame(frame))
    // Local commits propagate as deltas (debounced to batch mutation bursts).
    this.unsubscribe = this.vault.doc.subscribe((event) => {
      if (event.by === 'local') this.scheduleBroadcast()
    })
    this.sendHello()
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
    if (this.broadcastTimer) clearTimeout(this.broadcastTimer)
    this.broadcastTimer = setTimeout(() => this.sendDeltaSince(this.peerVersion), BROADCAST_DEBOUNCE_MS)
  }

  private onFrame(frame: Uint8Array): void {
    const message = this.assembler.push(frame)
    if (!message) return
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
