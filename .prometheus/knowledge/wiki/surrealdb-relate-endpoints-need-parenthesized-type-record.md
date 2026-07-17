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

## Lesson

Don't iterate on SurrealQL syntax guesses. Two moves beat guessing:
1. **Probe the live DB** — `SELECT * FROM relates_to;` and read the `in`/`out` keys. A
   key of `"$from"` instead of `"a"` names the bug in one shot.
2. **Read surrealdb-core's parser source.** The parser's own error text names the
   sanctioned route (`type::record("{}",{})`).

Related: `type::thing` does not exist in 3.2 — it is `type::record(table, key)`.
