# SPEC — SelectorMixin DataFrame-dtype preservation (scikit-learn #25102)

**Mode:** intent-spec (align NL intent ↔ code ↔ formal spec).
**Status:** constructed, **not** machine-checked (no execution environment; the
`kompile`/`kprove` commands are emitted in `PROOF.md`).
**Artifacts:** [`mini_sklearn.k`](mini_sklearn.k) (fragment semantics),
[`mini_sklearn-spec.k`](mini_sklearn-spec.k) (claims).

This audits the V1 fix described in [`../reports/baseline_notes.md`](../reports/baseline_notes.md):

- `sklearn/feature_selection/_base.py` — `SelectorMixin.transform` / `_transform`
- `sklearn/base.py` — `BaseEstimator._validate_data(..., cast_to_ndarray=True)`
- `sklearn/utils/validation.py` — `_is_pandas_df`

---

## 1. Public intent ledger

| # | Source | Evidence (quoted / paraphrased) | Semantic obligation | Status |
|---|--------|----------------------------------|---------------------|--------|
| L1 | prompt (title) | "Preserving dtypes for DataFrame output by transformers that **do not modify the input values**" | When a selector outputs pandas and gets a DataFrame, each surviving column keeps its **input dtype**. | **met** by V1 (PO-1, PO-2) |
| L2 | prompt (example) | `category` and `np.float16` columns must not silently become `float64`. | Extension/low-precision dtypes preserved exactly, not upcast. | **met** (PO-1) |
| L3 | prompt (maintainer) | "the feature selection could use NumPy array to compute the features to be selected and we **select the columns on the original container before the conversion**." | Selection reads from the original DataFrame, not the homogenized array. | **met** — V1 sets `cast_to_ndarray=False` and selects via `_safe_indexing` (PO-3, PO-1) |
| L4 | prompt (maintainer) | "all operations are done with NumPy arrays under the hood, inhomogeneous types will be converted to a single homogeneous type" — preservation is **not** expected for the default/legacy path or column-modifying transformers. | Default output and non-DataFrame input keep **legacy** (homogeneous-ndarray) behavior. | **met** (PO-4, PO-5) |
| L5 | prompt | "Such a preservation might be **limited to transformers which export the same or a subset of the inputted features**." | Scope = `SelectorMixin` selectors (subset-of-columns); not `StandardScaler` etc. | **met** — change is confined to `SelectorMixin` |
| L6 | code/tests | `get_feature_names_out()` is the ground-truth for output column labels (`_check_generated_dataframe`). | Output columns must equal `get_feature_names_out()`; only dtypes change. | **met** — `_wrap_in_pandas_container` relabels to `get_feature_names_out()` (Finding F6) |
| L7 | implementation | Sparse/ndarray selection must be unchanged (no perf/format regression). | `_safe_indexing(X, mask, axis=1)` ≡ `X[:, safe_mask(X, mask)]` for ndarray/sparse. | **met** — verified by existing test `test_safe_indexing_2d_mask` (Finding F1) |

No external upstream-fix source was consulted (forbidden). Intent is taken from
`benchmark/PROBLEM.md` and the public discussion quoted therein, plus the existing
code/tests in `repo/`.

---

## 2. The modeled fragment (mini-X)

The Python under audit is container logic, not arithmetic, so the mini-X semantics
([`mini_sklearn.k`](mini_sklearn.k)) abstracts containers to:

- `df(Cols)` — a DataFrame; **each column keeps its own dtype**.
- `arr(Dtype, Cols)` — an ndarray; **all columns share one dtype** (this single
  fact models `check_array`'s homogenizing conversion = the dtype *loss* the bug
  was about).
- `Cols` = list of `col(Name, Dtype, ValsId)`; `Mask` = list of `Bool`.

Modeled functions (each a faithful 1-line abstraction of one implementation piece):

| K function | models | key rule |
|---|---|---|
| `isDf(X)` | `_is_pandas_df(X)` | `df(_)→true`, `arr(..)→false` |
| `validate(X, Cast)` | `_validate_data(X, cast_to_ndarray=Cast)` | `Cast=false → X` (unchanged); `Cast=true → toNdarray(X)` |
| `toNdarray(X)` | `check_array` homogenization | `df(Cs) → arr(commonDtype(Cs), Cs)` |
| `safeIndex1(X, M)` | `_safe_indexing(X, M, axis=1)` | container-kind-preserving column subselect |
| `selectCols(Cs, M)` | the masked column subselection | keeps `Cs[i]` **verbatim** where `M[i]` |
| `dtypesOf(X)` | `X.dtypes` | per-column dtypes (df) / repeated common dtype (arr) |
| `xform(X, Cfg, M)` | `transform`∘`_transform` (non-empty, length-matched return) | `safeIndex1(validate(X, ¬preserve), M)` |

Out of the fragment by design (not the property under audit): the actual numeric
values, the homogenizing arithmetic of `check_array`, `_wrap_in_pandas_container`
relabeling, warnings, exceptions, and the empty-mask / shape-mismatch guards
(handled as Findings, not modeled — see `FINDINGS.md`).

---

## 3. Function contracts (claims)

Stated formally in [`mini_sklearn-spec.k`](mini_sklearn-spec.k); in English:

- **(SELECT-FRAME)** — *circularity over the column list.* `selectCols(Cs, M)`
  returns the sublist of `Cs` at the true positions of `M`, **each element
  unchanged**. (List recursion; discharged by its own coinductive hypothesis.)
  Precondition `size(Cs) == size(M)`.

- **(DTYPE-FRAME)** — `dtypesOf(df(selectCols(Cs, M))) == selectCols(dtypesOf(df(Cs)), M)`.
  Every surviving column reports its **original** dtype. (Corollary of SELECT-FRAME.)

- **(TRANSFORM-PRESERVE)** — for a DataFrame and `config = pandas`:
  `xform(df(Cs), pandas, M) ⇒ df(selectCols(Cs, M))`. Output is a DataFrame built
  from the original columns ⇒ dtypes preserved (with DTYPE-FRAME). *Meets L1, L2, L3.*

- **(TRANSFORM-DEFAULT)** — for a DataFrame and `config = default`:
  `xform(df(Cs), default, M) ⇒ arr(commonDtype(Cs), selectCols(Cs, M))`. Homogeneous
  ndarray = exactly the legacy V0 result. *Meets L4 (no behavior change off the new path).*

- **(TRANSFORM-NONDF)** — for an ndarray and **any** config:
  `xform(arr(D, Cs), Cfg, M) ⇒ arr(D, selectCols(Cs, M))`. Non-DataFrame input is
  never preserved-as-DataFrame ⇒ legacy result. *Meets L4, L7.*

Preconditions assumed (and discharged elsewhere in the real code, see Findings):
the support `Mask` is non-empty and `size(Mask) == n_features` (enforced by
`_transform`'s empty/shape guards and `_check_n_features`); `config ∈ {default,
pandas}` (enforced by `_get_output_config`).

---

## 4. What "preserve" means precisely (frame condition)

The property is a **frame condition**, not an arithmetic closed form: for every
column index `i` with `mask[i]` true,

```
output_column(i).dtype  ==  input_column(σ(i)).dtype
output_column(i).values ==  input_column(σ(i)).values   (selection does not modify values)
```

where `σ` maps output positions to the corresponding input positions. This is the
formal reading of L1 ("transformers that do not modify the input values") and L2
(`category`/`float16` survive). SELECT-FRAME establishes it because `selectCols`
copies surviving `col(Name, Dtype, Vals)` nodes **verbatim**.
