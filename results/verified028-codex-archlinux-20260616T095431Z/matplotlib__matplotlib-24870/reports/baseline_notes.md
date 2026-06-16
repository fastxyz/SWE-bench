# Baseline Notes

## Root cause

`QuadContourSet._contour_args` converted the input `Z` data to `float64`
before automatic contour levels were selected.  A boolean array therefore
became numeric `0.0`/`1.0` data before `_process_contour_level_args` ran, so
the default path used the normal `MaxNLocator` behavior and produced multiple
levels for a two-valued boolean field.

For `contourf`, the same default level path could also produce too few useful
boundaries for boolean data; a single boundary is not enough for filled
contours, which need intervals.

## Changed files

`repo/lib/matplotlib/contour.py`

- Added a `_contour_z_is_bool` flag on contour sets.
- Set that flag from the original `Z` dtype in both `contour(Z, ...)` and
  `contour(X, Y, Z, ...)` call forms before converting `Z` to `float64`.
- Updated the no-levels-provided default so boolean `contour` uses `[0.5]` and
  boolean `contourf` uses `[0, 0.5, 1]`.
- Left explicit level choices alone, including positional level arguments,
  keyword `levels=...`, explicit `locator=...`, and log-scale contouring.

`reports/baseline_notes.md`

- Documents the diagnosis, implementation, and assumptions for the benchmark
  task.

## Assumptions and alternatives considered

The boolean special case is only for arrays whose original `Z` dtype is
`bool`.  Numeric arrays containing only `0` and `1` still use the existing
numeric automatic level selection, because the issue asks to auto-detect
boolean inputs rather than binary-valued numeric data.

The special case applies only when the caller did not provide levels.  I
treated an explicit integer level count, an explicit `levels` keyword, or a
custom locator as caller-directed behavior that should remain unchanged.

I kept the change in the regular quadrilateral contour implementation because
the issue describes `contour()` and `contourf()` on 2D arrays.  Extending the
same behavior to triangular contours would be possible, but it would broaden
the behavior beyond the reported case.

I did not run tests or execute Matplotlib code, following the task constraint
that this workspace has no execution environment for tests or code execution.
