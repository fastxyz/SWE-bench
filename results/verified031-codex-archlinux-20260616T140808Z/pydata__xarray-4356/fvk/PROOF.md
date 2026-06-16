# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python,
or test commands were run.

## Claim

V1 is correct for the intended `min_count` decision in `_maybe_null_out`:

```text
count = product(mask.shape[a] for a in reduced_axes)
missing = mask.sum(reduced_axes)
valid = count - missing
result is null iff valid < min_count
```

For one integer axis this reduces to the existing single-axis rule. For scalar
or all-dimension reductions, V1 leaves the existing `mask.size - mask.sum()`
branch unchanged.

## Constructed Proof Sketch

1. Public dispatch: by PO-001, the issue input with `dim=["dim_0", "dim_1"]`
   reaches `nanops.nansum` with a tuple axis and then `_maybe_null_out` because
   `min_count` is not `None`.
2. Legacy rejection removed: the pre-V1 tuple/list-axis `ValueError` is absent,
   so the in-domain multi-axis input is no longer rejected at the helper entry.
3. Multi-axis count: by PO-002, `np.take(mask.shape, axis).prod()` computes the
   product of all reduced axis sizes. This is exactly the total number of
   candidate elements contributing to each output position.
4. Null decision: by PO-003, V1's predicate
   `(count - mask.sum(axis) - min_count) < 0` is algebraically equivalent to
   `valid_count < min_count`, which matches the public doc obligation.
5. Preservation: by PO-004, when `axis` is a single integer, the new count equals
   `mask.shape[axis]`. By PO-005, scalar/all-dimension reductions do not enter
   the changed branch and retain their previous intended rule.
6. Compatibility: by PO-006, public signatures and dispatch shapes do not
   change.

Therefore, under the formal model in `fvk/mini-nanops.k`, V1 satisfies the
intent-derived obligations for multi-axis `sum(..., min_count=...)` and does not
justify any further source edit.

## K Claims

The supporting K claims are in `fvk/nanops-min-count-spec.k`:

- MULTI-AXIS-NULL: `maybeNull(D0 * D1, NULLS, MIN) => null` when
  `D0 * D1 - NULLS < MIN`.
- MULTI-AXIS-KEEP: `maybeNull(D0 * D1, NULLS, MIN) => keep` when
  `D0 * D1 - NULLS >= MIN`.
- SINGLE-AXIS-NULL: `maybeNull(D0, NULLS, MIN) => null` when
  `D0 - NULLS < MIN`.
- SINGLE-AXIS-KEEP: `maybeNull(D0, NULLS, MIN) => keep` when
  `D0 - NULLS >= MIN`.

There are no loop circularities because the audited source path contains no
loops.

## Machine-Check Commands Not Run

The commands that would be run in an environment with K installed are:

```sh
kompile fvk/mini-nanops.k --backend haskell
kast --backend haskell fvk/nanops-min-count-spec.k
kprove fvk/nanops-min-count-spec.k
```

Expected result after a successful machine check would be `#Top` for all claims.
That result was not obtained in this session.

## Test Guidance

No tests were modified. Test removal is not recommended because the proof is
constructed, not machine-checked, and the mini semantics abstracts away full
NumPy/Dask behavior. Useful tests to keep or add are:

- multi-axis `DataArray.sum(..., min_count=1)` where enough valid values exist;
- multi-axis `DataArray.sum(..., min_count=N)` where too few valid values exist;
- one-axis `min_count` regression;
- scalar/all-dimension `min_count` regression;
- Dask-backed variants if the project supports them.

