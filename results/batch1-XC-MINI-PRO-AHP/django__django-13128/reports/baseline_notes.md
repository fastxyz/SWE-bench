# Baseline notes — django__django-13128

## Issue

Temporal subtraction (subtracting two date/time/datetime fields) requires an
explicit `ExpressionWrapper(..., output_field=DurationField())`. Without it, an
expression such as

```python
Experiment.objects.annotate(
    delta=F('end') - F('start') + Value(datetime.timedelta(), output_field=DurationField())
)
```

raises

```
django.core.exceptions.FieldError: Expression contains mixed types: DateTimeField, DurationField. You must set output_field.
```

The goal is to make temporal subtraction infer a `DurationField` output type on
its own, so no wrapper is needed.

## Root cause

`F('end') - F('start')` produces a `CombinedExpression(connector=SUB)`. SQL
generation already understands temporal subtraction:
`CombinedExpression.as_sql()` (django/db/models/expressions.py) detects
`connector == SUB` with two same-typed temporal operands and delegates to
`TemporalSubtraction`, which emits the correct duration-producing SQL and carries
`output_field = DurationField()`.

The problem is purely in **output-field inference**, which is a separate code
path from `as_sql()`. `CombinedExpression` had no `_resolve_output_field()` of its
own, so it fell back to `BaseExpression._resolve_output_field()`. That method just
checks that all source fields share a type and returns that type. For
`DateTimeField - DateTimeField` it therefore infers `DateTimeField` — which is
semantically wrong (the difference of two datetimes is a duration, not a
datetime).

That wrong inference becomes visible the moment the subtraction is combined with
anything else: in the issue example the outer `+ Value(..., DurationField())` sees
one operand inferred as `DateTimeField` (the subtraction) and one as
`DurationField` (the value), concludes the types are mixed, and raises
`FieldError`. In short, `as_sql()` knew the result was a duration but
`_resolve_output_field()` did not.

## Change

**File:** `repo/django/db/models/expressions.py`

Added a `_resolve_output_field()` override on `CombinedExpression` that mirrors the
temporal-subtraction detection already used in `as_sql()`:

```python
def _resolve_output_field(self):
    datetime_fields = {'DateField', 'DateTimeField', 'TimeField'}
    if self.connector == self.SUB:
        lhs_field, rhs_field = self.get_source_fields()
        if lhs_field is not None and rhs_field is not None:
            lhs_type = lhs_field.get_internal_type()
            rhs_type = rhs_field.get_internal_type()
            if lhs_type in datetime_fields and lhs_type == rhs_type:
                return fields.DurationField()
    return super()._resolve_output_field()
```

When the connector is subtraction and both operands resolve to the *same*
temporal field type (`DateField`, `DateTimeField`, or `TimeField`), the expression
now reports `DurationField` as its output field. Every other case (different
connectors, mixed temporal types like `DateTimeField - DurationField`, non-temporal
operands, unresolved operands) falls through to the unchanged base
implementation.

The detection condition (`connector == SUB`, `lhs_type in datetime_fields`,
`lhs_type == rhs_type`) is intentionally identical to the existing guard in
`as_sql()` so inference and SQL generation stay in lock-step.

### Why this fixes the example

* `F('end') - F('start')` now infers `DurationField` instead of `DateTimeField`.
* The outer `... + Value(timedelta(), DurationField())` therefore sees
  `DurationField + DurationField`, which the base inference happily resolves to
  `DurationField`. No more "mixed types" error.
* SQL is unchanged: `as_sql()` still routes the inner subtraction through
  `TemporalSubtraction` (producing e.g. `django_timestamp_diff(...)` on SQLite or
  an interval subtraction on PostgreSQL/Oracle), and the outer
  `DurationField + DurationField` uses the ordinary numeric/interval addition path
  — the same path the existing, already-passing `test_duration_expressions`
  (`F('estimated_time') + delta`) exercises.
* Value conversion is correct: with `output_field = DurationField`, the column is
  run through `DurationField.get_db_converters` (`convert_durationfield_value` on
  microsecond backends), yielding a `datetime.timedelta`.

## Assumptions

* "Temporal subtraction" means subtracting two operands of the **same** temporal
  type. This matches the existing `as_sql()` guard and the documented backend
  helper `subtract_temporals()`. `DateTimeField - DurationField` (mixed) is *not*
  temporal subtraction; it stays handled by the `DurationExpression` path and is
  out of scope for this issue.
* Output-field resolution always happens after `resolve_expression()` has turned
  `F()` references into concrete columns, so `get_source_fields()` returns real
  field instances (or `None`) rather than unresolved `F` objects. This is the same
  precondition the inherited `_resolve_output_field()` already relies on, so the
  override introduces no new failure mode.

## Alternatives considered and rejected

* **Override `resolve_expression()` to return a `TemporalSubtraction`** (the shape
  some refactors take). Rejected as riskier: to inspect operand types it must
  first resolve `lhs`/`rhs`, then it would have to rebuild/re-resolve them inside a
  new `TemporalSubtraction`. Re-resolving already-resolved nodes — especially
  correlated `Subquery`/`OuterRef` operands used in the existing subquery-
  subtraction tests — can double-process them. Overriding `_resolve_output_field()`
  changes nothing about the expression tree or its resolution; it only corrects the
  inferred type lazily, leaving the proven `as_sql()` dispatch untouched.

* **Special-casing the type promotion inside `as_sql()` only.** That is already
  what exists and is exactly why the bug occurs: SQL generation and type inference
  were inconsistent. The fix must live in inference.

* **Documentation-only / requiring users to keep `ExpressionWrapper`.** Contrary to
  the issue's explicit request to make it work without the wrapper.
