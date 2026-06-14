# Code review — V1 fix for scikit-learn #25102

Scope of V1: preserve per-column dtypes of a pandas `DataFrame` for feature
selectors (`SelectorMixin`) when `set_output(transform="pandas")` (or the
global `transform_output="pandas"`) is active. Files touched:
`sklearn/feature_selection/_base.py`, `sklearn/base.py`
(`_validate_data`), `sklearn/utils/validation.py` (`_is_pandas_df`, `import
sys`), and `doc/whats_new/v1.3.rst`.

Severity legend: **[BUG]** must fix, **[RISK]** behavioural change to weigh,
**[OK]** reviewed and correct, **[NIT]** cosmetic.

---

## 1. [OK] Core behaviour matches the issue

`SelectKBest(chi2, k=2).set_output(transform="pandas").fit_transform(X, y)` on
the issue's mixed-dtype frame now returns the selected columns with their
original dtypes (e.g. `petal length (cm) → float16`, `cat → category`).
Trace: `fit` still converts to NumPy and computes the support mask
(`_univariate_selection._BaseFilter.fit` uses the default
`cast_to_ndarray=True`); `transform` sets `preserve_X=True`, so
`_validate_data(..., cast_to_ndarray=False)` returns the original DataFrame, and
`_transform` selects columns with `_safe_indexing(X, mask, axis=1)` →
`X.loc[:, mask]`, which preserves each column's dtype. `_wrap_in_pandas_container`
already preserves dtypes for a DataFrame input (it only re-labels columns/index).

## 2. [OK] `_safe_indexing(X, mask, axis=1)` is equivalent to the old `X[:, safe_mask(X, mask)]`

The selection line changed from `X[:, safe_mask(X, mask)]` to
`_safe_indexing(X, mask, axis=1)`. Verified equivalence on every container:
- **dense ndarray:** `safe_mask` returns the boolean mask unchanged → old
  `X[:, mask]`; `_safe_indexing` → `_array_indexing` → `X[:, mask]`. Identical
  (both return a copy via boolean fancy indexing).
- **sparse (csr/csc):** `safe_mask` converts the boolean mask to integer indices
  (`np.arange(n)[mask]`) → `X[:, int_idx]`; `_safe_indexing` →
  `_array_indexing` has an explicit `issparse(...) and key_dtype == "bool"`
  branch → `X[:, np.asarray(mask)]`, and scipy converts the boolean mask to the
  same integer indices internally. Same columns, same order, same csr result.
  The all-False mask never reaches this line (short-circuited by `not
  mask.any()`), so the historically-problematic empty sparse slice cannot occur.
- **DataFrame (new):** `_pandas_indexing` → `X.loc[:, mask]` returns a DataFrame
  (never a Series, even for a single selected column), preserving dtypes.

Conclusion: no regression for ndarray/sparse; correct new behaviour for
DataFrame.

## 3. [OK] Empty-selection branch for DataFrames

When `not mask.any()`, V1 returns `X.iloc[:, :0]` for a DataFrame and the
previous `np.empty(0, dtype=X.dtype).reshape((X.shape[0], 0))` otherwise. The
warning is still emitted. The DataFrame result is an `(n_samples, 0)` frame with
the original index — user-facing identical to the pre-fix pandas path, where the
empty NumPy array was wrapped into a 0-column DataFrame with the same index.
`_wrap_in_pandas_container` then sets `.columns` to the (empty)
`get_feature_names_out()` without error.

## 4. [OK] Backward compatibility of the default / global-config paths

With `transform="default"` (the default) `output_config_dense == "default"`, so
`preserve_X=False`, `cast_to_ndarray=True`, and the code is byte-for-byte the
old path (validate to ndarray → `_transform` → `_safe_indexing` ≡ old indexing).
NumPy or sparse input always yields `preserve_X=False` (because `_is_pandas_df`
is False) regardless of the output config. Global `config_context(
transform_output="pandas")` is honoured because `_get_output_config` falls back
to the global config.

## 5. [OK] `fit` is untouched

No selector's `fit` was modified; `_BaseFilter.fit` and the meta-selectors still
call `_validate_data(X, y, ...)` with the default `cast_to_ndarray=True`, so the
score functions (`chi2`, `f_classif`, …) keep receiving NumPy arrays. Category
columns are converted to their numeric codes/values for scoring exactly as
before; only the *output* container of `transform` changes.

## 6. [OK] `_validate_data(cast_to_ndarray=...)` — default preserves all callers

The new parameter defaults to `True`. Every existing caller (none passes the
parameter) therefore behaves identically. `_check_feature_names` (run before the
branches) and `_check_n_features` (run after, gated on `ensure_2d`) both operate
natively on DataFrames, so feature-name/feature-count validation and their
warnings are preserved on the `cast_to_ndarray=False` path.

## 7. [RISK → accepted] Finiteness validation is skipped on the preserve path

When `preserve_X=True`, `check_array` is not called, so a DataFrame containing
`NaN`/`inf` is no longer rejected at `transform` time for selectors with
`allow_nan=False`. This is the intended consequence of "pass the container
through unchanged"; the values are not used during `transform` (the mask is
computed at `fit`), and selecting columns cannot introduce non-finite values.
The common check `check_estimators_nan_inf` exercises `transform` with **NumPy**
input and **default** output (`preserve_X=False`), where validation still runs
and still raises — so that check is unaffected. Accepted, no change.

## 8. [RISK → accepted] `_validate_data` joint (X **and** y) branch ignores `cast_to_ndarray`

`cast_to_ndarray` is honoured only in the X-only and y-only branches; the
`else` branch (both X and y) still calls `check_X_y`. This is the only path that
performs joint validation (e.g. equal-length checks), and no caller passes
`cast_to_ndarray=False` together with both X and y (feature-selection
`transform` validates X alone). Guarding it would create an unexercised
"skip joint validation" path. Accepted, no change; the parameter is correct for
every real call site.

## 9. [RISK → accepted] `_get_output_config` is now evaluated inside `transform` before validation

V1 calls `_get_output_config("transform", self)` at the top of `transform`. For
an *invalid* output config it raises the same `ValueError("output config must be
'default' or 'pandas' …")` that the `_SetOutputMixin` wrapper raised before,
only slightly earlier (before data validation). All existing error-message
matches still succeed. The only observable change would be in the contrived case
of simultaneously setting an invalid config *and* passing malformed `X`, which is
not a realistic test. Accepted, no change.

## 10. [OK] `_is_pandas_df` correctness and robustness

- `pd.DataFrame` (and subclasses) → `True`; `np.ndarray`, lists → `False`
  (no `columns`); `pd.Series` → `False` (`columns` absent).
- Uses `sys.modules["pandas"]` rather than importing pandas: if pandas is not
  imported, the object cannot be a real DataFrame, so returning `False` is
  correct and avoids a pandas import on a hot path.
- Non-pandas frames (polars/pyarrow) → `False`, which is correct because only
  pandas output is supported at 1.3 (they fall back to the NumPy/wrap path).

## 11. [OK] Import hygiene / no circular imports / no broken re-exports

`_base.py` now imports `_safe_indexing`, `_get_output_config`, `_is_pandas_df`
and no longer imports the now-unused `safe_mask`. Verified: nothing imports
`safe_mask` *from* `feature_selection._base` (only `SelectorMixin` /
`_get_feature_importances` are imported from it; `_univariate_selection` and the
tests import `safe_mask` directly from `sklearn.utils`). The new import
`from ..utils._set_output import _get_output_config` introduces no cycle
(`_set_output` does not import `feature_selection`, and `base` already imports
`_set_output`). `_safe_indexing` is a module-level export of
`sklearn/utils/__init__.py`.

## 12. [OK] No `transform`/`_transform` overrides to conflict with

`transform` and `_transform` are defined exactly once in the feature_selection
package (`_base.py`); every selector (`SelectKBest`/`_BaseFilter`,
`VarianceThreshold`, `RFE`/`RFECV`, `SelectFromModel`,
`SequentialFeatureSelector`, …) inherits them, so the fix applies uniformly and
nothing shadows it.

## 13. [OK] RFE/RFECV internal `_transform` call stays NumPy

`_rfe.py:754` calls `self._transform(X)` where `X` is the already-validated
NumPy array from `RFECV.fit`; `_safe_indexing(ndarray, mask, axis=1)` returns a
NumPy array exactly as before. No behavioural change for the internal refit.

## 14. [OK] `fit_transform` double-wrapping is harmless

`TransformerMixin.fit_transform` calls `self.transform(X)`; both `transform`
(wrapped at `SelectorMixin`) and `fit_transform` (wrapped at `TransformerMixin`)
run `_wrap_data_with_container`. The inner call already returns a DataFrame, and
`_wrap_in_pandas_container` on a DataFrame only re-assigns columns/index
(idempotent), leaving dtypes intact.

## 15. [OK] Existing `check_set_output_transform_pandas` still passes

That common check builds its frame from `rng.uniform(...)` (all `float64`), so
the preserved dtype equals the homogeneous default-output dtype; the generated
DataFrame, its `float64` dtypes, columns (`get_feature_names_out`) and default
`RangeIndex` all match the expected frame for every fit/transform × df/array
combination (including the "fit array / transform df" case, where the same
"fitted without feature names" warning is emitted on both the default and pandas
paths).

## 16. [NIT → no change] Non-string DataFrame column names

If a selector is fit on a DataFrame whose column labels are non-strings,
`feature_names_in_` is not stored and `get_feature_names_out` emits generated
`x0…`-style names; the output frame is therefore relabelled. This is the
pre-existing behaviour of `get_feature_names_out` and is unrelated to the dtype
fix — the dtypes are still preserved. No change.

## 17. [NIT → no change] `transform` docstring still says it returns an "array"

Consistent with the rest of the codebase, where transformer `transform`
docstrings describe the default (NumPy) return type and the `set_output`
wrapping is documented separately. Left as-is for convention.

## 18. [OK] Scope is correct and intentionally narrow

The fix targets only `SelectorMixin` (pure column selection, values unchanged),
matching the maintainers' explicit conclusion in the issue thread. Value-modifying
transformers (`StandardScaler`, …) and `ColumnTransformer` are deliberately not
changed — preserving heterogeneous dtypes there would require lossy round-trips
the maintainers rejected, and is out of scope for this issue.

## 19. [OK] Changelog

A new alphabetically-placed `sklearn.feature_selection` section was added to
`doc/whats_new/v1.3.rst` with a matching-length RST underline and a valid
contributor reference. Documentation only; not exercised by unit tests.

---

## Verdict

No **[BUG]**-level findings. Every behavioural change is either provably
equivalent to the previous code (findings 2–6, 11–15) or a deliberate,
well-scoped consequence of the feature with no realistic test impact (findings
7–9). **V1 is confirmed correct and stands without functional code changes.**
