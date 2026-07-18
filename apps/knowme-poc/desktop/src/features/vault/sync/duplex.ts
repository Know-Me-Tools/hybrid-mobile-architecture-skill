// TJ-ARCH-MOB-001 compliant — transport seam + framing for vault peer sync.
// Any byte pipe between two of the user's devices can carry the protocol:
// WebRTC DataChannels (production/browser lane), an in-memory pair (tests).
// Frames are 16 KiB; logical messages reassemble up to 256 KiB.

/** A bidirectional byte pipe to ONE paired peer. Dumb by design. */
export interface VaultDuplex {
  send(frame: Uint8Array): void
  onFrame(handler: (frame: Uint8Array) => void): void
  close(): void
}

export const FRAME_PAYLOAD_BYTES = 16 * 1024 - 9 // 16 KiB frame incl. 9-byte header
export const MAX_MESSAGE_BYTES = 256 * 1024

export type VaultMessage =
  | { kind: 'hello'; versionVector: Uint8Array }
  | { kind: 'delta'; update: Uint8Array }

const KIND_HELLO = 1
const KIND_DELTA = 2

/** Encode one logical message into 16 KiB frames: [msgId u32][seq u16][total u16][kind u8][chunk]. */
export function encodeFrames(message: VaultMessage, msgId: number): Uint8Array[] {
  const payload = message.kind === 'hello' ? message.versionVector : message.update
  if (payload.length > MAX_MESSAGE_BYTES) {
    throw new Error(`vault message exceeds ${MAX_MESSAGE_BYTES} bytes — blobs do not go in the doc`)
  }
  const kind = message.kind === 'hello' ? KIND_HELLO : KIND_DELTA
  const total = Math.max(1, Math.ceil(payload.length / FRAME_PAYLOAD_BYTES))
  const frames: Uint8Array[] = []
  for (let seq = 0; seq < total; seq++) {
    const chunk = payload.subarray(seq * FRAME_PAYLOAD_BYTES, (seq + 1) * FRAME_PAYLOAD_BYTES)
    const frame = new Uint8Array(9 + chunk.length)
    const view = new DataView(frame.buffer)
    view.setUint32(0, msgId)
    view.setUint16(4, seq)
    view.setUint16(6, total)
    view.setUint8(8, kind)
    frame.set(chunk, 9)
    frames.push(frame)
  }
  return frames
}

/** Reassembles frames into logical messages (per-peer instance). */
export class FrameAssembler {
  private readonly partial = new Map<number, { kind: number; total: number; chunks: Map<number, Uint8Array> }>()

  push(frame: Uint8Array): VaultMessage | null {
    const view = new DataView(frame.buffer, frame.byteOffset)
    const msgId = view.getUint32(0)
    const seq = view.getUint16(4)
    const total = view.getUint16(6)
    const kind = view.getUint8(8)
    const chunk = frame.subarray(9)

    let entry = this.partial.get(msgId)
    if (!entry) {
      entry = { kind, total, chunks: new Map() }
      this.partial.set(msgId, entry)
    }
    entry.chunks.set(seq, chunk)
    if (entry.chunks.size < entry.total) return null

    this.partial.delete(msgId)
    const size = [...entry.chunks.values()].reduce((n, c) => n + c.length, 0)
    const payload = new Uint8Array(size)
    let offset = 0
    for (let i = 0; i < entry.total; i++) {
      const part = entry.chunks.get(i)
      if (!part) return null // missing sequence — drop (peer will resend on next delta)
      payload.set(part, offset)
      offset += part.length
    }
    return entry.kind === KIND_HELLO
      ? { kind: 'hello', versionVector: payload }
      : { kind: 'delta', update: payload }
  }
}
