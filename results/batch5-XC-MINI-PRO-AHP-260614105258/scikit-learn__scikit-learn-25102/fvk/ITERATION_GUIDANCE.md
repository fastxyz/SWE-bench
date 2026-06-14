# ITERATION GUIDANCE — next-pass feedback (scikit-learn #25102)

The audit's verdict: **V1's behavior is correct on its specified domain and stands;
the only V2 edit is a zero-risk docstring clarification (F4).** This file records the
residual, non-blocking items a future code-generation / intent-elicitation pass
should consider, each traced to a Finding and an obligation.

## Decision summary

| Decision | Trace | Rationale |
|---|---|---|
| **Keep V1 logic unchanged** | PO-1…PO-7 all discharged; F1 verified by existing test | Every in-scope obligation holds; the riskiest edit is test-covered. Forcing a behavioral change would be less honest than a rigorous confirmation. |
| **Clarify `cast_to_ndarray` docstring** (V2) | F4, PO-3 | V1's docstring over-promised; a pure-doc edit now scopes it to single-array validation, so spec = code. Zero behavioral risk. |
| Do **not** validate-to-ndarray on the preserve path | F3, PO-3 | Re-introducing `check_array` would undo the fix and could reject legitimate preserved dtypes (string `category`). Skipping it is the correct realization of "select on the original container." |
| Do **not** broaden `_validate_data`'s combined branch now | F4, PO-3 (scoped) | Unreachable by the feature; `_validate_data` is hot/critical; reflowing it for a hypothetical caller is unjustified risk. The docstring now documents the scope instead. |

## Open (non-blocking) items for a future pass

1. **`cast_to_ndarray` uniformity (F4).** *Partially addressed in V2* — the docstring
   was scoped to single-array validation so spec = code. Remaining open question:
   - *Classification:* latent inconsistency / underspecified intent.
   - *UltimatePowers question:* "Should `_validate_data(X, y, cast_to_ndarray=False)`
     (validating X **and** y jointly) also skip the cast, or is `cast_to_ndarray`
     intentionally X-/y-single-array only?"
   - *Recommended change if 'should skip':* wrap the `else` branch body in
     `if cast_to_ndarray:` so the invariant "False ⇒ inputs returned unchanged"
     holds in all branches; then drop the docstring scoping caveat.
   - *Recommended if 'single-array only' (the V2 assumption):* leave as is — the
     docstring now documents it.
   - *Tests:* add a unit test pinning whichever semantics is chosen; until then keep
     none (no caller exercises it).

2. **Finiteness on the preserve path (F3).**
   - *Classification:* intended-behavior, worth a documented test.
   - *UltimatePowers question:* "When a fitted selector with `allow_nan=False`
     transforms a DataFrame containing NaN under `transform='pandas'`, should it
     raise (as the legacy ndarray path did) or pass the values through?"
   - *Recommended:* keep pass-through (values are not computed on during
     `transform`); add an explicit regression test asserting *no* error so the
     behavior is pinned rather than incidental.

3. **Config-error precedence (F9).**
   - *Classification:* negligible behavior shift for doubly-invalid input.
   - *Recommended:* none, unless a maintainer wants `transform` to validate input
     before reading the output config; not worth a change.

4. **Scope beyond selectors (intent L5).**
   - *Classification:* intentionally out of scope.
   - *Note for future intent passes:* the issue also muses about column-modifying
     transformers (`StandardScaler`) and `ColumnTransformer` chaining. Those need a
     different mechanism (they *do* modify values; `astype`-back would be lossy). If
     ever requested, formalize them as a **separate** spec — do not stretch the
     SelectorMixin frame condition to cover them.

## Machine-check to run (upgrades "constructed" → "verified")

```sh
kompile mini_sklearn.k --backend haskell
kprove  mini_sklearn-spec.k          # expected: #Top
```

Running these is the precondition for acting on the (small) test-redundancy
recommendation in `PROOF.md` §10. Until then: **keep all tests**, especially the
mixed-dtype preservation tests and `test_safe_indexing_2d_mask`.

## If a future pass DOES regenerate code

Hand it this package (`SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`).
The must-hold invariants for any reimplementation:

- (PO-1/2/6) pandas + DataFrame ⇒ select original columns verbatim (dtype + values).
- (PO-4/5) default output or non-DataFrame input ⇒ legacy homogeneous-ndarray result.
- (PO-7) keep using `_safe_indexing(..., axis=1)` (or prove any replacement
  equivalent for sparse via `test_safe_indexing_2d_mask`).
- (PO-9) preserve the empty-mask warning and the shape-mismatch `ValueError`, in that
  order.
- Confine the change to `SelectorMixin` (L5); do not touch column-modifying
  transformers.
