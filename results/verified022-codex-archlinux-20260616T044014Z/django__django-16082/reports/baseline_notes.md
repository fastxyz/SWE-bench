# Baseline Notes

## Root cause

`CombinedExpression` infers its `output_field` from `_connector_combinations` in
`django/db/models/expressions.py`. The same-type numeric rule included
`Combinable.MOD`, so `IntegerField % IntegerField` and
`DecimalField % DecimalField` could resolve automatically. The mixed numeric
rule only included add, subtract, multiply, and divide. As a result, modulo
between `DecimalField` and `IntegerField` had no registered result type and
raised `FieldError` instead of resolving to `DecimalField`.

## Files changed

`repo/django/db/models/expressions.py`

Added `Combinable.MOD` to the mixed numeric connector registration. This reuses
the existing mixed numeric result table, so `IntegerField % DecimalField` and
`DecimalField % IntegerField` resolve to `DecimalField`, while
`IntegerField % FloatField` and `FloatField % IntegerField` resolve to
`FloatField`, matching the behavior of the other mixed numeric arithmetic
operators already listed there.

## Assumptions and alternatives considered

I assumed the intended behavior is for modulo to follow the established mixed
numeric inference rules used by `+`, `-`, `*`, and `/`, because the issue
explicitly describes Decimal/Integer modulo and compares it with other
mathematical operators.

I considered adding only the two Decimal/Integer modulo combinations, but that
would duplicate part of the existing mixed numeric table and leave Float/Integer
modulo inconsistent with the same rationale. Adding `Combinable.MOD` to the
connector list is the smaller and more consistent change.

I did not add mixed-type `Combinable.POW` handling because the issue is specific
to modulo and the existing code intentionally excludes mixed numeric power from
that table.

Per the task constraints, I did not run tests or execute project code.
