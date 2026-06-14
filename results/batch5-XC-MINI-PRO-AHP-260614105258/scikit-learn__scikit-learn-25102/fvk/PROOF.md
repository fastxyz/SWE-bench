# PROOF — SelectorMixin dtype preservation (scikit-learn #25102)

**Status: CONSTRUCTED, NOT MACHINE-CHECKED.** No execution environment is
available; below is the symbolic-execution proof against
[`mini_sklearn.k`](mini_sklearn.k), plus the exact commands to machine-check it.
Claims are in [`mini_sklearn-spec.k`](mini_sklearn-spec.k).

---

## 0. What is proved, in one line

For every DataFrame `X` and pandas output, `SelectorMixin.transform` returns a
DataFrame whose selected columns are the **original** columns — same dtype, same
values — while default output and non-DataFrame input keep the **legacy**
homogeneous-ndarray behavior. (PO-1, PO-2, PO-4, PO-5, PO-6.)

---

## 1. (SELECT-FRAME) — the circularity

**Claim.** `selectCols(CS, MS) ⇒ selectColsSpec(CS, MS)` with `requires size(CS) ==Int size(MS)`.

`selectCols` and `selectColsSpec` are defined by the *same* four rules (empty-list ×2,
keep-on-`true`, drop-on-`false`), so the claim is the list-recursion identity. K makes
the claim its own coinductive hypothesis (a circularity); we discharge by structural
recursion on `CS` — the genuine `=>⁺` step that earns the hypothesis is the head rewrite.

- **Base** `CS = .List`: rule `selectCols(.List, _) => .List` fires; RHS
  `selectColsSpec(.List, _) => .List`. Both `.List`. ✓ (closed by Reflexivity *after*
  the genuine step).
- **Step** `CS = ListItem(C) Cs`, and by the precondition `MS = ListItem(B) Ms`:
  - `B = true`: `selectCols ⇒ ListItem(C) selectCols(Cs, Ms)`. One genuine step taken
    ⇒ invoke the **circularity** on `(Cs, Ms)` (its precondition `size(Cs)==size(Ms)`
    follows from `size(CS)==size(MS)`). Reaches `ListItem(C) selectColsSpec(Cs, Ms) =
    selectColsSpec(ListItem(C) Cs, MS)`. ✓
  - `B = false`: `selectCols ⇒ selectCols(Cs, Ms)`; circularity on `(Cs, Ms)` ⇒
    `selectColsSpec(Cs, Ms) = selectColsSpec(ListItem(_) Cs, MS)`. ✓

**Guardedness:** every appeal to the hypothesis follows the head rewrite (≥1 real
step), so the coinduction is sound. The list length strictly decreases, so it also
terminates (PO-10). ∎

**Frame reading:** because the kept branch reproduces `ListItem(C)` *verbatim*, each
surviving `col(Name, Dtype, Vals)` — hence its **dtype and values** — is unchanged.
This is PO-2 and the engine of PO-1.

## 2. (DTYPE-FRAME) — dtypes distribute over selection

**Claim.** `dtypesOf(df(selectCols(CS, MS))) ⇒ selectCols(dtypesOf(df(CS)), MS)`,
`requires size(CS) ==Int size(MS)`.

Induct on `CS` (same shape as §1; reuse SELECT-FRAME as a lemma/circularity):

- `CS = .List`: LHS `dtypesOf(df(.List)) => .List`; RHS `selectCols(.List, MS) => .List`. ✓
- `CS = ListItem(col(_,D,_)) Cs`, `MS = ListItem(B) Ms`:
  - `B = true`: LHS `dtypesOf(df(ListItem(col(_,D,_)) selectCols(Cs,Ms)))
    => ListItem(D) dtypesOf(df(selectCols(Cs,Ms)))`; RHS
    `selectCols(ListItem(D) dtypesOf(df(Cs)), MS) => ListItem(D) selectCols(dtypesOf(df(Cs)),Ms)`.
    Invoke the hypothesis on `(Cs, Ms)`: both sides reach `ListItem(D) selectCols(dtypesOf(df(Cs)),Ms)`. ✓
  - `B = false`: LHS drops the head via SELECT-FRAME; RHS drops `ListItem(D)` via the
    `false` rule. Hypothesis on `(Cs, Ms)` closes it. ✓ ∎

⇒ **PO-1:** every selected output dtype equals its original input dtype. A `category`
or `float16` column stays `category` / `float16`.

## 3. (TRANSFORM-PRESERVE) — the function contract

**Claim.** `xform(df(CS), pandas, MS) ⇒ df(selectCols(CS, MS))`.

Symbolic execution of the single `xform` rule:

```
xform(df(CS), pandas, MS)
  =>  safeIndex1( validate(df(CS), notBool ((pandas =/=K default) andBool isDf(df(CS)))), MS )      // [xform]
```
Evaluate the guard by Axiom steps:
- `pandas =/=K default` ⇒ `true`;  `isDf(df(CS))` ⇒ `true` (rule `isDf(df(_))=>true`);
- `true andBool true` ⇒ `true`;  `notBool true` ⇒ `false`.

```
  =>  safeIndex1( validate(df(CS), false), MS )
  =>  safeIndex1( df(CS), MS )                    // [validate(_,false) => X]  — the NEW behavior (PO-3)
  =>  df( selectCols(CS, MS) )                    // [safeIndex1(df(Cs),M) => df(selectCols(Cs,M))]
```
Matches the claimed RHS. ✓ With §1–§2 ⇒ **PO-1, PO-2, PO-6**, i.e. intent **L1, L2, L3**. ∎

## 4. (TRANSFORM-DEFAULT) — legacy path for default output

**Claim.** `xform(df(CS), default, MS) ⇒ arr(commonDtype(CS), selectCols(CS, MS))`.

```
xform(df(CS), default, MS)
  =>  safeIndex1( validate(df(CS), notBool ((default =/=K default) andBool …)), MS )    // [xform]
```
Guard: `default =/=K default` ⇒ `false`; `false andBool _` ⇒ `false`; `notBool false` ⇒ `true`.
```
  =>  safeIndex1( validate(df(CS), true), MS )
  =>  safeIndex1( toNdarray(df(CS)), MS )         // [validate(_,true) => toNdarray]
  =>  safeIndex1( arr(commonDtype(CS), CS), MS )  // [toNdarray(df(Cs)) => arr(commonDtype(Cs),Cs)]
  =>  arr(commonDtype(CS), selectCols(CS, MS))    // [safeIndex1(arr(D,Cs),M) => arr(D,selectCols(Cs,M))]
```
Homogeneous output — every `dtypesOf` entry is `commonDtype(CS)` — i.e. exactly the
V0 numpy result. ✓ **PO-4**, intent **L4**. ∎

## 5. (TRANSFORM-NONDF) — legacy path for ndarray/sparse input

**Claim.** `xform(arr(D, CS), CFG, MS) ⇒ arr(D, selectCols(CS, MS))` for any `CFG`.

```
xform(arr(D,CS), CFG, MS)
  =>  safeIndex1( validate(arr(D,CS), notBool ((CFG =/=K default) andBool isDf(arr(D,CS)))), MS )
```
`isDf(arr(D,CS))` ⇒ `false`, so `(_ andBool false)` ⇒ `false` regardless of `CFG`;
`notBool false` ⇒ `true`.
```
  =>  safeIndex1( validate(arr(D,CS), true), MS )
  =>  safeIndex1( toNdarray(arr(D,CS)), MS )       // toNdarray(arr) = arr (identity)
  =>  safeIndex1( arr(D,CS), MS )
  =>  arr(D, selectCols(CS, MS))
```
✓ **PO-5**, intent **L4, L7**. (Models that `set_output("pandas")` on numpy/sparse
input is a no-op for preservation — there is nothing to preserve.) ∎

## 6. PO-7 — sparse indexing equivalence (discharged outside the fragment)

`_safe_indexing(X, mask, axis=1)` vs legacy `X[:, safe_mask(X, mask)]` is not an
arithmetic VC — it is a library-equivalence fact about scipy/numpy/pandas indexing.
It is discharged by the **existing** test
`sklearn/utils/tests/test_utils.py::test_safe_indexing_2d_mask`, which asserts the
correct subset for `array`/`sparse`/`dataframe` × `axis ∈ {0,1}` with a boolean
mask. For dense, `safe_mask` returns the bool mask unchanged so the two are
syntactically equal; for sparse, `_array_indexing` converts the bool mask
(`np.asarray`) and scipy selects the same columns. See FINDINGS **F1**. ✓

## 7. Composition

The Python `transform` is `xform` modulo the empty/shape guards (PO-9, reasoned in
F6/F9, outside the fragment) and the `_wrap_in_pandas_container` relabeling (PO-8,
reasoned in F5). On the main (non-empty, length-matched) return branch, §3–§5 give
the full contract by case on `(isDf(X), config)`:

| input | config | result | obligation |
|---|---|---|---|
| `df` | pandas | `df(selectCols)` — dtypes preserved | PO-1,2,6 |
| `df` | default | `arr(common, selectCols)` — legacy | PO-4 |
| ndarray/sparse | any | `arr(D, selectCols)` — legacy | PO-5 |

No proof obstacle forced an invented side condition. The arithmetic/VC tier was not
even needed (the property is structural, not numeric); the only inductions are the
two list recursions in §1–§2, both guarded and terminating.

---

## 8. Reproduce the machine check

```sh
kompile mini_sklearn.k --backend haskell          # compile the fragment semantics
kast    --backend haskell mini_sklearn-spec.k     # (optional) confirm the spec parses
kprove  mini_sklearn-spec.k                        # discharge all claims; expected: #Top
```

A `#Top` from `kprove` upgrades this from *constructed* to *machine-verified*. Until
then, treat §1–§7 as a careful hand proof.

---

## 9. Benefit payoffs

- **Benefit 2 (bugs/corner cases).** Writing the spec surfaced a clean set of
  preconditions the code already enforces (non-empty mask, `size(mask)=n_features`,
  `config ∈ {default,pandas}`) and **one** genuine scope limit — `cast_to_ndarray`
  on the combined X/y branch (F4). No hidden corner case turned into a code bug; the
  riskiest edit (sparse indexing, F1) is covered by an existing test. Net: the audit
  **confirms** V1.
- **Benefit 1 (test redundancy).** See §10. Conditioned on running `kprove`.

## 10. Test-redundancy (recommendation only — conditioned on machine-checking)

Once the claims are machine-checked, the following become **subsumed** by the proof
*within its domain* and could be trimmed (but **keep them until `kprove` returns
`#Top`** — MVP does not run the toolchain):

- **Subsumed (in-domain points):** per-selector assertions of the *shape/identity*
  of the selected columns for ndarray/sparse input under `transform="default"` — the
  contract (TRANSFORM-DEFAULT / NONDF) proves them for all inputs.
- **KEEP — do not remove:**
  - the **mixed-dtype** preservation tests (the actual new behavior; they pin L1/L2
    and are the reason the fix exists);
  - `test_safe_indexing_2d_mask` (it *is* the discharge of PO-7);
  - out-of-domain tests: NaN handling (F3), bad-config errors (F9), empty-selection
    warnings (F6, F9), feature-name mismatch warnings (F5);
  - integration tests (Pipeline/ColumnTransformer end-to-end dtype chaining);
  - termination/performance tests.

Estimated CI saving is small and **not** worth acting on before machine-checking;
the dtype-preservation tests must be kept regardless.
