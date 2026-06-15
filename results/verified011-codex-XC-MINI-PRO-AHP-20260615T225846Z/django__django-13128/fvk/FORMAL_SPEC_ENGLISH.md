# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases each nontrivial K claim in
`fvk/temporal-subtraction-spec.k`.

## Claims

`DATE-SUB`

If a combined expression subtracts a `DateField` expression from another
`DateField` expression, its inferred output field is `DurationField`.

`DATETIME-SUB`

If a combined expression subtracts a `DateTimeField` expression from another
`DateTimeField` expression, its inferred output field is `DurationField`.

`TIME-SUB`

If a combined expression subtracts a `TimeField` expression from another
`TimeField` expression, its inferred output field is `DurationField`.

`ISSUE-NESTED-DATETIME-DURATION`

The issue expression's inner datetime subtraction resolves to `DurationField`,
so adding it to a `DurationField` value resolves as `DurationField`.

`GENERIC-SAME-DURATION`

A non-special expression combining two `DurationField` operands resolves to
`DurationField` through the existing generic same-type rule.

`GENERIC-MIXED-DATETIME-DURATION`

A direct non-special expression combining `DateTimeField` and `DurationField`
still resolves to `FieldError`; V1 does not broaden unrelated mixed arithmetic.

`GENERIC-SAME-INTEGER`

A non-special expression combining two matching non-temporal fields delegates to
generic inference and resolves to that same field type.

`SQL-TEMPORAL-SUBTRACTION`

The SQL rendering discriminator for `DateTimeField - DateTimeField` remains the
temporal-subtraction branch.

`SQL-TEMPORAL-SUBTRACTION-OUTPUT`

The temporal-subtraction SQL branch is associated with `DurationField` output.

## Side Conditions

The model assumes operands have already been query-resolved so their internal
field type is known or explicitly absent. This matches the audited point in
Django's expression lifecycle.
