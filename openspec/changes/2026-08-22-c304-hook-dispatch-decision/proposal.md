## Why

`prom-hook-dispatch` has been advisory text across two phases; a third is a decision by
default. Separately, the W6.x sequences in the two specs are OFFSET BY ONE across
W6.6-W6.9 — docs/03:191 calls prom-hook-dispatch W6.7 while docs/05:596 calls it W6.8 —
so the labels cannot be reconciled one at a time.

## What Changes

- Decide: build `prom-hook-dispatch`, or drop it from spec 03's Definition of Done.
- Renumber one document's FULL W6.x sequence so both lists map the same label to the
  same remedy end to end.
- Add a mechanical check asserting the label→remedy mapping is identical in both files.
- If dropped: `verify-hooks-reliability.sh` stops reporting it as pending.
- If built: scope the Rust crate as its own change and defer, so this stays a decision.

## Impact

- Depends on c300.
- Edits two specs' DoD; whichever way the decision goes, both must agree.
