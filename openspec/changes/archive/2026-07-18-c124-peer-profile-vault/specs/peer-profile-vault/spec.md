## ADDED Requirements

### Requirement: Structural exclusion of local-class data
The sync write queue SHALL refuse, at enqueue time, any row whose table
classifies `local` — including every UNDECLARED table (fail-closed default).
Server-syncable tables MUST be explicitly declared `public` or `trusted`.

#### Scenario: Vault table never reaches the server queue
- **WHEN** a write targeting an undeclared or local-class table (e.g. `_vault_state`) is enqueued
- **THEN** enqueue fails terminally and nothing durable happens on the sync path

### Requirement: Loro profile vault
Sensitive profile data, private preferences, and agent-learned user facts SHALL
live in one Loro document per vault (maps: profile, preferences, agent_facts),
persisted locally as encoded snapshots (`_vault_state`), accessed only through a
typed repository facade, and never registered as a PEM entity or sync scope.

#### Scenario: Vault survives restart locally
- **WHEN** the vault is mutated, flushed, and reopened from the local store
- **THEN** all fields are present without any server round-trip

### Requirement: Device-to-device CRDT sync over peer channels
Vault convergence SHALL use version-vector exchange plus
export-updates-since deltas over a transport-agnostic duplex, chunked to 16 KiB
frames (messages ≤ 256 KiB), with WebRTC DataChannels as the browser-capable
lane and signaling treated as an untrusted pipe (dev manual signaler now, FRF
SignalService as the production swap).

#### Scenario: Two paired devices converge bidirectionally
- **WHEN** two devices with divergent vault state connect over a duplex
- **THEN** both reach identical state, later mutations propagate as deltas, and
  out-of-order frame delivery still reassembles correctly
