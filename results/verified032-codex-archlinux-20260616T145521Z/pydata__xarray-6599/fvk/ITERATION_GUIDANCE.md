# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit production code beyond the V1 patch. The audit found no additional
public-intent obligation that requires changing `polyval` behavior.

## Why V1 Stands

F1 and PO1 identify the concrete bug: timedelta values were sent through
`datetime_to_numeric` with a datetime epoch offset. V1 fixes that by adding a
separate `x.dtype.kind == "m"` branch and a zero timedelta offset.

F4 and PO6 confirm the exact offset choice. Using the minimum timedelta would
make `polyval` evaluate relative to the first/minimum coordinate, while `polyfit`
uses raw timedelta durations. The zero offset is the intent-compatible choice.

F2 and PO7 reject a broader change to restore legacy index-coordinate lookup for
the original MCVE call. Public hints state that the new algorithm evaluates
`coord` values directly.

F3 and PO8 reject a broader API change to accept plain NumPy arrays. The public
signature is `DataArray`/`Dataset`, and the issue discussion says the NumPy array
attempt is not the bug.

F5 and PO2-PO5 confirm that V1 preserves existing datetime, numeric, Dataset, and
missing-value behavior.

## Follow-Up Tests For A Normal Dev Environment

Do not run these in this benchmark session. They are listed only as next-iteration
guidance.

```sh
pytest xarray/tests/test_computation.py -k polyval
pytest xarray/tests/test_duck_array_ops.py -k datetime_to_numeric
```

Recommended new test cases, if test edits were allowed:

- `xr.polyval` with `coord` equal to a `DataArray` of `timedelta64[ns]` values.
- A timedelta coordinate that starts at a nonzero duration, proving the zero
  offset choice.
- Existing datetime `polyval` behavior to guard the epoch conversion frame.
- Numeric coordinate pass-through.

## Future FVK Work

Run the recorded K commands in a real K environment:

```sh
kompile fvk/mini-xarray-polyval.k --backend haskell
kast --backend haskell fvk/polyval-spec.k
kprove fvk/polyval-spec.k
```

If K reports a parsing or proof issue, repair the mini semantics or claims first;
do not infer a production-code bug unless the failed obligation still traces to
`fvk/FINDINGS.md`.
