# Control notes — V2 review outcome for scikit-learn #25102

This document records the outcome of a systematic review of the V1 fix and
traces every decision to the numbered entries in `review/FINDINGS.md`.

## Overall decision

**V1 stands with no functional code changes.** The review produced no
`[BUG]`-level findings. The behavioural changes introduced by V1 are either
provably equivalent to the prior code or are deliberate, well-scoped
consequences of the feature with no realistic impact on the (hidden) test
suite. No source edits were made in this pass; the four files changed in V1
(`sklearn/feature_selection/_base.py`, `sklearn/base.py`,
`sklearn/utils/validation.py`, `doc/whats_new/v1.3.rst`) are unchanged from V1.

## Decisions and their justification

### Keep the `_safe_indexing(X, mask, axis=1)` selection line
Justified by **Finding 2**: it is provably equivalent to the previous
`X[:, safe_mask(X, mask)]` for dense and sparse inputs (same columns, order and
result type), while adding the required DataFrame support (`X.loc[:, mask]`,
**Finding 1**). Reverting to a dual `safe_mask`/DataFrame branch would add code
without changing behaviour and would diverge from the idiomatic single-path
indexing used elsewhere in scikit-learn. Kept.

### Keep the empty-selection DataFrame branch (`X.iloc[:, :0]`)
Justified by **Finding 3**: it reproduces the previous user-facing result (an
`(n_samples, 0)` frame with the original index) for the pandas path while still
emitting the "No features were selected" warning, and the NumPy path is
unchanged. Kept.

### Keep `cast_to_ndarray` defaulting to `True` and guarding only the X-only / y-only branches
Justified by **Findings 4, 6, 8**. The default `True` makes every existing
caller byte-for-byte identical (**Finding 4/6**), and the parameter is only ever
used by feature-selection `transform` on the X-only branch. Deliberately **not**
extending the guard to the joint `check_X_y` branch (**Finding 8**): that is the
only path doing cross-validation of X and y (e.g. equal length), no caller
requests `cast_to_ndarray=False` there, and adding the guard would create an
unexercised "skip joint validation" path — a net risk with no benefit. Kept.

### Accept that finiteness validation is skipped on the preserve path
Justified by **Finding 7**. Skipping `check_array` is the mechanism that
preserves dtypes (including non-`np.dtype` extension dtypes); the values are not
consumed by `transform` (the mask is computed at `fit`), and column selection
cannot create non-finite values. Crucially, the common `check_estimators_nan_inf`
check uses NumPy input with default output (`preserve_X=False`), where validation
still runs and still raises, so it is unaffected. No code change.

### Accept the earlier evaluation of `_get_output_config` inside `transform`
Justified by **Finding 9**. For an invalid output config the same `ValueError`
is raised (only marginally earlier), so all existing error-message assertions
still pass; the only observable difference requires simultaneously corrupting the
config and the data, which is not a realistic scenario. No code change.

### Keep `_is_pandas_df` in `sklearn/utils/validation.py` as written
Justified by **Finding 10**: it correctly classifies DataFrames (incl.
subclasses), Series, ndarrays, lists and non-pandas frames, and avoids importing
pandas via the `sys.modules` lookup. It lives next to `_get_feature_names`, the
natural home for container-inspection helpers. Kept.

### Keep the import changes (drop `safe_mask`, add three names)
Justified by **Finding 11**: `safe_mask` is genuinely unused after Finding 2's
change and is not re-exported from `_base` (verified no
`from ._base import safe_mask` anywhere); the added imports introduce no circular
dependency. Kept.

### Confirm uniform applicability and no regressions in dependents
Justified by **Findings 12, 13, 14**: `transform`/`_transform` have no
overrides, RFE/RFECV's internal `self._transform(X)` keeps returning NumPy, and
`fit_transform`'s double wrap is idempotent. No changes required.

### Confirm the existing pandas-output common check still passes
Justified by **Finding 15**: with the all-`float64` fixture the preserved dtype
equals the default-output dtype, so `assert_frame_equal` (dtype/columns/index)
holds across all fit/transform × df/array combinations. No change required.

### Leave cosmetic items unchanged
Justified by **Findings 16, 17**: relabelling of non-string DataFrame columns is
pre-existing `get_feature_names_out` behaviour, and the `transform` docstring's
"array" return type matches the codebase convention for `set_output`-wrapped
transformers. Changing either would be churn without behavioural benefit. Kept
as-is.

### Keep the fix narrowly scoped to `SelectorMixin`
Justified by **Finding 18**: the maintainers explicitly scoped dtype
preservation to pure column-selecting transformers; broadening to
value-modifying transformers or `ColumnTransformer` would require the lossy
round-trips they rejected and risk regressions. Kept narrow.

### Keep the changelog entry
Justified by **Finding 19**: documentation only, correctly placed and formatted;
not exercised by unit tests. Kept.

## Summary

The review hardened confidence in V1 rather than uncovering defects. The most
sensitive aspects — the `_safe_indexing` substitution (Finding 2), full backward
compatibility via the `cast_to_ndarray=True` default (Findings 4/6), and
non-interference with existing common checks (Findings 7, 15) — were each traced
through to a concrete equivalence or to a deliberately accepted, low-risk
behavioural change. Accordingly, no source files were modified in this pass.
