// TJ-ARCH-MOB-001 compliant — WebRTC DataChannel adapter for vault peer sync.
// The browser-capable device-to-device lane (references/sync/peer-crdt.md).
// This shim is DUMB: it moves frames and surfaces events; every protocol
// decision lives in VaultPeerSession. Signaling here is the dev lane (manual
// offer/answer copy — QR/paste); production signaling is FRF SignalService,
// swapped as configuration, not redesign. The signaler is untrusted by design:
// it sees only SDP blobs, never vault bytes (DTLS underneath).
import type { VaultDuplex } from './duplex'

const CHANNEL_LABEL = 'vault-sync-v1'

class DataChannelDuplex implements VaultDuplex {
  private handler: ((frame: Uint8Array) => void) | null = null

  constructor(
    private readonly connection: RTCPeerConnection,
    private readonly channel: RTCDataChannel,
  ) {
    channel.binaryType = 'arraybuffer'
    channel.onmessage = (event: MessageEvent<ArrayBuffer>) => {
      this.handler?.(new Uint8Array(event.data))
    }
  }

  send(frame: Uint8Array): void {
    if (this.channel.readyState !== 'open') return
    // Copy into a plain ArrayBuffer — RTCDataChannel.send's typing rejects
    // views over ArrayBufferLike (SharedArrayBuffer).
    const buffer = new ArrayBuffer(frame.byteLength)
    new Uint8Array(buffer).set(frame)
    this.channel.send(buffer)
  }

  onFrame(handler: (frame: Uint8Array) => void): void {
    this.handler = handler
  }

  close(): void {
    this.channel.close()
    this.connection.close()
  }
}

function waitForOpen(channel: RTCDataChannel): Promise<void> {
  if (channel.readyState === 'open') return Promise.resolve()
  return new Promise((resolve, reject) => {
    channel.onopen = () => resolve()
    channel.onerror = () => reject(new Error('vault DataChannel failed to open'))
  })
}

/** Gathered-ICE local description as a pastable/QR-able dev-signaling blob. */
async function localDescriptionBlob(connection: RTCPeerConnection): Promise<string> {
  await new Promise<void>((resolve) => {
    if (connection.iceGatheringState === 'complete') return resolve()
    connection.onicegatheringstatechange = () => {
      if (connection.iceGatheringState === 'complete') resolve()
    }
  })
  return JSON.stringify(connection.localDescription)
}

export interface OfferSession {
  /** Give this blob to the other device (paste/QR — the dev signaler). */
  offer: string
  /** Complete the pairing with the answering device's blob. */
  accept(answer: string): Promise<VaultDuplex>
}

/** Initiator side of a pairing. */
export async function createOfferSession(config?: RTCConfiguration): Promise<OfferSession> {
  const connection = new RTCPeerConnection(config)
  const channel = connection.createDataChannel(CHANNEL_LABEL)
  await connection.setLocalDescription(await connection.createOffer())
  const offer = await localDescriptionBlob(connection)
  return {
    offer,
    async accept(answer: string): Promise<VaultDuplex> {
      await connection.setRemoteDescription(JSON.parse(answer) as RTCSessionDescriptionInit)
      await waitForOpen(channel)
      return new DataChannelDuplex(connection, channel)
    },
  }
}

/** Responder side: consume the offer blob, produce the answer blob. */
export async function acceptOfferSession(
  offer: string,
  config?: RTCConfiguration,
): Promise<{ answer: string; duplex: Promise<VaultDuplex> }> {
  const connection = new RTCPeerConnection(config)
  const channelReady = new Promise<RTCDataChannel>((resolve) => {
    connection.ondatachannel = (event) => resolve(event.channel)
  })
  await connection.setRemoteDescription(JSON.parse(offer) as RTCSessionDescriptionInit)
  await connection.setLocalDescription(await connection.createAnswer())
  const answer = await localDescriptionBlob(connection)
  const duplex = channelReady.then(async (channel) => {
    await waitForOpen(channel)
    return new DataChannelDuplex(connection, channel)
  })
  return { answer, duplex }
}
