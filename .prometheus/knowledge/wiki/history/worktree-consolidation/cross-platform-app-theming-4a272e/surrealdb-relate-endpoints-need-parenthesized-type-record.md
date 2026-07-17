<!-- source=cross-platform-app-theming-4a272e; branch=claude/cross-platform-app-theming-4a272e; original_sha256=e819a88a349a53bd0462393b8d6defc4a9a6079d59f2a9f6db77bd6fef395ea6 -->
# SurrealDB RELATE endpoints need parenthesized type::record — chevrons silently corrupt edges

**Date:** 2026-07-16
**Phase:** phase-codegen-and-ci-verification (C-111 follow-up)
**Component:** `apps/knowme-poc/rust/crates/gen_ui_db_graph`
**Status:** Fixed and VERIFIED — `cargo test -p gen_ui_db_graph --test it` →
`5 passed; 0 failed; 0 ignored`. `graph_expand_traverses_relate_edges` un-`#[ignore]`d
and unweakened.

## Symptom

After C-111 cleared the parse errors, `create_entity()` + `relate()` both returned
`Ok`, but `graph_expand("a", 2)` returned `[]`. The 1-hop neighbour was never found.
The prior note framed it as an either/or: edges not persisted, **or** the traversal
query not reading them back under 3.2.

It was the first. **The traversal query was correct the whole time.**

## Root cause

`relate()` used the escaped-identifier form:

```sql
RELATE entity:⟨$from⟩->relates_to->entity:⟨$to⟩ SET rel = $rel;
```

`⟨ ⟩` is SurrealDB's **escaped-IDENTIFIER** syntax, not parameter interpolation. A live
probe of the in-memory DB (`SELECT * FROM relates_to;`) showed exactly what was written:

```
"in":  RecordId { table: "entity", key: String("$from") }
"out": RecordId { table: "entity", key: String("$to") }
```

Every edge pointed at two junk records literally keyed `$from` / `$to`. `entity:a` had
no edges, so traversal correctly returned nothing.

Confirmed in surrealdb-core-3.2.1 source:
- `syn/lexer/char.rs:16` — `'⟨' => return self.lex_surrounded_ident(false)`, so the
  content is literal identifier text.
- `syn/parser/record_id.rs` `parse_record_id_key` default arm (~line 335) returns
  `RecordIdKeyLit::String(ident)` verbatim. **There is no `$param` arm in that function
  at all** — a param can never reach a record-id key position.

## The fix

Endpoints must be a **parenthesized expression**:

```sql
RELATE (type::record('entity', $from))->relates_to->(type::record('entity', $to)) SET rel = $rel;
```

Per `syn/parser/stmt/relate.rs` `parse_relate_expr`, RELATE endpoints accept:
- `t!("$param")` → a bare bound param (works; costs an extra `LET` statement)
- `t!("(")` → a parenthesized expression (**chosen** — one statement, matches the
  `type::record` idiom used everywhere else in `store.rs`)
- otherwise → falls through to `parse_record_id`, which dies on `::`. That fallthrough
  is why the earlier bare `type::record(...)` produced "Unexpected token `::`" and led
  to the chevron workaround in the first place.

## Why this hid for so long

`relate()` calls `.query(...).await?` and never inspects `Response::take_errors()`.
SurrealDB reports statement failures **per-statement**, not as a query-level `Err` — so
`relate()` structurally cannot report a failed edge write. `GraphStore::init()` already
guards this correctly. Flagged as follow-up work.

The chevron form was worse than a parse error: a parse error fails loudly, this wrote
plausible-looking garbage and returned success.

## Follow-up (2026-07-17): the error guard was added — and proven unable to catch this bug

A later session added the flagged follow-up: `error::check_statements(&mut IndexedResults,
ctx)`, applied to every previously-silent `.query()` site (`relate`, `upsert_provider`,
`delete_provider`, `upsert_model_pref`, `set_setting`, `init`).

**But it does not catch this bug, and cannot.** Verified empirically, not assumed: a
side-by-side live probe against surrealdb-core 3.2.1 ran both RELATE forms and called
`take_errors()` on each —

```
CHEVRON take_errors: {}   <- EMPTY. The chevron form is not a statement failure.
PAREN   take_errors: {}
```

The chevron form is not a "failure that goes unreported" — it is a **complete, correct
success** from SurrealDB's point of view. It parsed, executed, and did exactly what its
syntax says: wrote an escaped-identifier record key. `check_statements()` has nothing to
catch. Confirmed by falsification: reverting `relate()` to the chevron form and re-running
the test suite left `relate_rejected_by_db_surfaces_error` (the guard's own test) **green**,
while only a test asserting on the actual stored edge keys (`relate_binds_endpoint_ids_not_
literal_param_names`) went red.

**The corrected framing:** this was never a missing-error-check bug. It was a **silent
wrong-success** bug — SurrealDB did something legal and complete that was not what the
caller meant. No error-reporting layer, however thorough, can surface that class of bug.
Only an assertion on what was actually written can. See [[surrealdb-three-failure-levels]]
for the general pattern (query Err / per-statement error / silent wrong success).

The guard is still worth having — `memory_search()` had a real level-2 bug of its own
(only the last of its multi-statement query was checked, so a failed vector or BM25 lane
silently degraded hybrid search to one lane while returning plausible rows) — just not
this one.

## Lesson

Don't iterate on SurrealQL syntax guesses. Two moves beat guessing:
1. **Probe the live DB** — `SELECT * FROM relates_to;` and read the `in`/`out` keys. A
   key of `"$from"` instead of `"a"` names the bug in one shot.
2. **Read surrealdb-core's parser source.** The parser's own error text names the
   sanctioned route (`type::record("{}",{})`).

A second lesson from the follow-up: **don't assume an error-reporting gap explains a
silent-wrong-success bug** without checking whether the error path could ever have fired.
Falsify the fix — revert it and confirm the test goes red for the right reason — before
trusting a green suite.

Related: `type::thing` does not exist in 3.2 — it is `type::record(table, key)`.
