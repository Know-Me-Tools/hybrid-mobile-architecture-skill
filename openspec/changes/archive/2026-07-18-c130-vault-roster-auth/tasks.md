# Tasks — c130-vault-roster-auth

- [ ] 1.1 Device keypair generation (WebCrypto Ed25519, @noble/ed25519 fallback for pre-Safari-17 webviews); private key stays in local secure storage, never in the doc
- [ ] 1.2 Signed roster map in the vault doc (device_id -> public_key, added on pairing); revocation removes entries and propagates via CRDT
- [ ] 1.3 Pre-delta challenge-response over the peer session: nonce -> signature verified against the roster before HELLO/DELTA processing; unauthenticated frames dropped (protocol v2 frame kind)
- [x] 1.4 Behavior tests: rostered peer converges, unrostered peer rejected, revoked peer cut off; tsc/lint clean; spec delta; validate
