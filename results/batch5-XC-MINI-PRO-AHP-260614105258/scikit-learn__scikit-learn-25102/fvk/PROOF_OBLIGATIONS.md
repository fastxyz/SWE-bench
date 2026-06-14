# PROOF OBLIGATIONS — scikit-learn #25102 (V1 audit)

Each obligation lists: the property, its domain (precondition), the intent-ledger
entry it serves, how V1 discharges it, and status. "Constructed, not
machine-checked" applies to every formal claim (no execution environment).

| ID | Obligation | Domain / precondition | Serves | Discharge | Status |
|----|------------|-----------------------|--------|-----------|--------|
| **PO-1** | **Dtype preservation.** With pandas output and a DataFrame input, every selected output column has the **same dtype** as its source column. | `config = pandas`, `X` is a DataFrame, `mask` non-empty, `len(mask)=n_features` | L1, L2 | (TRANSFORM-PRESERVE) ∘ (DTYPE-FRAME): output is `df(selectCols(Cs,M))`; `selectCols` copies columns verbatim ⇒ dtypes intact. | ✅ proved (constructed) |
| **PO-2** | **Value preservation.** Selected columns carry the **same values** as the input (selection does not modify values). | same as PO-1 | L1 | (SELECT-FRAME): each surviving `col(Name,Dtype,Vals)` is kept verbatim; values untouched. | ✅ proved (constructed) |
| **PO-3** | **Validation pass-through.** `_validate_data(X, cast_to_ndarray=False)` returns `X` **unchanged** (no ndarray conversion), still running `_check_feature_names` / `_check_n_features`. | **X-only** validation (`y = "no_validation"`) — the feature's sole call site | L3 | `validate(X, false) ⇒ X`; in code the `if cast_to_ndarray:` guard skips `check_array`, the name/feature checks run unconditionally. | ✅ proved (constructed), domain-scoped — see F4 |
| **PO-4** | **Default-path backward compat.** With default output, a DataFrame yields the legacy **homogeneous-ndarray** selection (dtype intentionally collapsed). | `config = default`, `X` a DataFrame | L4 | (TRANSFORM-DEFAULT): `xform(df,default,M) ⇒ arr(commonDtype(Cs), selectCols(Cs,M))`. | ✅ proved (constructed) |
| **PO-5** | **Non-DataFrame backward compat.** ndarray/sparse input is never preserved-as-DataFrame for any config; legacy result. | `X` not a DataFrame, any `config` | L4, L7 | (TRANSFORM-NONDF): `isDf(arr)=false ⇒ preserve=false ⇒ toNdarray(arr)=arr`. | ✅ proved (constructed) |
| **PO-6** | **Selection correctness.** Output columns = exactly the masked sublist of input columns, in order. | `len(mask)=n_features` | L1, L5 | (SELECT-FRAME): `selectCols` keeps index `i` iff `mask[i]`, preserving order. | ✅ proved (constructed) |
| **PO-7** | **Indexing equivalence.** `_safe_indexing(X, mask, axis=1)` equals the legacy `X[:, safe_mask(X, mask)]` for ndarray and sparse. | `X` ndarray or sparse, boolean `mask` | L7 | Existing test `test_safe_indexing_2d_mask` (array/sparse/dataframe × axis 0/1, bool mask) asserts the correct subset; dense is literally `X[:, mask]`. | ✅ verified by existing test (F1) |
| **PO-8** | **Output labels unchanged.** Output column **labels** equal `get_feature_names_out()` (only dtypes improve, not names). | preserve path | L6 | `_wrap_in_pandas_container` overwrites `.columns = get_feature_names_out()`; equals `feature_names_in_[mask]` (F5). | ✅ reasoned (F5); not formalized (labels abstracted out) |
| **PO-9** | **Empty / shape guards intact.** Empty mask → warn + empty container; `len(mask)≠n_features` → `ValueError`. Guard ordering unchanged from V0. | any | L1 (safety) | `_transform` keeps both guards before `_safe_indexing`; DataFrame empty case returns `X.iloc[:, :0]` (F6). | ✅ reasoned (F6); guards not modeled (outside fragment) |
| **PO-10** | **Termination.** `transform` / `_transform` / `_safe_indexing` terminate. | finite `n_features` | — | No new loops; `selectCols` recurses on a strictly shorter list each step (measure = `size(Cs)`). | ✅ trivial (finite recursion) |

## Domain notes (scoping, à la the kit's `n ≥ 0`)

- **PO-3 is scoped to X-only validation.** The combined X-and-y branch of
  `_validate_data` does not honor `cast_to_ndarray` (Finding **F4**). This is
  *out-of-domain* for the feature, since `SelectorMixin.transform` only ever calls
  `_validate_data(X, …)`. The obligation is stated with that precondition rather
  than weakened, mirroring how the `sum` example states `requires N ≥ 0` and reports
  `n < 0` as a finding. **In V2 the `cast_to_ndarray` docstring was clarified to
  state this scope**, so the human-readable spec now matches the (correct) code; the
  control flow itself was left untouched (no caller exercises the combined branch).
- **PO-3's preserve path skips finiteness** (Finding **F3**) — intended; not a
  postcondition of the feature. Tests asserting NaN-rejection in `transform` are
  out-of-domain for the preserve path.

## What is NOT claimed (residual risk)

- The mini-X fragment abstracts away numeric values and `check_array`'s actual
  homogenization arithmetic; it models only *which* columns survive and *what dtype*
  each carries (the audited property). Adequacy of that abstraction is part of the
  trusted base.
- `_wrap_in_pandas_container` relabeling, warnings, and exceptions are reasoned
  about (F5, F6, F9) but not symbolically executed.
- Partial correctness only by default; termination (PO-10) is argued informally, not
  via a formal variant.
- Constructed, **not** machine-checked — discharge with the `kompile`/`kprove`
  commands in `PROOF.md` to upgrade to machine-verified.
