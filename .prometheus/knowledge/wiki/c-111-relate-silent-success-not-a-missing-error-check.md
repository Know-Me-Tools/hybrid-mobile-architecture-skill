---
type: Reference
id: c-111-relate-silent-success-not-a-missing-error-check
title: "C-111 RELATE bug was silent success, not a missing error check"
tags:
- surrealdb
- graph-store
- error-handling
timestamp: 2026-07-17T00:00:00Z
created_at: 2026-07-17T00:00:00Z
updated_at: 2026-07-17T00:00:00Z
revision: 1
---

# C-111 RELATE bug was silent success, not a missing error check

_2026-07-17 — phase-codegen-and-ci-verification, gen_ui_db_graph_

## What was asked vs what was true

The task was scoped as an error-handling gap: `GraphStore::relate()` discards its
`Response` without `take_errors()`, and SurrealDB reports statement failures there rather
than as a query-level `Err` — so `relate()` could not report a failed edge write. The
premise was that this silence "directly enabled the C-111 graph_expand bug", which had
already been fixed.

Both halves of the premise were wrong:

1. **The C-111 bug was still live in the code.** `relate()` was still using
   `entity:⟨$from⟩` endpoints.
2. **`take_errors()` could never have caught it.** Verified by a side-by-side live probe
   against surrealdb-core 3.2.1 (both forms, one in-memory DB):

```
CHEVRON take_errors: {}        <- EMPTY. no error, at any level
PAREN   take_errors: {}
EDGES WRITTEN:
    ["a", "b", "paren"]        <- correct
    ["$from", "$to", "chev"]   <- literal param names as record keys
TRAVERSAL FROM a: [["b"]]      <- only the paren edge is reachable
```

The chevron form parses, executes, and reports complete success while writing an edge
between records literally keyed `"$from"`/`"$to"`. `⟨⟩` is escaped-IDENTIFIER syntax, not
parameter interpolation. The in-code comment asserted the opposite ("the id is still
bound, so this is not string interpolation") — that wrong comment is what made the bug
durable across two sessions.

## Why this mattered to the fix

Adding only the requested guard and un-ignoring `graph_expand_traverses_relate_edges`
would have produced a red test with no explanation. Adding the guard and leaving the test
ignored would have shipped a guard that looks like a fix over live-broken traversal.
The guard is worth having — but for level-2 failures, not this one.

## Three failure levels (the durable lesson)

1. **Query-level `Err`** — caught by `.await?`.
2. **Per-statement error** — reported only inside the `Response`; `.await?` still returns
   `Ok`. Needs `take_errors()`, or `take(i)?` which surfaces statement `i` incidentally.
3. **Silent wrong success** — statement succeeds, does the wrong thing. Invisible at
   levels 1 and 2. Only a behaviour assertion on what was written/read back catches it.

Attributing a level-3 bug to a level-2 gap and "fixing" it with an error check is a no-op
that produces false confidence.

## Changes

- `relate()` → parenthesized `(type::record('entity', $from))` endpoints. Comment now
  states the chevron trap instead of asserting its safety.
- `error::check_statements(&mut IndexedResults, ctx)` — one `pub(crate)` guard, applied to
  the six sites that never checked: `relate`, `upsert_provider`, `delete_provider`,
  `upsert_model_pref`, `set_setting`, and `init` (which had it inline). Its doc states it
  catches *reported* failures only, so it is not mistaken for a C-111 guard again.
- **`memory_search()` — unrequested find, same silent class, in shipping code.** It takes
  only the last statement, so a failed `LET $vs`/`LET $ft` lane went unreported and
  silently degraded hybrid search to a single lane while returning plausible rows. Guarded.
- Tests: un-ignored `graph_expand_traverses_relate_edges`; added
  `relate_rejected_by_db_surfaces_error` (guard) and
  `relate_binds_endpoint_ids_not_literal_param_names` (the actual defect).

## Deviations from the brief

- Asked for a test that a RELATE to a *nonexistent* endpoint errors. It does not —
  SurrealDB relates not-yet-created records without complaint. Used a genuine constraint
  violation instead (`relates_to` is `TYPE RELATION FROM entity TO entity`; relating from
  `provider` violates it). The requested test would have asserted behaviour the DB lacks.
- The C-111 regression test asserts on stored edge keys, not on an error, because no error
  path can detect it.
- Added two `#[doc(hidden)]` test-only accessors (`relate_raw_for_test`,
  `edge_endpoints_for_test`): the crate deliberately keeps SurrealQL private, so neither
  failure was reachable through the public intent API.

## Verification

Falsified before trusting: reverted `relate()` to the chevron form and confirmed the tests
go red for the right reason —

```
edge should be keyed by bound ids, got [("$from", "$to")]
1-hop neighbour b should be present: []
TEST_EXIT=101
```

`relate_rejected_by_db_surfaces_error` stayed **green** through that revert — empirical
proof the error guard cannot detect C-111. Restored: clippy + 6/6 tests green, 0 ignored.

## Harness traps hit (both the same shape as the bug)

- **`cargo … | tail` reports tail's exit code.** A build failing with E0425 was reported as
  "exit code 0"; caught only by reading the output file. Stamp `$?` in-band before any pipe.
- **A failed `cp` restore left the worktree in the deliberately-broken experimental state.**
  Reported as a task failure, but had the output gone unread, the chevron form would have
  been committed as the fix.

Read outputs; do not trust status lines.
