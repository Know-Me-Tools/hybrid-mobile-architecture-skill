# Design decisions — c303

## D-1 · Fix the templates and gate both (task 1.1)

**Decided by:** user, 2026-08-22 · **Option chosen:** A — fix + render-and-build gate

### The measurement that decided it

The plan framed this as a cost tradeoff: a slow gate versus deleting a feature.
Measuring first found something neither option anticipated — **`tray.rs.template`
does not compile.**

```
error[E0596]: cannot borrow `*app` as mutable, as it is behind a `&` reference
   --> tray.rs.template:105
    |
105 |     let _ = app.set_activation_policy(tauri::ActivationPolicy::Accessory);
    |             ^^^ `app` is a `&` reference, so it cannot be borrowed as mutable
help: consider changing this to be a mutable reference
    |
103 | pub fn apply_accessory_policy(app: &mut App) {
```

`scaffold-tauri-tray.sh:91` renders this into every scaffolded project's
`src-tauri/tray.rs`. Every consumer of that scaffold has received code that
cannot build.

The prior phase's reflection listed "`tray.rs` is never compiled" as debt and
noted it "references `tauri` APIs verified against current docs". Verification
against documentation is not verification against a compiler. The debt was not
hypothetical rot-in-future; it was a shipped defect.

That reframes the decision. Deleting the template would have removed a broken
artifact — acceptable — but the gate is what would have *caught* it, and what
prevents the next one.

### Measured cost (this machine, warm cargo cache)

| Template | Dependencies | Build |
|---|---|---|
| `health-aggregator` | `tokio` only | **14s**, compiles clean, 6/6 tests |
| `tray.rs` | full Tauri 2 graph | **~2min** |

### What ships

- The E0596 bug is fixed.
- `scripts/verify-tray-templates.sh` renders both templates into a scratch
  project and builds them.
- It is wired into `audit.sh` as its **own named mode**, deliberately **not**
  part of `all`. A two-minute step inside the everyday aggregate audit is a step
  people learn to skip; a named mode is run on purpose, and `all` stays fast.

### Why not the cheaper half-measure

Gating only the 14s health-aggregator was offered and declined. The
health-aggregator was already the one artifact proven by execution in the prior
phase — it was never the risk. The 2-minute template is the one that shipped a
compile error, so gating only the cheap half would leave exactly the surface
that failed unguarded.

## D-2 · `toggle_pause` stays a stub, and says so (task 1.4A)

`tray.rs.template:82-84` is an empty body with a comment where the aggregator
wiring belongs. It stays empty: the tray owns no state, and the wiring depends
on the consuming app's aggregator handle, which the scaffold cannot know.

What changes is that the stub is now *documented as intentional* rather than
reading as unfinished work — and, unlike before, it is compiled, so it cannot
silently drift out of signature agreement with its call site.

## D-3 · Scope boundary: 43 more ungated Rust template files

Task 2.4 asks whether any artifact remains that claims to compile but never is.
Within c303's scope — the tauri-tray templates — the answer is now no: both are
rendered through the real scaffold and built under `clippy -D warnings`.

Outside it, the answer is **yes, at 15× the scale**:

```
$ find assets/templates/rust -name '*.rs' | wc -l
43            # across 4 crates: gen_ui_types, gen_ui_inference, and two more
$ grep -n 'cargo\|clippy' scripts/verify-scaffold.sh
              # (no matches — nothing builds them)
```

`tray.rs.template` was 108 lines and shipped two defects (E0596, then
`clippy::let_unit_value`). The same reasoning applies to 43 files that no build
touches, and the defect rate there is unknown precisely because nothing measures
it.

This is **not fixed here**. Gating four crates is its own change with its own
cost profile, and c303 was scoped to the tray templates. Recorded so the finding
survives into reflect as named debt rather than being absorbed by a checked box
on task 2.4.
