# FVK Notes

## Decisions From The Audit

### V2 Source Change

I changed `repo/django/forms/models.py` after the FVK audit found
`fvk/FINDINGS.md` F1. V1 had a separate `base_formfield_callback` fallback in
`ModelFormMetaclass.__new__()`. That fallback made `formfield_callback` inherit
from a base form even when a subclass supplied a replacement `Meta` class that
did not define or inherit the option.

That behavior violated `fvk/PROOF_OBLIGATIONS.md` PO6:
`REPLACED-META-DOES-NOT-LEAK-BASE`. The public evidence is Django's ModelForm
inheritance docs, recorded as `fvk/SPEC.md` E4: normal Python name resolution
uses the child's `Meta` if it exists, otherwise the first parent's `Meta`.

The V2 edit removes the special base fallback. The metaclass now resolves the
callback from an explicit top-level class attribute if present; otherwise it
uses `opts.formfield_callback` from the already resolved `Meta` object. This
keeps callback resolution consistent with other `ModelFormOptions`.

### V1 Behavior Kept

I kept the V1 change that stores `formfield_callback` on `ModelFormOptions` and
passes `opts.formfield_callback` to `fields_for_model()`. This is justified by
F3 and PO2: direct `Meta.formfield_callback` declarations must affect field
generation.

I kept the V1 factory change that avoids adding a top-level
`formfield_callback` attribute when the factory argument is `None`. This is
justified by F2 and PO1: omitted factory callbacks must preserve a callback
available through the base form's `Meta`.

I kept the V1 `is not None` checks in `modelform_factory()`. This is justified
by F4 and PO5: a falsey but non-`None` callable is still an explicit callback
argument and should be preserved.

I kept the explicit top-level callback override path. This is justified by PO3
and PO4: existing public behavior expects explicit factory callbacks to win,
and invalid explicit callbacks must still reach `fields_for_model()` validation.

## Formalization Decisions

The K model is intentionally narrow. It models callback selection as the
observable identity of the callback object passed to field generation. That
choice is justified in `fvk/SPEC.md` because the reported bug is exactly that
the wrong callback, `None`, reached field generation.

The model does not attempt to prove all Python metaclass behavior or all Django
form generation. That residual risk is recorded in `fvk/FINDINGS.md` F5 and
`fvk/PROOF.md`.

## Execution Constraint

No tests, Python code, or K tooling were run. The proof is constructed, not
machine-checked. The emitted commands in `fvk/PROOF.md` should be run only in an
environment where K execution is allowed.
