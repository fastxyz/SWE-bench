# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not justify any additional source edit.

## Trace to findings and proof obligations

### Keep the V1 source condition

The V1 condition is:

```python
if self.can_delete and (
    self.can_delete_extra or (index is not None and index < initial_form_count)
):
```

This is retained because `fvk/FINDINGS.md` F1 identifies the original failing
state and marks it discharged by PO1, PO2, and PO3c in
`fvk/PROOF_OBLIGATIONS.md`. Those obligations require that `index=None` on
`empty_form` avoids the numeric comparison, raises no `TypeError`, and does
not add `DELETE` when `can_delete_extra=False`.

### Preserve indexed form behavior

No broader rewrite was made because `fvk/FINDINGS.md` F2 confirms the existing
indexed behavior remains the intended one: initial forms get `DELETE`, extra
forms do not when `can_delete_extra=False`. This traces to PO3d, PO3e, and PO4,
which cover initial indexes, extra indexes, and frame conditions.

### Preserve public API and subclass compatibility

No signature or call-shape change was made because `fvk/FINDINGS.md` F3 and
PO5 show the public compatibility audit passes. `empty_form` still calls
`add_fields(form, None)`, normal form construction still calls
`add_fields(form, i)`, and model/inline formsets continue to delegate through
`super().add_fields(form, index)`.

### Do not expand scope to nonstandard manual indexes

No guard was added for negative integers or arbitrary non-integer objects
because `fvk/FINDINGS.md` F4 classifies those cases as outside the audited
public domain. PO1 states the domain used for this repair: `None` for the empty
template form or a nonnegative integer form index.

## Artifacts produced

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The additional FVK adequacy and formal-core artifacts are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-formset.k`
- `fvk/formset-add-fields-spec.k`

The proof is constructed, not machine-checked. The recorded `kompile`,
`kast`, and `kprove` commands were written into the artifacts but not executed.
