# Constructed Proof

Status: constructed, not machine-checked.

## What Is Proved

For the fast-delete scheduling abstraction in `mini-fast-delete.k`, the V1
collector helper satisfies these partial-correctness properties:

- Compatible same-model fast-delete entries combine into one OR predicate when
  parameter limits permit it.
- Incompatible entries remain separate.
- Entries that would exceed a backend parameter limit remain separate.
- The reported two-FK and self-M2M cases reduce final fast-delete entries from
  two to one, which maps to one `_raw_delete()` round trip in `Collector.delete()`.

## Proof Sketch

`addFast(FDs, Q, L)` recursively scans the existing fast-delete list from left
to right.

Case 1, empty list: `addFast(.FDs, Q, L)` rewrites to `Q ; .FDs`. This is the
append behavior when no compatible entry exists.

Case 2, compatible head: If `canCombine(F, Q, L)` is true, the semantic rule
rewrites `addFast(F ; REST, Q, L)` to `combineFD(F, Q) ; REST`. For same model
entries with known counts inside the limit, `combineFD` rewrites the predicate
to `P1 |or| P2` and the count to `known(A + B)`. This discharges PO-1 and the
first two K claims.

Case 3, incompatible or unsafe head: If `canCombine(F, Q, L)` is false, the
semantic rule rewrites to `F ; addFast(REST, Q, L)`. With `.FDs` as the rest,
this yields two entries, discharging PO-2 and PO-3.

Round-trip count: `rawDeleteCount(.FDs) => 0` and
`rawDeleteCount(_ ; REST) => 1 + rawDeleteCount(REST)`. Composing this with
Case 2 for the reported two-FK input gives `rawDeleteCount(combined-entry) => 1`,
discharging PO-5.

Semantic preservation: SQL `OR` denotes set union over the row predicate. The
combined predicate `P |or| Q` therefore deletes the same final row set as two
sequential DELETE statements for `P` and `Q`; duplicate matches are counted once,
which matches sequential deletion after the first statement removes them.

## Source Mapping

The K function `addFast` models `Collector.add_fast_delete()`.

- `canCombine` models the queryset-like check, same-model check, and
  `max_query_params` guard.
- `combineFD` models `fast_delete | qs`.
- `rawDeleteCount` models `Collector.delete()` executing one `_raw_delete()` per
  final `fast_deletes` entry.

`Collector.collect()` integration is discharged by source inspection: both
previous direct append sites now call `add_fast_delete()`.

## Residual Risk

The proof is partial correctness over an abstraction, not a full Python/Django
semantics proof. It is property-complete for the issue's observable behavior
because it preserves model/table identity, OR predicate shape, parameter safety,
and fast-delete entry count.

The K artifacts were not executed. Machine-checking requires:

```sh
kompile fvk/mini-fast-delete.k --backend haskell
kast --backend haskell fvk/fast-delete-spec.k
kprove fvk/fast-delete-spec.k
```

Expected outcome after syntax/tooling iteration, if any is needed in a K-enabled
environment: `kprove` returns `#Top`.

## Test Guidance

No tests were modified. Existing or hidden tests for the two public examples are
not redundant until the K proof is machine-checked. After machine-checking, unit
tests that only assert two compatible same-model fast deletes become one
OR-combined entry would be subsumed by PO-1 and PO-5, while integration tests
that exercise actual database SQL rendering and backend-specific parameter
limits should be kept.
