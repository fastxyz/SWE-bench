# Baseline Notes

## Root cause

`OPTICS` accepts `min_samples` as either an absolute count or a fraction of
the input sample count. In `compute_optics_graph`, fractional values were
validated and scaled by `n_samples`, but the scaled value remained a float.
That float was then passed to `NearestNeighbors(n_neighbors=...)`, which
requires an integer neighbor count and raises a `TypeError`.

The same fractional-size conversion pattern also existed in
`cluster_optics_xi` for `min_samples` and `min_cluster_size`. Those values are
used as count thresholds during Xi cluster extraction, so they should be
converted to integer sample counts after validation as well.

## Files changed

- `repo/sklearn/cluster/optics_.py`
  - Updated the `compute_optics_graph` `min_samples` docstring to document the
    accepted fractional form.
  - Converted fractional `min_samples` to an integer count before constructing
    `NearestNeighbors`.
  - Converted fractional `min_samples` and `min_cluster_size` to integer counts
    in `cluster_optics_xi` before passing them into the Xi extraction helper.

## Assumptions and alternatives considered

- I treated fractional values as sample-count fractions that should be
  truncated with `int(...)` and bounded below by 2, matching the public hint to
  use direct integer conversion and the existing validation language.
- I considered using nearest-integer rounding or `ceil`, but rejected those
  because the existing code only needed to remove the float type before count
  usage, and the public discussion explicitly suggested direct integer
  conversion rather than compatibility-oriented `round(...)` wrapping.
- I did not modify tests, changelog files, or broader documentation because the
  benchmark instructions forbid test edits and ask for a minimal source-code
  fix plus this report.
