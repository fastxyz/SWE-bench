# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims proved

The K claims in `fvk/formset-add-fields-spec.k` prove the deletion-field
projection of `BaseFormSet.add_fields()`:

```text
DELETE is added iff
can_delete and (
    can_delete_extra or (index is not None and index < initial_form_count)
)
```

The proof domain is `initial_form_count >= 0` and `index` is either `None` or a
nonnegative integer form index.

## Symbolic proof sketch

The semantics in `fvk/mini-python-formset.k` reduces
`addFieldsDelete(CD, CDE, IDX, N)` by first evaluating the total helper
`shouldAddDelete(CD, CDE, IDX, N)`.

Case 1: `CD = false`.

- `shouldAddDelete(false, _, _, _) => false`.
- The no-add rewrite applies.
- The fields set is unchanged and the exception cell is `noException`.
- Discharges PO3a.

Case 2: `CD = true`, `CDE = true`.

- `shouldAddDelete(true, true, _, _) => true`.
- The add rewrite inserts `deleteField()`.
- No comparison with `IDX` occurs, so `noneIndex()` is safe.
- Discharges PO3b.

Case 3: `CD = true`, `CDE = false`, `IDX = noneIndex()`.

- `shouldAddDelete(true, false, noneIndex(), _) => false`.
- The no-add rewrite applies.
- The semantics contains no rule comparing `noneIndex()` with `N`, so the
  exception cell remains `noException`.
- Discharges PO2 and PO3c, and directly resolves F1.

Case 4: `CD = true`, `CDE = false`, `IDX = someIndex(I)`, `0 <= I < N`.

- `shouldAddDelete(true, false, someIndex(I), N) => I <Int N`.
- Under the path condition, the helper is true.
- The add rewrite inserts `deleteField()`.
- Discharges PO3d and the initial-form part of F2.

Case 5: `CD = true`, `CDE = false`, `IDX = someIndex(I)`, `I >= N`.

- `shouldAddDelete(true, false, someIndex(I), N) => I <Int N`.
- Under the path condition, the helper is false.
- The no-add rewrite applies.
- Discharges PO3e and the extra-form part of F2.

There are no loops or recursive calls in the modeled operation, so no
circularity is needed.

## Adequacy gate

`FORMAL_SPEC_ENGLISH.md` paraphrases all formal claims. `SPEC_AUDIT.md` marks
each claim as passing against `INTENT_SPEC.md`. No claim preserves the reported
legacy `TypeError`, and no claim is justified solely by V1 behavior.

`PUBLIC_COMPATIBILITY_AUDIT.md` finds no public signature, dispatch, or
override incompatibility. This discharges PO5 and supports F3.

## Test-redundancy recommendation

No test files were modified. If the K artifacts are machine-checked later and
`kprove` returns `#Top`, unit tests that assert only the in-domain truth table
for `DELETE` insertion would be subsumed by the proof. Integration, rendering,
subclass override, and out-of-domain behavior tests should remain.

A regression test for the reported path would still be valuable until
machine-checking is available: `can_delete=True`, `can_delete_extra=False`,
and `formset.empty_form` should not raise and should not include `DELETE`.

## Residual risk

The proof is only constructed. Confidence is limited by the adequacy of the
mini semantics, the unexecuted K toolchain, and the chosen audit scope. The
Findings report does not identify a source-level gap requiring a V2 edit.

## Reproduce the machine check later

Run from `fvk/`:

```sh
kompile mini-python-formset.k --main-module MINI-PYTHON-FORMSET --syntax-module MINI-PYTHON-FORMSET-SYNTAX --backend haskell
kast --backend haskell formset-add-fields-spec.k
kprove formset-add-fields-spec.k --spec-module FORMSET-ADD-FIELDS-SPEC
```
