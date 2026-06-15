# FVK Specification

Status: constructed, not machine-checked.

## Audited Unit

The audited unit is the defaulting branch inside:

`repo/django/db/models/fields/related.py::ForeignKey.formfield()`

The observable under verification is whether the generated
`ModelChoiceField.empty_label` is `None` or present. That observable is
property-complete for this bug because `ModelChoiceIterator.__iter__()` yields
the blank `("", empty_label)` choice if and only if `empty_label is not None`.

## Public Intent Ledger

The detailed ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical entries
are:

- E1: non-blank foreign keys rendered with `RadioSelect` must not present a
  blank option.
- E2: normal select widgets must keep the blank-option convention.
- E4-E6: `empty_label=None` is the mechanism that removes the blank choice and
  prevents a new form's empty value from checking an empty radio input.
- E8: the effective widget may come from a custom form field class default, not
  only from an explicit `widget` kwarg.
- E9: explicit `empty_label` keyword arguments are caller overrides.

## Contract

For all in-domain calls to `ForeignKey.formfield()`:

1. If `self.blank` is false, `empty_label` is absent from `kwargs`, and the
   effective widget is a `forms.RadioSelect` class, instance, or subclass, the
   method must pass `empty_label=None` to `ModelChoiceField`.
2. The effective widget is the explicit `kwargs['widget']` if supplied; otherwise
   it is the chosen form field class's default `widget`.
3. If `self.blank` is true, Django may keep its normal empty label.
4. If the effective widget is not radio, Django must keep its normal empty label.
5. If `empty_label` is explicitly supplied, the method must preserve it.
6. Queryset, `to_field_name`, public method signature, and unrelated keyword
   behavior are framed and must remain unchanged.

## Formal Core

The formal core is:

- `fvk/mini-django-formfield.k`
- `fvk/foreignkey-formfield-spec.k`

The model abstracts widget identity to `radio`, `select`, or `other`, and
abstracts the `empty_label` result to `emptyNone`, `emptyDefault`, or
`emptyExplicit`. This abstraction distinguishes the passing and failing cases:

- failing legacy case: non-blank + effective radio + no explicit `empty_label`
  maps to `emptyDefault`, which renders a blank choice;
- passing V2 case: the same input maps to `emptyNone`, which renders no blank
  choice.

No loops or recursive functions occur in the audited branch, so there are no
loop circularities.
