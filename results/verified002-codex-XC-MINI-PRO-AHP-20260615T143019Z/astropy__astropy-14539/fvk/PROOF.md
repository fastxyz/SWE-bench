# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims

The formal claims are in `fvk/fitsdiff-vla-spec.k` over the fragment semantics
in `fvk/mini-fitsdiff.k`.

The claims state:

1. `P` and `Q` are VLA formats; `OTHER` is not.
2. A same-shape floating row differs exactly when the FITSDiff floating helper
   says it differs.
3. A same-shape non-floating numeric row differs exactly when numeric closeness
   fails.
4. A same-shape non-numeric row differs exactly when exact equality fails.
5. Any shape mismatch differs.
6. A `Q` column whose rows all satisfy the row equality predicate contributes
   zero row differences.
7. A `Q` or `P` column with a failing row predicate contributes that row as a
   difference.

## Proof Sketch

For PO-001 and PO-002, `_ColumnFormat.__new__` normalizes the top-level FITS
format code into `col.format.format`. The source branch
`col.format.format in ("P", "Q")` is equivalent to the formal `isVLA(P) = true`
and `isVLA(Q) = true` claims. Therefore both descriptor variants reach the same
row-wise comparison.

For PO-003, `_vla_values_differ` first converts each row to an array and checks
shape equality. If shapes differ, it returns `True` before any value predicate.
Thus row shape cannot be hidden by numeric broadcasting or element comparison.

For PO-004, the floating-row branch calls `where_not_allclose` and returns
`True` only when that helper reports at least one differing index. Existing
public code and tests establish that this is FITSDiff's floating-data policy,
including matching invalid floating values.

For PO-005, if the rows are numeric but not floating, the helper returns the
negation of `np.allclose` with the caller's `rtol` and `atol`. This preserves
the previous tolerance-aware numeric VLA behavior after the new shape guard.

For PO-006, if the rows are non-numeric, the helper returns whether exact
element inequality has any true element. With equal shapes, identical rows
therefore return `False`; any unequal element returns `True`.

For PO-007, the helper call is syntactically inside only the `P`/`Q` branch.
The fixed-floating column branch and the generic non-VLA branch are unchanged.

For PO-009 and PO-010, `TableDataDiff._diff` builds `diffs[0]` as exactly the
list of row indices for which `_vla_values_differ` is true. The existing
aggregation increments `diff_total` by `len(set(diffs[0]))` and records up to
`numdiffs` entries by iterating through `diffs[0]`. Therefore an empty row list
contributes no data difference, and each differing row is available to the
existing reporting path.

Composing these obligations: for the public `QD` same-file case, `Q` dispatches
to the VLA branch; each row has the same shape and equal floating contents; the
row predicate is false for every row; `diffs[0]` is empty; no data difference is
added by that column.

## Machine-Check Commands

These commands are recorded for a later environment with K installed. They were
not executed here.

```sh
kompile fvk/mini-fitsdiff.k --backend haskell
kast --backend haskell fvk/fitsdiff-vla-spec.k
kprove fvk/fitsdiff-vla-spec.k
```

Expected machine-check result after successful discharge: `#Top`.

## Residual Risk

This proof is partial correctness for the modeled branch predicate. It does not
prove termination of the enclosing table diff loop, full NumPy semantics, FITS
I/O correctness, or report formatting. Those behaviors are outside the local
patch and should remain covered by tests.
