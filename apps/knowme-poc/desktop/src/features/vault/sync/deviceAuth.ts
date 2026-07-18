// TJ-ARCH-MOB-001 compliant — C-130: vault pairing hardening.
// Every device has an Ed25519 keypair; the private key NEVER enters the Loro
// doc (it stays in the platform's own local storage). The vault doc carries
// a signed ROSTER of trusted device public keys, so the roster itself
// converges via CRDT and revocation propagates like any other vault write.
//
// Primary: WebCrypto Ed25519 (native, fast, available since Node 24 / recent
// Chromium/WebKit). Fallback: @noble/ed25519 for older WKWebView builds
// (macOS 10.15 is this app's stated minimum — Safari there predates
// WebCrypto Ed25519 support, per tauri.conf.json).
import * as nobleEd25519 from '@noble/ed25519'

export interface DeviceKeyPair {
  deviceId: string
  publicKey: Uint8Array
  sign(message: Uint8Array): Promise<Uint8Array>
}

interface StoredKeyMaterial {
  deviceId: string
  publicKey: string // base64
  privateKey: string // base64 — local-only, never synced (see doc comment above)
}

const DEVICE_KEY_STORAGE_KEY = 'knowme.vault.device-key.v1'

function toBase64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
}
function fromBase64(b64: string): Uint8Array {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0))
}

/** WebCrypto's typings require a view over a plain `ArrayBuffer`, not the
 * broader `ArrayBufferLike` a `Uint8Array` may carry — copy defensively. */
function toArrayBufferView(bytes: Uint8Array): Uint8Array<ArrayBuffer> {
  const buffer = new ArrayBuffer(bytes.byteLength)
  new Uint8Array(buffer).set(bytes)
  return new Uint8Array(buffer)
}

async function webCryptoEd25519Available(): Promise<boolean> {
  try {
    await crypto.subtle.generateKey('Ed25519', false, ['sign', 'verify'])
    return true
  } catch {
    return false
  }
}

async function generateKeyMaterial(): Promise<{ publicKey: Uint8Array; privateKeyRaw: Uint8Array }> {
  if (await webCryptoEd25519Available()) {
    const pair = (await crypto.subtle.generateKey('Ed25519', true, ['sign', 'verify'])) as CryptoKeyPair
    const publicKey = new Uint8Array(await crypto.subtle.exportKey('raw', pair.publicKey))
    const privateKeyRaw = new Uint8Array(await crypto.subtle.exportKey('pkcs8', pair.privateKey))
    return { publicKey, privateKeyRaw }
  }
  const { secretKey, publicKey } = await nobleEd25519.keygenAsync()
  return { publicKey, privateKeyRaw: secretKey }
}

/** Load this device's keypair from local storage, generating one on first use. */
export async function loadOrCreateDeviceKey(
  storage: Pick<Storage, 'getItem' | 'setItem'> = localStorage,
): Promise<DeviceKeyPair> {
  const existing = storage.getItem(DEVICE_KEY_STORAGE_KEY)
  if (existing) {
    const material = JSON.parse(existing) as StoredKeyMaterial
    return keyPairFromMaterial(material)
  }
  const { publicKey, privateKeyRaw } = await generateKeyMaterial()
  const deviceId = crypto.randomUUID()
  const material: StoredKeyMaterial = {
    deviceId,
    publicKey: toBase64(publicKey),
    privateKey: toBase64(privateKeyRaw),
  }
  storage.setItem(DEVICE_KEY_STORAGE_KEY, JSON.stringify(material))
  return keyPairFromMaterial(material)
}

async function keyPairFromMaterial(material: StoredKeyMaterial): Promise<DeviceKeyPair> {
  const publicKey = fromBase64(material.publicKey)
  const privateKeyRaw = fromBase64(material.privateKey)
  const webCryptoKey = await importPkcs8IfPossible(privateKeyRaw)
  return {
    deviceId: material.deviceId,
    publicKey,
    sign: async (message) => {
      if (webCryptoKey) {
        return new Uint8Array(
          await crypto.subtle.sign('Ed25519', webCryptoKey, toArrayBufferView(message)),
        )
      }
      return nobleEd25519.signAsync(message, privateKeyRaw)
    },
  }
}

async function importPkcs8IfPossible(privateKeyRaw: Uint8Array): Promise<CryptoKey | null> {
  try {
    return await crypto.subtle.importKey(
      'pkcs8',
      toArrayBufferView(privateKeyRaw),
      'Ed25519',
      false,
      ['sign'],
    )
  } catch {
    return null // stored as a noble raw secret key — sign via noble instead
  }
}

/** Verify `signature` over `message` against a rostered public key. */
export async function verifySignature(
  publicKey: Uint8Array,
  message: Uint8Array,
  signature: Uint8Array,
): Promise<boolean> {
  if (await webCryptoEd25519Available()) {
    try {
      const key = await crypto.subtle.importKey(
        'raw',
        toArrayBufferView(publicKey),
        'Ed25519',
        false,
        ['verify'],
      )
      return await crypto.subtle.verify(
        'Ed25519',
        key,
        toArrayBufferView(signature),
        toArrayBufferView(message),
      )
    } catch {
      // fall through to noble — WebCrypto Ed25519 detection can be a false
      // positive for import/verify specifically on some engines
    }
  }
  return nobleEd25519.verifyAsync(signature, message, publicKey)
}
