## ADDED Requirements

### Requirement: Sync doctrine reference documentation
The skill package SHALL provide binding local-first reference documentation under
`references/sync/` covering: the three-way data split, invariants LFS-INV-1…7, the
offline write-queue state machine, fail-closed rules, the thin-client fallback,
partial replication (scope descriptors, lookup currency, onboarding loads), the
peer-CRDT profile vault, the client-side RAG retrieval loop, and ratified decisions
ADR-LFS-1…5. The CLAUDE.md reference index SHALL list every `references/sync/*` doc.

#### Scenario: Sync work consults the doctrine
- **WHEN** an agent or developer begins any sync, replication, realtime, or
  offline-storage work in this repo or a scaffolded project
- **THEN** `references/sync/doctrine.md` SHALL be discoverable from the CLAUDE.md
  reference index and its invariants SHALL be treated as review-blocking rules

#### Scenario: Never-server data has a composed design
- **WHEN** a feature stores `local`-class (sensitive/profile) data
- **THEN** `references/sync/peer-crdt.md` SHALL define the complete flow (privacy
  classes, structural enqueue exclusion, Loro vault, WebRTC device-to-device sync,
  pairing and signaling) without requiring any server-persisted copy

#### Scenario: Open decisions are ratified or explicitly deferred
- **WHEN** implementation requires a stance on master-plan open decisions OD-2, OD-3,
  OD-4, OD-7, or the CRDT choice
- **THEN** `references/sync/decisions.md` SHALL record the ratified decision and its
  blast radius, and decisions outside phase scope SHALL be listed as deferred
