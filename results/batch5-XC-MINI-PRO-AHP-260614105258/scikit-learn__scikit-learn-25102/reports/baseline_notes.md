# Baseline notes — scikit-learn #25102

## Issue

When a feature‑selection transformer is configured with
`set_output(transform="pandas")` (or the global `transform_output="pandas"`
config) and is given a heterogeneous pandas `DataFrame`, the returned
`DataFrame` loses the per‑column dtypes of the input. In the reported example
`SelectKBest(chi2, k=2)` turns `np.float16` and `category` columns into
`float64`:

```
petal length (cm)    float64
cat                  float64
```

The maintainers agreed that, while preserving heterogeneous dtypes in general
(e.g. `StandardScaler`) is hard, it is cheap to do for transformers that merely
**select a subset of the input columns** without modifying their values:
"the feature selection could use a NumPy array to compute the features to be
selected and we select the columns on the original container before the
conversion." This change implements exactly that for every
`SelectorMixin`‑based selector.

## Root cause

`SelectorMixin.transform` (in `sklearn/feature_selection/_base.py`) always ran
the input through `self._validate_data(...)`, which calls `check_array` and
converts the `DataFrame` to a single homogeneous NumPy array *before* the
columns are selected. The dtype (and any extension dtype such as `category`)
is therefore lost at the validation step, long before the output is wrapped
back into a `DataFrame` by `_SetOutputMixin`. Because the values are merely
sub‑selected (not modified), this conversion is unnecessary when pandas output
is requested and a `DataFrame` was passed in.

## Fix

The selection is now performed on the original `DataFrame` when pandas output
is configured, so each selected column keeps its exact dtype. The output then
flows through the existing `_wrap_in_pandas_container`, which already preserves
dtypes for `DataFrame` inputs (it only re‑labels columns/index).

### Files changed

1. **`sklearn/utils/validation.py`**
   - Added `import sys`.
   - Added a small private helper `_is_pandas_df(X)` that returns `True` only
     for a genuine `pandas.DataFrame`. It uses `sys.modules["pandas"]` so it
     never imports pandas itself: if pandas was never imported, the object
     cannot be a `DataFrame`, and it returns `False`. This is the predicate
     used to decide whether dtype preservation is possible.

2. **`sklearn/base.py`** — `BaseEstimator._validate_data`
   - Added a new keyword argument `cast_to_ndarray=True`.
   - When `cast_to_ndarray=False`, the `X`‑only and `y`‑only branches skip the
     `check_array` / `_check_y` conversion and leave the input unchanged, while
     `_check_feature_names` and `_check_n_features` are still run (both work
     natively on `DataFrame`s). Documented the new parameter. The default
     (`True`) keeps the behaviour of every existing caller byte‑for‑byte.

3. **`sklearn/feature_selection/_base.py`** — `SelectorMixin`
   - Imports: dropped the now‑unused `safe_mask`; added `_safe_indexing`,
     `_get_output_config`, and `_is_pandas_df`.
   - `transform`: compute
     `preserve_X = output_config_dense != "default" and _is_pandas_df(X)` and
     pass `cast_to_ndarray=not preserve_X` to `_validate_data`. When pandas
     output is requested for a `DataFrame`, validation no longer collapses the
     dtypes; otherwise behaviour is unchanged.
   - `_transform`: select columns with `_safe_indexing(X, mask, axis=1)`, which
     handles NumPy arrays, sparse matrices and `DataFrame`s uniformly (for a
     `DataFrame` it becomes `X.loc[:, mask]`, preserving dtypes). The
     "no features selected" branch now returns an empty `DataFrame`
     (`X.iloc[:, :0]`) when the input is a `DataFrame`, and the previous empty
     NumPy array otherwise.

4. **`doc/whats_new/v1.3.rst`** — added a changelog entry under a new
   `sklearn.feature_selection` section.

### Why `_safe_indexing` is equivalent for the non‑pandas paths

- Dense ndarray: `_safe_indexing(X, bool_mask, axis=1)` → `X[:, bool_mask]`,
  identical to the old `X[:, safe_mask(X, mask)]` (for dense, `safe_mask`
  returns the boolean mask unchanged).
- Sparse: `_array_indexing` explicitly handles the `issparse` + boolean‑mask +
  `axis=1` case (`X[:, np.asarray(mask)]`); scipy converts the boolean mask to
  integer indices internally, giving the same columns as the old
  `safe_mask`‑based integer indexing. The all‑False case never reaches
  `_safe_indexing` because it is short‑circuited by the `not mask.any()` branch.

## Scope

The change affects only `SelectorMixin.transform`/`_transform` (so all
univariate selectors, `VarianceThreshold`, `RFE`/`RFECV`, `SelectFromModel`,
`SequentialFeatureSelector`, …) plus the opt‑in `cast_to_ndarray` plumbing on
`_validate_data`. With the default `transform="default"` output, or with NumPy
/ sparse input, every code path is byte‑for‑byte unchanged. `fit` is untouched
(it still converts to NumPy to compute the support mask), so score functions
such as `chi2` continue to operate on NumPy arrays.

## Assumptions and rejected alternatives

- **Assumption:** dtype preservation should be limited to transformers that
  output a subset of the input columns (feature selectors). This matches the
  maintainers' explicit conclusion in the issue thread that doing it generally
  for value‑modifying transformers like `StandardScaler` is out of scope and
  potentially "lossy/surprising". I therefore did **not** touch
  `StandardScaler` or other column‑wise transformers.

- **Rejected alternative — add a `dtypes` argument to
  `_wrap_in_pandas_container` and re‑apply them with `astype` (the literal
  suggestion in the issue):** this cannot correctly restore a subset of columns
  (output columns ≠ input columns for a selector) and, more importantly, an
  `astype` round‑trip is lossy and cannot faithfully rebuild an extension dtype
  such as `category` from a float NumPy array. Selecting from the original
  container avoids any conversion and preserves the dtype exactly, which is the
  approach the maintainers described.

- **Rejected alternative — add `cast_to_ndarray` to the public `check_array`
  and have it validate‑but‑return‑the‑original:** keeping the switch in
  `_validate_data` is more localized, avoids touching a heavily used public
  function, and—because it skips the NumPy conversion entirely—correctly
  handles non‑numeric extension dtypes (e.g. string `category`) that a forced
  finiteness check on a converted object array could otherwise reject.

- **Assumption:** running `_validate_data` with `cast_to_ndarray=False` should
  still perform the `feature_names_in_` / `n_features_in_` consistency checks.
  These operate directly on the `DataFrame` and preserve the existing
  validation/warnings (e.g. the "fitted without feature names" warning), so the
  only behavioural difference on the preserve path is that the per‑value
  finiteness check is skipped — acceptable because the values are passed
  through unchanged and were already validated during `fit`.
