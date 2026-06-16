# Public Evidence Ledger

Status: public evidence only. Current implementation behavior is listed only as
implementation evidence, not as expected behavior by itself.

## E1 - Prompt: reported failing state

- Source: `benchmark/PROBLEM.md`.
- Evidence: formsets fail when `can_delete=True`, `can_delete_extra=False`, and
  `add_fields()` receives `index=None`.
- Obligation: the empty-form path is in scope and must not raise `TypeError`.
- Status: encoded by I1, I2, PO1, and PO2.

## E2 - Prompt: requested guard shape

- Source: `benchmark/PROBLEM.md`.
- Evidence: the issue proposes checking `index is not None` before comparing it
  with `initial_form_count`.
- Obligation: do not compare `None` with an integer initial-form count.
- Status: encoded by PO2 and K claim `EMPTY-FORM-NO-DELETE`.

## E3 - Django docs: empty form is public API

- Source: `repo/docs/topics/forms/formsets.txt`.
- Evidence: `empty_form` returns a form instance with `__prefix__`.
- Obligation: constructing the empty template form must be total for ordinary
  formset configurations.
- Status: encoded by I1 and PO2.

## E4 - Django docs: `can_delete_extra`

- Source: `repo/docs/topics/forms/formsets.txt`.
- Evidence: `can_delete_extra=False` removes deletion from extra forms.
- Obligation: when extra deletion is disabled, non-initial forms and the empty
  template form do not receive `DELETE`.
- Status: encoded by I3, PO3c, and PO3e.

## E5 - Django tests: indexed form behavior

- Source: `repo/tests/forms_tests/tests/test_formsets.py`.
- Evidence: tests assert initial forms keep `DELETE` and extra forms do not when
  `can_delete_extra=False`.
- Obligation: preserve indexed initial/extra behavior while fixing `None`.
- Status: encoded by PO3d, PO3e, and PO4.

## E6 - Source comment: `index=None` convention

- Source: `repo/django/forms/formsets.py`.
- Evidence: `get_form_kwargs()` documents that `index` is `None` for the empty
  form.
- Obligation: `None` is a valid hook value and cannot be rejected or replaced
  with a synthetic numeric index.
- Status: encoded by I2 and PO5.

## E7 - Source implementation: ordering branch pattern

- Source: `repo/django/forms/formsets.py`.
- Evidence: ordering prefill already checks `index is not None` before
  comparing with `initial_form_count`.
- Obligation: the delete branch should use the same `None` discipline for
  comparisons, without changing ordering behavior.
- Status: encoded by PO2 and PO4.

## E8 - Source implementation: model formset delegation

- Source: `repo/django/forms/models.py`.
- Evidence: model and inline formsets call `super().add_fields(form, index)`.
- Obligation: the base fix covers delegated model formset behavior without a
  signature or dispatch change.
- Status: encoded by PO5.
