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
  // C-130 protocol v2: a peer session opens with a challenge/response
  // handshake BEFORE any hello/delta is processed (see peerSync.ts). Payload
  // is JSON-in-bytes since these carry structured fields, not raw CRDT bytes.
  | { kind: 'challenge'; nonce: Uint8Array; deviceId: string }
  | { kind: 'response'; nonce: Uint8Array; deviceId: string; publicKey: Uint8Array; signature: Uint8Array }

const KIND_HELLO = 1
const KIND_DELTA = 2
const KIND_CHALLENGE = 3
const KIND_RESPONSE = 4

function textEncode(value: unknown): Uint8Array {
  return new TextEncoder().encode(JSON.stringify(value))
}
function textDecode(bytes: Uint8Array): unknown {
  return JSON.parse(new TextDecoder().decode(bytes))
}
function bytesToB64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
}
function b64ToBytes(b64: string): Uint8Array {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0))
}

/** Encode one logical message into 16 KiB frames: [msgId u32][seq u16][total u16][kind u8][chunk]. */
export function encodeFrames(message: VaultMessage, msgId: number): Uint8Array[] {
  let kind: number
  let payload: Uint8Array
  switch (message.kind) {
    case 'hello':
      kind = KIND_HELLO
      payload = message.versionVector
      break
    case 'delta':
      kind = KIND_DELTA
      payload = message.update
      break
    case 'challenge':
      kind = KIND_CHALLENGE
      payload = textEncode({ nonce: bytesToB64(message.nonce), deviceId: message.deviceId })
      break
    case 'response':
      kind = KIND_RESPONSE
      payload = textEncode({
        nonce: bytesToB64(message.nonce),
        deviceId: message.deviceId,
        publicKey: bytesToB64(message.publicKey),
        signature: bytesToB64(message.signature),
      })
      break
  }
  if (payload.length > MAX_MESSAGE_BYTES) {
    throw new Error(`vault message exceeds ${MAX_MESSAGE_BYTES} bytes — blobs do not go in the doc`)
  }
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
    switch (entry.kind) {
      case KIND_HELLO:
        return { kind: 'hello', versionVector: payload }
      case KIND_DELTA:
        return { kind: 'delta', update: payload }
      case KIND_CHALLENGE: {
        const { nonce, deviceId } = textDecode(payload) as { nonce: string; deviceId: string }
        return { kind: 'challenge', nonce: b64ToBytes(nonce), deviceId }
      }
      case KIND_RESPONSE: {
        const { nonce, deviceId, publicKey, signature } = textDecode(payload) as {
          nonce: string
          deviceId: string
          publicKey: string
          signature: string
        }
        return {
          kind: 'response',
          nonce: b64ToBytes(nonce),
          deviceId,
          publicKey: b64ToBytes(publicKey),
          signature: b64ToBytes(signature),
        }
      }
      default:
        return null // unknown frame kind — drop rather than crash (forward-compat)
    }
  }
}
