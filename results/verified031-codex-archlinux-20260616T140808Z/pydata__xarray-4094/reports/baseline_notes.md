# Baseline Notes

## Root cause

`DataArray.to_unstacked_dataset()` reconstructs a dataset by selecting one
value from the requested MultiIndex level and then building `Dataset(data_dict)`
from the selected arrays. For arrays produced by `Dataset.to_stacked_array()`
where every original variable only has the sample dimensions, selecting a
single variable consumes the only MultiIndex level. The selected array can keep
scalar coordinates for the stacked dimension and the consumed level. Those
coordinates have different values for each output variable, so
`Dataset(data_dict)` tries to merge conflicting scalar coordinate values and
raises `MergeError`.

## Files changed

- `repo/xarray/core/dataarray.py`: after selecting and squeezing each variable
  in `to_unstacked_dataset()`, the code now drops the stacked coordinate name
  and the consumed MultiIndex level coordinate when present. These coordinates
  are reconstruction metadata after the selection and should not be merged into
  the output dataset variables.

## Assumptions and alternatives considered

- I assumed the roundtrip should remove the synthetic stacked coordinate
  metadata, matching the existing successful mixed-dimensional roundtrip tests
  where the output dataset should look like the original dataset.
- I considered changing `Dataset.to_stacked_array()` so the single-level
  MultiIndex is encoded differently, but that would alter the public stacked
  representation and affect more callers than necessary.
- I considered passing `compat="override"` during dataset construction, but
  that would mask real coordinate conflicts. Dropping only the consumed stacked
  metadata is narrower and preserves normal merge validation.
- I did not run tests or execute code, per the benchmark instructions.
