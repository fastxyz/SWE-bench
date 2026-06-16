# Baseline Notes

## Root cause

`merge_attrs` handled `combine_attrs="override"` by returning
`variable_attrs[0]` directly. For `xr.merge`, `merge_core` passes that attrs
object into `Dataset._construct_direct`, which stores the mapping without
copying. As a result, the merged dataset and the first source dataset shared the
same attrs dictionary, so mutating `merged.attrs` could mutate the source attrs.

## Files changed

- `repo/xarray/core/merge.py`: changed the `combine_attrs="override"` branch in
  `merge_attrs` to return `dict(variable_attrs[0])`, matching the fresh shallow
  copy behavior already used by the `no_conflicts` and `identical` branches.
- `reports/baseline_notes.md`: added this required explanation of the fix.

## Assumptions and alternatives considered

- I assumed the expected behavior is a fresh attrs mapping, not a deep copy of
  every attr value. The existing `no_conflicts` and `identical` branches already
  use shallow `dict(...)` copies, and the reported failure is direct dictionary
  aliasing.
- I considered fixing `merge()` or `merge_core()` by copying attrs after
  combination, but that would duplicate responsibility and would not help other
  callers of `merge_attrs`, such as concat/combine paths. Fixing the helper is
  narrower and covers the shared behavior.
- I did not modify tests or run code, in accordance with the benchmark
  constraints.
