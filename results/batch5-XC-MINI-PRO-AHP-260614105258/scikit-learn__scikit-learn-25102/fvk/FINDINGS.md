# FINDINGS — FVK audit of the V1 fix (scikit-learn #25102)

Plain-language findings, each as `input → observed vs expected`, with a
classification and what (if anything) to do. The audit's headline result:
**the V1 fix is behaviorally correct on its specified domain and stands; the only
edit is a zero-risk docstring clarification (F4) that makes the spec match the
code.** The single highest-risk edit (the sparse indexing change) is shown
behavior-preserving by an *existing* test.

Legend for classification: `confirmation` (property holds), `intended-behavior`
(deliberate, traced to intent), `latent/out-of-domain` (real but unreachable by
this feature), `pre-existing` (not introduced by V1).

---

## F1 — Sparse/ndarray selection unchanged by `_safe_indexing` switch ✅ confirmation

V1 replaced `return X[:, safe_mask(X, mask)]` with
`return _safe_indexing(X, mask, axis=1)` in `SelectorMixin._transform`. This is the
**riskiest** line in the fix: a wrong sparse result would silently corrupt *every*
sparse feature selection.

- input: `X` a CSR matrix, `mask = [False, True, True]`, `axis=1` → observed:
  `_array_indexing` runs `X[:, np.asarray(mask)]`; expected: the same column subset
  as the legacy `X[:, safe_mask(X, mask)]` (which converts the bool mask to integer
  indices).
- **Verification:** the existing, non-hidden test
  `sklearn/utils/tests/test_utils.py::test_safe_indexing_2d_mask` is parametrized
  over `array_type ∈ {array, sparse, dataframe}` × `axis ∈ {0,1}` with a boolean
  mask and asserts the exact expected subset. So `_safe_indexing(sparse, bool,
  axis=1)` is already proven to produce the correct columns. For dense, `safe_mask`
  returns the boolean mask unchanged, so `X[:, mask]` is literally identical.
- **Action:** none. (Discharges PO-7 and intent L7.)

## F2 — Backward compatibility on the default/legacy path ✅ confirmation

- input: any `X`, `set_output` left at `transform="default"` → observed:
  `preserve_X = ("default" != "default") and … = False` ⇒ `cast_to_ndarray=True` ⇒
  `_validate_data` converts to ndarray exactly as before ⇒ `_transform` returns
  `_safe_indexing(ndarray, mask, axis=1) == ndarray[:, mask] == ndarray[:,
  safe_mask(...)]`. expected: byte-for-byte V0 behavior.
- input: `X` a numpy array, `transform="pandas"` → observed: `_is_pandas_df(X)=False`
  ⇒ `preserve_X=False` ⇒ legacy path, then `_wrap_in_pandas_container` builds the
  DataFrame from the ndarray (nothing to preserve). expected: unchanged.
- **Action:** none. (Discharges PO-4, PO-5; intent L4, L7.)

## F3 — Preserve path skips `check_array` finiteness/numeric validation — intended-behavior

On the preserve path, `_validate_data(cast_to_ndarray=False)` does **not** call
`check_array`, so `force_all_finite` / `dtype` / `accept_sparse` are not enforced
during `transform`.

- input: an `allow_nan=False` selector, fitted, then `transform(df_with_NaN)` with
  `transform="pandas"` → observed: returns the selected columns (NaN passes
  through), **no** error; expected under V0: `ValueError("Input contains NaN")`.
- **Why this is intended, not a bug:** (a) feature selection does **not compute on**
  the values during `transform` — it only *selects columns the fit already chose*;
  the values are passed through unmodified, so a finiteness check is not needed for
  correctness. (b) Validating to ndarray *for the check* would re-introduce the very
  homogenization the fix removes, and could even *reject* legitimate preserved
  dtypes (e.g. a string-`category` column → object array → finiteness check), so the
  clean implementation of "don't cast" is "don't call `check_array`." (c) The
  feature-names / `n_features_in_` consistency checks are still performed
  (`_check_feature_names`, `_check_n_features` run before the cast branch).
- **Action:** none; documented. Tests asserting NaN-rejection during `transform`
  would be **out-of-domain** for the preserve path (kept, not removed).

## F4 — `cast_to_ndarray` is honored only on single-array validation — latent/out-of-domain

`_validate_data` guards the `check_array`/`_check_y` call in the **X-only** and
**y-only** branches. The combined **X-and-y** branch (`else`: `validate_separately`
/ `check_X_y`) still converts regardless of `cast_to_ndarray`.

- input: `_validate_data(X, y, cast_to_ndarray=False)` → observed: X, y are still
  cast; expected (literal reading of the new docstring): unchanged.
- **Why it does not matter here:** the *only* caller that passes `cast_to_ndarray`
  is `SelectorMixin.transform`, which calls `_validate_data(X, …)` with `y` left at
  its `"no_validation"` default — i.e. **always the X-only branch**. No code path in
  the codebase combines `cast_to_ndarray=False` with joint X/y validation. The
  obligation PO-3 is therefore scoped to the single-array domain (analogous to the
  `n ≥ 0` precondition in the kit's `sum` example), and the combined path is an
  explicit **out-of-domain** case.
- **Action (taken in V2):** the *code* stands (guarding the unreachable `else`
  branch would touch the hot `_validate_data` control flow for no caller), but the
  V1 docstring over-promised ("`X` and `y` are unchanged"). That spec/code mismatch
  is **resolved** by a zero-risk docstring clarification in `sklearn/base.py`:
  `cast_to_ndarray` is "only honored when validating `X` or `y` on its own;
  validating `X` and `y` together always casts." Spec now matches code. A future
  pass may still choose to guard the `else` branch (see `ITERATION_GUIDANCE.md`).

## F5 — Output column **labels** still come from `get_feature_names_out()` ✅ confirmation

After the preserve path returns `df.loc[:, mask]` (original names), the wrapper
`_wrap_in_pandas_container` overwrites `.columns = get_feature_names_out()`.

- input: selector fit on a **numpy** array, `transform(df)` with `transform="pandas"`
  → observed: dtypes preserved from `df`, but column **names** become the generated
  `x0, x2, …` from `get_feature_names_out()` (and a "fitted without feature names"
  warning fires, exactly as in V0). expected: labels identical to V0 (only dtypes
  improve).
- input: selector fit and transformed on the **same** df → `df.loc[:, mask]` columns
  already equal `feature_names_in_[mask] == get_feature_names_out()`; the relabel is
  a no-op. expected: names and dtypes both correct.
- **Action:** none. The existing common check `check_set_output_transform_pandas`
  uses an all-`float64` frame, so preservation is a no-op there and the check still
  passes; the *mixed-dtype* assertion is the new behavior the fix adds. (Intent L6.)

## F6 — Empty selection returns an empty DataFrame on the preserve path ✅ confirmation

- input: `mask` all-False, `X` a df, `transform="pandas"` → observed: warns, returns
  `X.iloc[:, :0]` (0 columns, X's index/row-count); `_wrap_in_pandas_container` then
  sets `.columns = []`. expected: an empty DataFrame consistent with V0's
  `pd.DataFrame(np.empty((n,0)), columns=[])`. Match.
- Note the guard ordering is preserved: the all-False branch precedes the
  `len(mask) != X.shape[1]` shape check, identical to V0.
- **Action:** none.

## F7 — `_is_pandas_df` is robust ✅ confirmation

- `df` → `True`; `np.ndarray` → no `.columns` → `False`; `pd.Series` → no `.columns`
  → `False`; a polars/other frame with `.columns` but no `.iloc` → `False`; an
  arbitrary object with `.columns`+`.iloc` but not a `DataFrame` → `isinstance`
  guard → `False`. `sys.modules["pandas"]` is present whenever any `DataFrame`
  exists (you cannot build one without importing pandas), so the lazy lookup never
  misfires.
- **Action:** none.

## F8 — `df.loc[:, mask]` returns a copy → no aliasing ✅ confirmation

`_safe_indexing` → `_pandas_indexing` → `X.loc[:, bool_mask]`, which returns a
**copy**. The subsequent `_wrap_in_pandas_container` `.columns`/`.index` mutation
therefore cannot mutate the caller's original DataFrame, and no
`SettingWithCopyWarning` is raised.
- **Action:** none.

## F9 — Config error precedence shifts for doubly-invalid input — pre-existing/negligible

`transform` now reads `_get_output_config` *before* `_validate_data`. For a normal
(valid) config this only reads the threadlocal config one extra time (cheap, no
observable effect). If the config is invalid **and** `X` is also invalid, V1 raises
the config `ValueError("output config must be 'default' or 'pandas'")` *before* the
input-shape error, whereas V0 raised the shape error first.
- input: bad `set_output(transform="bad")` **and** wrong-shaped `X` → observed:
  config error; expected (V0): shape error.
- **Why benign:** requires two simultaneous user errors; both raise `ValueError`;
  the existing error-message-match tests (`output config must be 'default'`) still
  pass. No realistic test exercises the double-invalid combination.
- **Action:** none.

---

## Spec-difficulty signal

A **clean** spec was writable (SPEC.md §3): the property is a tidy *frame
condition* with a single soundness precondition (`size(mask) == n_features`,
`mask` non-empty, `config ∈ {default, pandas}`), all of which the code enforces via
existing guards. No awkward case-split or missing-precondition smell surfaced for
the in-scope behavior — consistent with V1 being correct. The **only** place a
clean universal spec was *not* writable was the `_validate_data` combined-branch
(F4), which is exactly why that obligation is scoped, and the limitation reported,
rather than papered over.

## Proof-derived findings from `/verify`

See `PROOF.md`. The proof of SELECT-FRAME, TRANSFORM-PRESERVE, TRANSFORM-DEFAULT,
and TRANSFORM-NONDF goes through with no invented side conditions beyond the
documented preconditions; the one VC of interest (DTYPE-FRAME: dtypes distribute
over verbatim subselection) is discharged by the same list induction as
SELECT-FRAME. No proof obstacle escalated to a code bug. The proof **could not**
close a universal statement about `_validate_data` over the combined X/y branch —
that non-closure is precisely Finding F4, and it is handled by scoping PO-3, not by
weakening the claim.
