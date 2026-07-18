// TJ-ARCH-MOB-001 compliant — in-memory duplex pair implementing the same
// chunked-frame contract as the WebRTC lane. The legitimate test double at
// this IO boundary (no mocks of protocol internals).
import type { VaultDuplex } from './duplex'

class MemoryEnd implements VaultDuplex {
  private handler: ((frame: Uint8Array) => void) | null = null
  private peer: MemoryEnd | null = null
  private closed = false

  connect(peer: MemoryEnd): void {
    this.peer = peer
  }

  send(frame: Uint8Array): void {
    if (this.closed || !this.peer) return
    const target = this.peer
    // Async delivery mirrors a real channel (no re-entrant handler stacks).
    queueMicrotask(() => {
      if (!target.closed) target.handler?.(frame)
    })
  }

  onFrame(handler: (frame: Uint8Array) => void): void {
    this.handler = handler
  }

  close(): void {
    this.closed = true
  }
}

export function memoryDuplexPair(): [VaultDuplex, VaultDuplex] {
  const a = new MemoryEnd()
  const b = new MemoryEnd()
  a.connect(b)
  b.connect(a)
  return [a, b]
}
