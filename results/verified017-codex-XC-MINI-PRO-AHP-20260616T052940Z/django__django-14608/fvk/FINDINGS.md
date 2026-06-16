# Findings

Status: source-inspection and constructed-proof findings. No tests, Python, or
K tools were run.

## F1: Original formset non-form errors lacked the requested class

Input / path: `BaseFormSet.full_clean()` creates `_non_form_errors` for
`formset.non_form_errors()`.

Observed in pre-V1 code: both construction sites used `self.error_class()`
without `error_class='nonform'`, so rendered output used only the base
`errorlist` class.

Expected by public intent: the list returned by `formset.non_form_errors()`
renders with the additional `nonform` class and custom `ErrorList`
implementations can observe the distinction at construction time.

Classification: code bug, resolved by V1.

Proof obligations: PO-1 and PO-2.

## F2: Public test evidence preserves legacy no-`nonform` rendering

Input / path: admin changelist formset non-form error rendering in
`repo/tests/admin_views/tests.py::test_non_form_errors_is_errorlist`.

Observed public test expectation: `str(non_form_errors)` is compared to
`str(ErrorList(["Grace is not a Zombie"]))`, which renders without the
additional class.

Expected by public intent: the same `non_form_errors` object should render
with `errorlist nonform`.

Classification: suspect legacy public-test evidence. It encodes the behavior
the issue says is missing and must not veto the public issue intent.

Proof obligations: PO-6.

## F3: Full Python/Django semantics is beyond this FVK mini-model

Input / path: complete `BaseFormSet.full_clean()` includes form construction,
management-form validation, iteration over forms, deletion handling, and
exception paths.

Observed limitation: this FVK pass models the formset validation outcome as a
finite `Path` value instead of compiling full Django/Python semantics.

Expected for this issue: the model must still distinguish whether the
resulting `ErrorList` has the `nonform` class.

Classification: proof capability boundary, not a code bug. The abstraction is
property-complete for the CSS-class issue because it preserves the exact
observable under test: error contents plus extra class.

Proof obligations: PO-1 through PO-4.

## F4: Per-form model formset non-field assignments are outside this issue

Input / path: `repo/django/forms/models.py` directly assigns a form's
`NON_FIELD_ERRORS` in model formset uniqueness validation.

Observed: those assignments are per-form non-field errors, not
`formset.non_form_errors()`.

Expected by this issue: add `nonform` for formset-level non-form errors.

Classification: alternative interpretation considered and rejected for this
repair. No V2 source change is justified by the current issue intent.

Proof obligations: PO-3 and PO-4 frame conditions.

## Proof-derived findings from `/verify`

No additional code bug was found beyond F1. The constructed claims C1-C4 close
over the modeled outcome paths if and only if PO-1 and PO-2 hold in source.
V1 satisfies those obligations. C5 confirms the model can distinguish the
pre-fix bug from the fixed behavior, so the proof is not vacuous over the CSS
class property.
