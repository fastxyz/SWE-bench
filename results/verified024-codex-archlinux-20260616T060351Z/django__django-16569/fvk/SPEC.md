# FVK Specification

Status: constructed, not machine-checked. This audit did not run tests,
Python, `kompile`, or `kprove`.

## Audited unit

`repo/django/forms/formsets.py`:

- `BaseFormSet.empty_form`
- `BaseFormSet.add_fields(form, index)`, limited to deletion-field insertion

The formal model abstracts the rest of Django's form machinery to:

- `can_delete`
- `can_delete_extra`
- `index`, represented as either `noneIndex()` or `someIndex(i)`
- `initial_form_count`
- the observable field-set mutation for `DELETE`
- an exception cell used to prove the empty-form path does not raise the
  reported `TypeError`

There are no loops in the audited code path.

## Human-readable contract

For any formset state with `initial_form_count = N >= 0` and an in-domain
`index` (`None` for the empty template form or a nonnegative integer form
index), `add_fields()` must add `DELETE` exactly when:

```text
can_delete and (
    can_delete_extra or (index is not None and index < initial_form_count)
)
```

Consequences:

- `can_delete=False`: no `DELETE`.
- `can_delete=True`, `can_delete_extra=True`: `DELETE` for initial, extra, and
  empty template forms.
- `can_delete=True`, `can_delete_extra=False`, `index=None`: no `DELETE` and no
  exception.
- `can_delete=True`, `can_delete_extra=False`, `0 <= index < N`: add `DELETE`.
- `can_delete=True`, `can_delete_extra=False`, `index >= N`: no `DELETE`.

Frame conditions:

- `add_fields(form, index)` keeps the same public signature and dispatch shape.
- The existing ordering-field logic is unchanged.
- Non-delete fields already present on the form are outside the deletion
  projection and are not modeled as modified by the V1 patch.

## Public intent ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2: the prompt identifies `index=None` plus disabled extra deletion as
  the failing path and requires avoiding the `None < int` comparison.
- E3: Django docs expose `empty_form` as a public dynamic-form API.
- E4: Django docs state `can_delete_extra=False` removes deletion from extra
  forms.
- E5: public tests encode initial-vs-extra indexed behavior for
  `can_delete_extra=False`.
- E6: source comments document `index=None` for the empty form.
- E7: the ordering branch already guards `index is not None`.
- E8: model formsets delegate to the base method.

## Formal artifacts

- `fvk/mini-python-formset.k`: minimal K fragment for the delete-field
  projection.
- `fvk/formset-add-fields-spec.k`: K reachability claims for all delete-field
  cases in the contract.
- `fvk/INTENT_SPEC.md`: intent-only English specification.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of the K claims.
- `fvk/SPEC_AUDIT.md`: adequacy comparison from formal claims to intent.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: API/callsite/override compatibility.

## Exact machine-check commands

These commands are recorded for a future environment with K installed. Run them
from `fvk/`. They were not executed in this session.

```sh
kompile mini-python-formset.k --main-module MINI-PYTHON-FORMSET --syntax-module MINI-PYTHON-FORMSET-SYNTAX --backend haskell
kast --backend haskell formset-add-fields-spec.k
kprove formset-add-fields-spec.k --spec-module FORMSET-ADD-FIELDS-SPEC
```
