# pem-scope-bridge Specification

## Purpose
TBD - created by archiving change c126-pem-scope-bridge. Update Purpose after archive.
## Requirements
### Requirement: App-side PEM scope bridge
The desktop/web PGlite tier SHALL feed local table changes into PEM's entity
graph via PGlite's `live` extension, so that any local row change — whether
from a UI mutation or a future scope-stream write — invalidates PEM reactivity
without feature code being sync-aware. Table-scoped live queries SHALL be
disposed when the entity runtime tears down.

#### Scenario: A change notification invalidates the bridged entity type
- **WHEN** the underlying live query delivers a change notification for a
  bridged table
- **THEN** the corresponding PEM entity type is invalidated

#### Scenario: Unsubscribe stops further invalidation
- **WHEN** a bridge's `unsubscribe()` is called
- **THEN** no further invalidation occurs even if a notification arrives after
  teardown began

### Requirement: PEM ListQuery is honored, not ignored
The PGlite entity transport SHALL compile PEM's `ListQuery` (filter, sort,
limit, cursor) into parameterized SQL via PEM's own `toSQLClauses`, always
ANDing a tenant predicate onto the compiled WHERE clause. It SHALL NOT fetch
all rows and ignore the query (retiring the pre-C-104 behavior).

#### Scenario: Query never widens past the tenant boundary
- **WHEN** a ListQuery with no filter is compiled for a given tenant
- **THEN** the resulting SQL still restricts results to that tenant

#### Scenario: Filter, sort, limit, and cursor are honored
- **WHEN** a ListQuery specifies a filter, a sort, a limit, and a cursor
- **THEN** the compiled SQL and its results reflect all four

### Requirement: One queue for entity mutations
Entity mutations (e.g. conversation save/delete) SHALL route through PEM's
`createGraphAction` (optimistic apply + durable run + replay-on-failure)
rather than a manual optimistic `useGraphStore` call paired with a separate
persistence write. There is no second, hand-rolled write queue.

#### Scenario: Save routes through one durable action
- **WHEN** a conversation is saved
- **THEN** the optimistic graph update and the durable persistence write both
  happen inside a single `createGraphAction`, with no separate manual
  `useGraphStore` call outside that action

