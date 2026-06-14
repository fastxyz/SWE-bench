# FVK audit notes — scikit-learn #25102 (V1 → V2)

## Outcome in one line

The FVK audit **confirms the V1 fix's behavior and leaves the logic unchanged**, with
a **single zero-risk edit**: a docstring clarification (Finding F4) so the spec
matches the code. Every in-scope proof obligation (PO-1…PO-7) is discharged, the
single riskiest edit is shown correct by an *existing* test, and the only spec
limitation surfaced (F4) is out-of-domain for the feature.

This is the allowed "stand unchanged or be minimally refactored… justified by the FVK
artifacts" outcome. The justification follows, decision by decision.

---

## 1. Why the logic stands (and the one doc edit) — decision ledger

Each row is a place I asked "should V1 change here?" and the evidence that answered.

| Candidate change | Verdict | Traced to |
|---|---|---|
| Revert `_safe_indexing` → keep `X[:, safe_mask(X, mask)]` for sparse safety | **Not needed** | **F1 / PO-7**: existing test `test_safe_indexing_2d_mask` already asserts `_safe_indexing(sparse, bool, axis=1)` gives the correct subset; dense is literally identical. The riskiest line is test-covered. |
| Validate-to-ndarray on the preserve path to keep finiteness checks | **Rejected** | **F3 / PO-3**: it would re-homogenize (undo the fix) and could *reject* valid preserved dtypes (string `category` → object array → finiteness error). Skipping `check_array` is the correct realization of L3. |
| Guard the combined X/y branch of `_validate_data` for `cast_to_ndarray` | **Rejected (this pass)** | **F4 / PO-3**: unreachable by the feature (transform calls X-only); `_validate_data` is hot/critical; reflowing it for a hypothetical caller is unjustified risk. Scoped PO-3 instead, like the kit's `n ≥ 0`. |
| Clarify the `cast_to_ndarray` docstring (resolve the V1 over-promise) | **Done (V2)** | **F4 / PO-3**: V1's docstring said "`X` and `y` are unchanged" but the combined branch always casts. A pure-doc, behavior-free edit now scopes it ("only honored when validating `X` or `y` on its own"), so the human-readable spec matches the code. |
| Change empty-selection handling | **Not needed** | **F6 / PO-9**: `X.iloc[:, :0]` yields the correct empty DataFrame; guard ordering matches V0. |
| Harden `_is_pandas_df` | **Not needed** | **F7**: robust against Series, polars, look-alikes, and lazy pandas import. |
| Re-order config read vs. validation in `transform` | **Rejected** | **F9**: only affects doubly-invalid input; both raise `ValueError`; existing message-match tests still pass. Negligible. |

So the audit's value here is **confirmation plus a documented evidence package**, with
one tiny doc-only correction — not a behavioral patch. The most important single
result is F1/PO-7: the one change in V1 that could have silently broken a large,
well-used code path (sparse feature selection) is proven equivalent by a test that
already ships in the repo.

## 2. How the spec was built (intent-first)

Per `formalize.md`, I built a **public intent ledger** (`SPEC.md` §1) from
`benchmark/PROBLEM.md` only — no upstream-fix knowledge. The decisive intent signals
were the framing words: *"preserve"*, *"do not modify the input values"* (frame
condition L1), *"category"/"np.float16"* must survive (L2), *"select the columns on
the original container before the conversion"* (the chosen mechanism, L3), and the
maintainer's explicit scoping to *"transformers which export… a subset of the
inputted features"* (L5) with **no** preservation expected on the homogeneous/legacy
path (L4). These mapped directly onto the obligations PO-1…PO-6.

The property is a **frame condition** (preserve dtype + values of surviving
columns), not an arithmetic closed form, so the mini-X semantics
(`fvk/mini_sklearn.k`) abstracts containers to `df(Cols)` (per-column dtype) vs
`arr(Dtype, Cols)` (one shared dtype = the modeled dtype *loss*), and abstracts the
selection to `selectCols`, which copies surviving columns **verbatim**. That single
modeling choice is what makes "dtype preserved" provable as `selectCols` keeping
`col(Name, Dtype, Vals)` nodes intact.

## 3. The proof and what it certifies

`fvk/PROOF.md` constructs (symbolic execution, not machine-run):

- **(SELECT-FRAME)** — the list-recursion circularity: selection keeps survivors
  verbatim ⇒ **PO-2** (values) and the core of **PO-1** (dtype).
- **(DTYPE-FRAME)** — dtypes distribute over selection ⇒ **PO-1** in full: a
  `category`/`float16` column stays itself.
- **(TRANSFORM-PRESERVE / DEFAULT / NONDF)** — the three-way case on
  `(isDf(X), config)` gives the whole contract: preserve only on pandas+DataFrame
  (**PO-1/2/6**); legacy homogeneous result otherwise (**PO-4/5**), i.e. **exact
  backward compatibility** off the new path.

No VC needed the arithmetic tier; the only inductions are the two guarded list
recursions. No proof obstacle became a code bug (Benefit 2). The proof **could not**
state a *universal* `_validate_data` pass-through over the combined X/y branch — that
non-closure is exactly **F4**, handled by scoping the obligation, not by weakening
the claim (the honest move the kit prescribes).

## 4. Adversarial cross-checks performed (Benefit 2 discipline)

Beyond the formal claims I ran the "be adversarial" checks the kit recommends, all
recorded in `FINDINGS.md`: column-order vs `get_feature_names_out` (F5), the existing
common check `check_set_output_transform_pandas` still passing (all-`float64` input ⇒
preservation is a no-op there, F5), copy-vs-view aliasing of `df.loc[:, mask]` (F8),
`_is_pandas_df` corner cases (F7), the empty/shape guards (F6/PO-9), value identity
between the numpy and DataFrame selection paths (F2), and NotFitted/error ordering
(F3/F9). None produced a correctness defect.

## 5. Residual risk (honest status)

- **Constructed, not machine-checked.** The `kompile`/`kprove` commands are in
  `PROOF.md` §8 / `ITERATION_GUIDANCE.md`; no execution environment exists here.
- **Trusted base:** adequacy of the mini-X abstraction (values and `check_array`
  arithmetic are abstracted; only dtype/column-survival are modeled), and the
  reasoned-but-unmodeled pieces — `_wrap_in_pandas_container` relabeling (F5/PO-8),
  warnings/exceptions (F6/F9/PO-9), sparse indexing equivalence (delegated to the
  existing test, F1/PO-7).
- **Partial correctness:** termination is argued informally (finite recursion,
  PO-10), not via a formal variant.
- **Scope:** the contract is for `SelectorMixin` only (L5); column-modifying
  transformers are deliberately not covered and would need a separate spec
  (`ITERATION_GUIDANCE.md` item 4).

## 6. Artifacts produced

```
fvk/mini_sklearn.k          mini-X fragment semantics
fvk/mini_sklearn-spec.k     reachability claims + the selection circularity
fvk/SPEC.md                 intent ledger + human-readable contracts
fvk/FINDINGS.md             F1–F9 (input → observed vs expected)
fvk/PROOF_OBLIGATIONS.md    PO-1…PO-10 with status and domain scoping
fvk/PROOF.md                constructed proof + kompile/kprove commands + test redundancy
fvk/ITERATION_GUIDANCE.md   non-blocking next-pass items
reports/fvk_notes.md        this file
```

The only `repo/` edit in V2 is the behavior-free `cast_to_ndarray` docstring
clarification in `sklearn/base.py` (F4); all V1 logic stands. No test files were
touched.
