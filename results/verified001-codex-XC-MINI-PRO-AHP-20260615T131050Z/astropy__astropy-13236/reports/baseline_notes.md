# Baseline Notes

## Root cause

`Table._convert_data_to_col` special-cased any plain structured `numpy.ndarray` that
was not already a `Column` or table mixin by viewing it as `NdarrayMixin`. That
forced structured arrays added during table construction, assignment, replacement,
or `add_column` to bypass the normal `ColumnClass` path. Since structured
`Column` now supports the relevant behavior, this automatic mixin conversion is
no longer needed and produces the undesirable column type described in the issue.

## Changed files

- `repo/astropy/table/table.py`: removed the structured-ndarray-to-`NdarrayMixin`
  conversion branch in `_convert_data_to_col`. Plain structured ndarrays now fall
  through to the existing `ColumnClass` construction path, preserving their
  structured dtype as regular columns. Also removed the now-unused `NdarrayMixin`
  import from this module.

## Assumptions and alternatives

- I assumed the requested behavior is the immediate change described in the public
  discussion: structured ndarrays should become `Column` objects now, without a
  transitional `FutureWarning`.
- I kept explicit `NdarrayMixin` inputs unchanged. They are still recognized by
  `_is_mixin_for_table` before the normal column path, so users who deliberately
  pass an `NdarrayMixin` continue to get mixin behavior.
- I considered adding compatibility logic for unnamed structured dtypes, but the
  existing `ColumnClass` constructor already delegates to `np.array` and preserves
  structured dtype information, so no additional conversion helper was needed.
- I did not modify tests and did not run tests or project code, per the benchmark
  instructions.
