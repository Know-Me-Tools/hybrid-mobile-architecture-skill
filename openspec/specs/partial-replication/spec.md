# partial-replication Specification

## Purpose
TBD - created by archiving change c122-partial-replication-slice. Update Purpose after archive.
## Requirements
### Requirement: Scope-declared partial replication
Clients SHALL replicate only declared sync scopes. A `UserSubset` scope without a
tenant parameter SHALL be refused at validation (fail closed); scope names and
parameter values SHALL match the allowlist `^[a-zA-Z0-9_-]{1,128}$`. The frozen
`SyncTransport` seam SHALL expose scope attachment via `start_scopes` with a
default that preserves existing transports.

#### Scenario: Tenantless scope refused
- **WHEN** a user-subset scope lacking the tenant parameter is attached
- **THEN** validation fails before any transport work and nothing replicates

#### Scenario: Loopback slice runs without a gateway
- **WHEN** scopes attach through the loopback transport and row batches are fed
- **THEN** rows apply atomically to the local store and status reaches Live

### Requirement: Lookup currency
Shared lookup/metatype bundles SHALL re-validate with `If-None-Match` and apply
only changed content, recording `(name, version, etag)` in a version ledger; a
version bump observed on the sync stream SHALL trigger refetch only when newer.

#### Scenario: Unchanged bundle does not reapply
- **WHEN** a bundle at the ledgered version is revalidated
- **THEN** the outcome is Current and no seed SQL executes

### Requirement: One-time onboarding loads
Boot SHALL order migrations → seed/lookup → pre-onboarding load → onboarding →
post-onboarding load → sync attach, as typestate states. Loads SHALL be
idempotent via a load ledger, and a failing load SHALL defer (retry next boot)
rather than block onboarding.

#### Scenario: Load runs exactly once
- **WHEN** the same pre-onboarding load runs on two consecutive boots
- **THEN** the second boot reports AlreadyLoaded and executes nothing

#### Scenario: Failing post-onboarding load degrades
- **WHEN** a post-onboarding load fails
- **THEN** boot completes, the result is Deferred, and the load retries on the
  next boot because the ledger was not advanced

