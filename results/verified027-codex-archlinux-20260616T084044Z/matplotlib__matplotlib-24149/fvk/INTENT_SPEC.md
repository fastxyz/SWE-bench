# Intent Spec

Scope: targeted FVK audit for `matplotlib__matplotlib-24149`, covering the
publicly reported `Axes.bar` failure path through `Axes._convert_dx`. This is a
partial-correctness audit of the affected helper and observable `bar` behavior,
not a full formalization of all Matplotlib.

## Required Behaviors

1. `ax.bar([np.nan], [np.nan])` is in scope and must not raise
   `StopIteration`.

2. For the all-NaN reproduction, `bar` must still return a bar container with
   one rectangle whose geometry carries nonfinite values rather than aborting
   before artist creation.

3. `ax.bar([np.nan], [0])` is also in scope because the issue identifies the
   x-position conversion as the failure, independently of whether the bar height
   is finite.

4. The prior first-finite behavior for mixed inputs, such as a leading `NaN`
   followed by finite x values, must be preserved. The issue text identifies
   that behavior as the fix for the older "first element is NaN" bug.

5. Empty bar data is not changed by this fix. The issue mentions
   `ax.bar([], [])` as an existing reason seaborn uses a phantom NaN bar, but it
   does not request changing empty-bar artist cardinality.

6. Unit-aware width conversion remains in scope. `_convert_dx` exists so widths
   such as date/timedelta-like values can be converted by adding the delta to a
   representative original coordinate and subtracting the converted coordinate.

7. No public API shape should change. The repair should be internal to the
   conversion path and must not modify test files.

## Default-Domain Assumptions

- `xconv` is an `np.ndarray`, matching the helper assertion.
- For non-empty `xconv`, `x0` and `xconv` represent the same coordinate data
  before and after unit conversion.
- `cbook._safe_first_finite` raises `StopIteration` exactly when an iterable has
  no finite/non-None element in the searched domain.
- `cbook.safe_first_element` returns the first iterable element without finite
  filtering for non-empty, non-generator inputs.
- This audit proves partial correctness of the conversion branch. It does not
  prove rendering, autoscaling, or total absence of unrelated downstream errors.
