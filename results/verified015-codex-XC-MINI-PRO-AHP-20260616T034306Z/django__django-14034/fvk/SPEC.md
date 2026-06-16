# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The verified unit is the render-time required-attribute path affected by V1:

- `MultiValueField.__init__()` in `repo/django/forms/fields.py:988`;
- `MultiWidget.get_context()` in `repo/django/forms/widgets.py:821`;
- the parent required attr source in `BoundField.build_widget_attrs()` at
  `repo/django/forms/boundfield.py:232`.

The spec intentionally excludes `MultiValueField.clean()` except as a frame
condition because the public issue discussion narrows the accepted fix to HTML
rendering.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | Mixed subfields: first optional, second required | Preserve per-subfield required distinctions | Encoded in C1/C2 |
| E2 | `benchmark/PROBLEM.md` | Removing parent `required=False` makes both inputs render `required` | Do not copy parent required uniformly in partial-required mode | Encoded in C2 |
| E3 | `benchmark/PROBLEM.md` | Parent required means whether the composite can be skipped; children respect own required | Represent parent and child required state separately | Encoded in C1 |
| E4 | issue discussion, public tests | Optional parent all-empty values remain valid | Leave validation unchanged | Encoded as frame PO-6 |
| E5 | docs at `repo/docs/ref/forms/fields.txt:1092` | `require_all_fields=False` lets individual fields be optional | Child field `required` must affect behavior | Encoded in C1/C2 |
| E6 | visible test at `repo/tests/forms_tests/field_tests/test_multivaluefield.py:125` | default required-all field renders all required | Preserve `require_all_fields=True` rendering | Encoded in C3 |
| E7 | source root cause | parent attrs were copied to all children | Adjust child attr construction | Encoded in C2 |

## Domain

The main domain is a `MultiValueField` with a `MultiWidget` and corresponding
finite subfield/subwidget positions. The formal abstraction assumes paired
positions; mismatched field/widget lengths are outside this issue's intent and
remain governed by existing `zip()` behavior.

The rendered child `required` value is specified only for the path where the
form-level `use_required_attribute` and parent widget
`use_required_attribute()` have already allowed a parent `required` attr. This
matches Django's existing `BoundField.build_widget_attrs()` gate.

## Formal Claims

C1. `setWidgetRequired(parent_required, require_all_fields, fields_required)`
models V1's `MultiValueField.__init__()` child-widget propagation.

C2. `renderRequired(false, true, uses_required_attr, child_required)` models
V1's `MultiWidget.get_context()` partial-required branch. It must produce
`zipAnd(uses_required_attr, child_required)`.

C3. `renderRequired(true, true, ..., child_required)` models the preserved
required-all branch. It must produce `repeatLike(true, child_required)`.

C4. `renderRequired(false, false, ..., child_required)` models an optional
parent render path. It must produce `repeatLike(false, child_required)`.

The machine-oriented claims are in `fvk/multivalue-required-spec.k`; the
supporting abstraction is in `fvk/mini-django-forms.k`.

## Adequacy Summary

The formal claims distinguish a passing and failing instance of the reported
property:

- failing legacy abstraction: parent required attr copied uniformly gives
  `[true, true]` for fields `[false, true]`;
- V1 abstraction: partial-required branch gives `[false, true]`.

This preserves the exact property axis under verification: rendered child HTML
`required` attributes.

