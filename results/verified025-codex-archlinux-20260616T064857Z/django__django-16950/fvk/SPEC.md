# FVK Specification

Status: constructed, not machine-checked.

## Scope

The audited production code is `repo/django/forms/models.py`, specifically:

- `BaseInlineFormSet.add_fields()`
- `InlineForeignKeyField.__init__()`
- The neighboring `BaseInlineFormSet._construct_form()` and
  `InlineForeignKeyField.clean()` behavior needed to show the parent value is
  both preserved and still used for inline validation/linking.

There are no loops in the changed code path. The formal model uses transition
claims for the relevant branches instead of loop circularities.

## Intent Spec

1. When an unsaved parent model has a non-primary unique UUID field with a
   Python default and an inline child uses `ForeignKey(..., to_field=<that
   field>)`, constructing or validating the inline formset must not set that
   parent field to `None`.
2. The inline form field for a default-generated unsaved relation target should
   still render with an empty hidden initial value, matching the existing UUID
   primary-key behavior and avoiding stale generated values in POST data.
3. Existing behavior for defaulted primary-key relations must be preserved:
   defaulted unsaved primary keys are ignored in inline hidden form data because
   they can be regenerated on save.
4. Existing `InlineForeignKeyField` behavior must be preserved for callers that
   don't supply an explicit `initial`: derive initial from `to_field` when set,
   otherwise from `parent_instance.pk`.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Django Admin with Inlines not using UUIDField default value" | Admin inline creation must preserve a defaulted UUID alternate key needed for the parent save. | Encoded in PO-001. |
| E2 | `benchmark/PROBLEM.md` | "`new_object.id` ... before `all_valid(formsets)` ... after ... `None`" | Inline form construction/validation must not mutate non-PK `to_field` values to `None`. | Encoded in PO-001. |
| E3 | `benchmark/PROBLEM.md` public hint | "need to stop set id value None when that field is not model's pk as UUIDField" | Distinguish primary-key targets from non-primary `to_field` targets. | Encoded in PO-001 and PO-003. |
| E4 | `repo/tests/model_formsets/test_uuid.py` | `test_inlineformset_factory_nulls_default_pks_alternate_key_relation` asserts the inline field initial is `None`. | A fix must preserve empty hidden initial values for defaulted alternate-key relations. | Encoded in PO-002. |
| E5 | `repo/tests/model_formsets/test_uuid.py` | UUID primary-key tests assert defaulted parent PK initial is `None`. | Existing defaulted PK behavior must not regress. | Encoded in PO-003. |
| E6 | `repo/django/forms/models.py` comments | "The pk will be regenerated on the save request" | The original mutation is justified only for primary-key fields. | Encoded in PO-003. |

## Formal Model

The K artifacts are:

- `fvk/mini-inline-formset.k`
- `fvk/inline-formset-spec.k`

The model abstracts only the property-relevant state:

- whether the parent instance is adding;
- whether the relation target is the parent primary key or an alternate
  `to_field`;
- whether that target has a Python default;
- the parent target value after `add_fields()`;
- the inline hidden field initial value;
- whether the parent target was mutated.

This abstraction distinguishes the failing pre-fix behavior from the fixed
behavior: a defaulted alternate-key relation maps to
`(parentTarget=noneValue, parentMutated=true)` in the buggy behavior but to
`(parentTarget=someValue, fieldInitial=noneValue, parentMutated=false)` in V1.

## Formal Spec English

1. For an adding parent and a defaulted alternate `to_field`, `add_fields()`
   terminates with the parent target value preserved, the inline initial empty,
   and no parent mutation.
2. For an adding parent and a defaulted primary-key target, `add_fields()`
   terminates with the parent target cleared, the inline initial empty, and the
   parent marked mutated, preserving legacy behavior.
3. When `InlineForeignKeyField` is constructed with an explicit initial value,
   that explicit value is used.
4. When `InlineForeignKeyField` is constructed without an explicit initial
   value, it derives the value from the parent.

## Adequacy Audit

| Formal claim | Intent coverage | Result |
| --- | --- | --- |
| Defaulted alternate `to_field` preserves parent value and uses empty initial. | Matches E1-E4 exactly: the bug is parent mutation, while public tests require empty initial. | Pass |
| Defaulted primary-key target is still cleared. | Matches E5-E6 and preserves existing documented behavior. | Pass |
| Explicit initial override is honored. | Required to satisfy empty initial without mutating a non-PK parent value. | Pass |
| No-explicit-initial behavior derives from parent. | Required compatibility with existing callers and unchanged code paths. | Pass |

## Public Compatibility Audit

No public function or method signature changed. `InlineForeignKeyField.__init__()`
already accepted arbitrary field kwargs through `**kwargs`; V1 only stops
overwriting an explicitly supplied `initial`. Public construction paths that do
not supply `initial` still derive the same initial value as before.

The changed callsite is internal: `BaseInlineFormSet.add_fields()` supplies
`initial=None` only for the defaulted non-PK `to_field` case.
