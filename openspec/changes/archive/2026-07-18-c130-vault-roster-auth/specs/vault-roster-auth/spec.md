## ADDED Requirements

### Requirement: Device keypair and signed roster
Each device SHALL hold an Ed25519 keypair (WebCrypto primary, `@noble/ed25519`
fallback for pre-Ed25519-WebCrypto webviews), with the private key stored
locally and never entering the vault doc. The vault doc SHALL carry a signed
roster of trusted device public keys, added on pairing and removed on
revocation, so roster changes converge via the vault's own CRDT.

#### Scenario: Roster changes propagate via CRDT
- **WHEN** a device is added to or removed from the roster
- **THEN** that change is a normal vault-doc mutation and syncs to other
  rostered devices like any other write

### Requirement: Mutual challenge-response before hello/delta
A vault peer session SHALL perform a nonce challenge-response handshake
before honoring any `hello` or `delta` frame from that peer. A peer's claimed
device id and public key MUST match a roster entry, and the signature over
the nonce MUST verify, before that peer is treated as authenticated.
Unauthenticated frames are dropped, not queued.

#### Scenario: Rostered peer converges after handshake
- **WHEN** two devices with mutual roster entries connect
- **THEN** both complete the challenge-response handshake and their vaults
  converge bidirectionally

#### Scenario: Unrostered peer never converges
- **WHEN** a peer with no roster entry connects
- **THEN** its hello/delta frames are dropped and no vault data crosses

#### Scenario: Revoked peer is cut off
- **WHEN** a previously-paired device is removed from the roster and a new
  session is opened
- **THEN** that device's frames are refused and further mutations do not
  reach it

### Requirement: Frame processing is delivery-ordered
Peer session frame handling SHALL serialize processing so that a frame
delivered after another is never processed first, even though
challenge/response handling is asynchronous (awaits a signature operation).

#### Scenario: A hello arriving during an in-flight signature is not dropped
- **WHEN** a `hello` frame is delivered while this session's own
  challenge-response signature verification is still pending
- **THEN** the `hello` is processed after authentication completes, not
  dropped for arriving "too early"
