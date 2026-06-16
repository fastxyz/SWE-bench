# Constructed Proof

Status: constructed, not machine-checked.

No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Machine-Check Commands For Later

```sh
cd fvk
kompile mini-django-groupby.k --backend haskell
kast --backend haskell django-groupby-spec.k
kprove django-groupby-spec.k
```

Expected result after a successful machine check: `#Top`.

## Modeled Function

The K model reduces the relevant compiler behavior to `orderGroupCols()`, a
finite list transformer over abstract order entries:

- `order(true, cols)` represents an `is_ref` entry and contributes nothing.
- `order(false, cols)` represents a non-reference entry and filters each group
  column by `keep(col)`.
- `keep(col)` is true if the column has direct column references, raw SQL in its
  flattened sources, or non-empty external columns in a flattened source.

This abstraction preserves the defect axis: whether an expression is added to
the `GROUP BY` candidate list.

## Proof Sketch

`DROP-RANDOM`: `randomCol` has no direct column references, no raw SQL source,
and no external-column source. The `keep()` predicate rewrites to `false`, so
`appendKept()` drops it and `orderGroupCols()` returns `.GroupCols`.

`KEEP-COLUMN`: `relatedCol` has `contains_column_references = true`. The first
branch of `keep()` rewrites to `true`, so `appendKept()` prepends the column to
the recursively filtered tail.

`KEEP-RAWSQL`: `rawCol` has a flattened `RawSQL` source. `hasSourceMarker()`
rewrites to `true`, so `keep()` is true and the column is retained.

`KEEP-EXTERNAL-COLS`: `externalSubqueryCol` has no direct column-reference
metadata but has a flattened source with non-empty external columns. The V2
source check matches this case, `hasSourceMarker()` rewrites to `true`, and the
column is retained. V1 lacked this branch, which is why F1 was reported.

`DROP-REF`: `order(true, cols)` rewrites directly to the filtered result of the
tail without inspecting `cols`, matching the existing compiler reference-skip
rule.

`FILTER-STEP`: By structural induction on the finite `OrderEntries` list:

- Base: `.OrderEntries` rewrites to `.GroupCols`.
- Step: the head order entry is either a reference entry, which contributes
  nothing, or a non-reference entry, whose `GroupCols` list is filtered by
  `appendKept()`. `appendKept()` itself is proved by structural induction on the
  finite group-column list, retaining exactly the `keep()` columns and then
  appending the recursively processed tail.

## Residual Risk

This is a partial-correctness proof over a mini semantics, not a machine-checked
proof over full Python or full Django. It does not prove database backend SQL
validity, query execution, performance, or termination of arbitrary custom
expression methods. It does prove the intended finite-list filtering rule, if
the mini semantics and claims are adequate.

Test removal is not recommended. The proof is constructed only, and the task
forbids editing tests.
