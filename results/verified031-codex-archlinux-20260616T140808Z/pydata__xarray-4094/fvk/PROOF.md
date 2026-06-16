# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims

The claims are recorded in `fvk/to-unstacked-dataset-spec.k` over the abstract
semantics in `fvk/mini-xarray-unstack.k`.

- C1 proves PO1: non-MultiIndex inputs reach the existing `ValueError` outcome.
- C2 proves PO2, PO3, PO4, and PO7 for the reported single-level roundtrip
  family.
- C3 proves PO5 and PO6 for the mixed-dimensional one-real-level family.
- C4 is represented by `mergeCompatible(OUT)` in C2/C3 and discharges PO7.

## Proof sketch

1. The method reads `idx = self.indexes[dim]` and checks
   `isinstance(idx, pd.MultiIndex)`. If the check fails, it raises before any
   dataset construction. This discharges PO1.
2. If the check succeeds, the method computes `variable_dim` from the selected
   MultiIndex level and iterates over that level's labels. For each `k`,
   `self.sel({variable_dim: k})` is the only producer of the candidate output
   array. This establishes one reconstruction path per selected label for PO2.
3. V2 builds `dims_to_squeeze` rather than calling `squeeze(drop=True)` on all
   singleton dimensions. The consumed stacked dimension `dim` is included only
   when it remains a singleton dimension after selection and either has no
   remaining MultiIndex levels or all remaining levels are null placeholders.
   Remaining level dimensions are included only when their coordinate has size
   one and all values are null. Thus legitimate sample dimensions and real
   remaining levels are framed through unchanged, including length-one cases.
   This discharges PO4 and PO6.
4. The null-sentinel branch captures the placeholder dimension that
   `to_stacked_array` creates for a variable missing a stacked level. Squeezing
   it with `drop=True` removes the placeholder rather than preserving a
   meaningless null dimension. This discharges PO5.
5. If a remaining level coordinate is not the single-null sentinel, V2 does not
   add it to `dims_to_squeeze`. It therefore remains available as a real output
   dimension/coordinate. This discharges PO6.
6. After targeted squeezing, V2 drops coordinate variables named `dim` and
   `variable_dim` with `errors="ignore"`. Those are the consumed stacked
   coordinate names; removing them prevents `Dataset(data_dict)` from merging
   different scalar values for the stacked coordinate. This discharges PO3 and
   PO7.
7. The method signature and outer return construction are unchanged. The guard
   and mixed-dimensional preservation arguments discharge PO8.

## Machine-check commands

Recorded only; not executed in this task.

```sh
kompile fvk/mini-xarray-unstack.k --backend haskell
kast --backend haskell fvk/to-unstacked-dataset-spec.k
kprove fvk/to-unstacked-dataset-spec.k
```

Expected result after a successful future machine check: `kprove` returns
`#Top`. Until then, this remains a constructed proof.

## Test guidance

No test files were modified. Existing tests should be kept until the K claims
are machine-checked and the normal Python test suite is available. Useful tests
to add outside this benchmark restriction are listed in
`fvk/ITERATION_GUIDANCE.md`.
