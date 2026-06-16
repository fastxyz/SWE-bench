# Baseline Notes

## Root cause

`Axes.hist` builds a `hist_kwargs` dictionary before calling `np.histogram`.
For the single-dataset path, or for empty input, it stores the requested
histogram range as `hist_kwargs['range'] = bin_range`. Later, when
`density=True` and the histogram is not stacked, the code replaced the entire
dictionary with `dict(density=density)`. That discarded the previously stored
range, so `np.histogram` chose automatic bin edges from the data extent instead
of the user-provided `range=(0, 1)`.

This specifically affects string/automatic bin strategies such as
`bins='auto'`, where NumPy uses the supplied range to determine the returned
edges. With `density=False`, the existing `range` entry remained in
`hist_kwargs`, so the bug was not triggered.

## Changed files

- `repo/lib/matplotlib/axes/_axes.py`: changed the density branch in
  `Axes.hist` to add `density` to the existing `hist_kwargs` dictionary instead
  of replacing it. This preserves any existing `range` value while still
  passing `density=True` to `np.histogram` for non-stacked density histograms.

## Assumptions and rejected alternatives

- I assumed the intended behavior is to mirror `np.histogram`: when a user
  provides `range`, automatic bin edges should span that range regardless of
  density normalization.
- I considered changing the earlier range/bin-edge selection logic, but the
  issue is caused after that logic has already recorded the correct range in
  `hist_kwargs`.
- I did not change stacked-density handling. Stacked density histograms are
  intentionally normalized manually later in `Axes.hist`, so passing
  `density=True` to `np.histogram` there would alter existing semantics.
- I did not modify tests, per the task instructions. I also did not run tests
  or execute project code.
