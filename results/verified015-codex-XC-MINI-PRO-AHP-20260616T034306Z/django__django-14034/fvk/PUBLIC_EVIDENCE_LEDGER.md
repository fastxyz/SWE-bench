# Public Evidence Ledger

## E1: Issue Reproduction

- Source: `benchmark/PROBLEM.md`
- Evidence: a `MultiValueField` with `require_all_fields=False` and subfields
  `[CharField(required=False), CharField(required=True)]`.
- Obligation: the model must distinguish optional and required subfields inside
  one `MultiValueField`.
- Status: encoded in `SPEC.md`, `multivalue-required-spec.k`, PO-1, and PO-3.

## E2: HTML Symptom

- Source: `benchmark/PROBLEM.md`
- Evidence: removing `required=False` from the parent makes both HTML inputs
  render `required`.
- Obligation: the rendered child `required` attributes must not be copied
  uniformly from the parent in the partial-required case.
- Status: encoded in PO-3 and finding F1.

## E3: Two-Level Required Semantics

- Source: `benchmark/PROBLEM.md`
- Evidence: the discussion says parent `required` answers whether the composite
  can be skipped, and individual fields should respect their own `required`
  attributes.
- Obligation: parent and child required state must be represented separately.
- Status: encoded in PO-1 and PO-2.

## E4: Validation Frame

- Source: `benchmark/PROBLEM.md` and visible validation tests at
  `repo/tests/forms_tests/tests/test_forms.py:3060`.
- Evidence: optional `MultiValueField` values do not raise a parent `required`
  error when all fields are empty; required partial values raise `incomplete`
  for empty required subfields.
- Obligation: do not change `MultiValueField.clean()`.
- Status: encoded in PO-6 and finding F2.

## E5: Django Docs

- Source: `repo/docs/ref/forms/fields.txt:1092`.
- Evidence: `require_all_fields=False` allows individual fields to be optional.
- Obligation: field-level `required` must remain meaningful in partial
  `MultiValueField` configurations.
- Status: encoded in PO-2 and PO-3.

## E6: Existing Required-All Rendering Frame

- Source: `repo/tests/forms_tests/field_tests/test_multivaluefield.py:125`.
- Evidence: a required `ComplexField` with default `require_all_fields=True`
  renders all subwidgets with `required`.
- Obligation: the V1 fix must not remove this legacy required-all behavior.
- Status: encoded in PO-4.

## E7: Current Root Cause

- Source: `repo/django/forms/boundfield.py:232`,
  `repo/django/forms/widgets.py:821`, and V1 diff.
- Evidence: `BoundField.build_widget_attrs()` adds parent `required=True`;
  `MultiWidget.get_context()` copies parent attrs to each child.
- Obligation: the repair must intercept child attr construction, not validation.
- Status: encoded in PO-3.

