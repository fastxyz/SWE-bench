# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The audit found that the source metadata path already records and passes the
original level coordinate dtype (`F2`, `PO2`). The defect was localized to the
level branch of `PandasMultiIndexingAdapter.__array__`, and V1 applies the
stored or explicitly requested dtype at that exact materialization point (`F1`,
`F3`, `PO3`, `PO4`, `PO5`).

## Recommended Future Tests

Do not edit tests in this benchmark. For a normal development branch, add or
keep tests for:

- default `.values.dtype` preservation after `stack` for an `int32` coordinate;
- consistency of stacked level coordinate `.dtype` and `.values.dtype`;
- explicit `np.asarray(adapter, dtype=...)` override behavior for a MultiIndex
  level; and
- unchanged behavior for the aggregate `level is None` MultiIndex coordinate.

## Machine Check

The constructed proof should be machine-checked later with:

```sh
cd fvk
kompile mini-python-indexing.k --backend haskell
kast --backend haskell pandas-multi-indexing-adapter-spec.k
kprove pandas-multi-indexing-adapter-spec.k
```

Until `kprove` returns `#Top`, keep tests. This run does not justify deleting
tests.

## No Further Code Changes

No additional source edit is recommended. Changing `PandasMultiIndex.stack` or
`PandasMultiIndex.create_variables` would duplicate metadata work that already
exists, and changing public APIs would add compatibility risk without improving
the proof obligations.

