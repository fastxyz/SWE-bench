# Baseline Notes

## Root cause

`Coarsen.construct` reshapes every variable in the temporary dataset, including
coordinate variables. After the reshape it rebuilds coordinate status with:

```python
should_be_coords = set(window_dim) & set(self.obj.coords)
```

That only keeps coordinates whose names are also coarsened dimension names. A
non-dimension coordinate such as `day`, with dims `("time",)`, is reshaped into
`("year", "month")` correctly but is left as a data variable because its name is
not in `window_dim`.

## Files changed

- `repo/xarray/core/rolling.py`: changed `Coarsen.construct` to mark all
  original coordinate names as coordinates after rebuilding the reshaped
  dataset. The reshape loop already preserves the coordinate variables as
  variables in `reshaped`, so the missing step was preserving their membership
  in the coordinate set.

## Assumptions and alternatives considered

- Assumed the expected invariant is that variables that were coordinates before
  `coarsen.construct` remain coordinates afterward, even if their dimensions are
  split by the coarsening operation. This matches the issue text and existing
  behavior for dimension coordinates such as `time`.
- Considered special-casing only non-dimension coordinates that include a
  coarsened dimension. Rejected that because coordinates on untouched dimensions
  should also retain coordinate status, and using all original coordinate names
  is simpler and consistent with xarray coordinate bookkeeping.
- Considered constructing the result with private dataset constructors and
  explicit `coord_names`. Rejected that as a larger internal change; the current
  code already uses `set_coords`, and only the set of names passed to it was
  incorrect.
- No tests or project code were run, per the benchmark instruction forbidding
  code execution in this session.
