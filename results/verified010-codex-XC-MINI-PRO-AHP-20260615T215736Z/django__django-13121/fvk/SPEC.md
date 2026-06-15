# FVK Spec

Status: constructed, not machine-checked.

## Unit under audit

`repo/django/db/models/expressions.py`, specifically the non-native-duration
path through `CombinedExpression.as_sql()` and `DurationExpression.as_sql()`.

The observable under verification is the SQL-shape decision:

- duration-only `+` and `-` expressions compile operands as stored
  microseconds and combine them with ordinary numeric SQL;
- mixed date/time and duration expressions compile duration operands with
  backend interval/date-time formatting and use backend duration-combine hooks.

## Public intent ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The controlling
entries are:

- E1/E2: the issue requires duration-only expressions on SQLite/MySQL to work,
  specifically `DurationField + timedelta`.
- E3: non-native `DurationField` storage is integer microseconds.
- E4: mixed date/time plus duration arithmetic must keep backend interval
  formatting.
- E5: temporal subtraction expressions are duration-producing.
- E6: valid duration-only operator scope is `+` and `-`.

## Formal contract

Let `duration_output(e)` mean that expression `e` produces a duration value.
It is true for:

- `DurationField` columns and values;
- `DurationValue`/`timedelta` literals;
- valid duration-only `+` and `-` expressions;
- temporal subtraction of two fields with the same temporal internal type:
  `DateField`, `DateTimeField`, or `TimeField`.

For non-native-duration backends:

1. If `connector in {+, -}` and both operands satisfy `duration_output`, then
   the compiled SQL must be a numeric combination of the operands' stored
   microsecond SQL.

2. In that duration-only branch, a `DurationValue` must compile through the
   normal `Value` preparation path so it becomes an integer microsecond
   parameter/literal, not backend interval SQL.

3. If either operand is not duration-producing, the expression is mixed
   date/time arithmetic and must use the existing
   `combine_duration_expression()` path with duration operands formatted by
   `format_for_duration_arithmetic()` or `date_interval_sql()`.

4. Operators outside `+` and `-` are outside this fix. They must not enter the
   duration-only numeric branch.

5. Native-duration backends are outside the changed branch because
   `CombinedExpression.as_sql()` only creates `DurationExpression` for this
   purpose when `has_native_duration_field` is false.

## K artifacts

- `fvk/mini-duration-expressions.k`: mini semantics for classifying duration
  output and selecting stored-microsecond vs interval compilation.
- `fvk/duration-expression-spec.k`: K reachability claims for the reported
  reproducer, reversed operands, temporal-subtraction duration operands, mixed
  date/time frame behavior, and invalid-connector exclusion.

These artifacts abstract SQL strings as `numeric(...)`, `durationFn(...)`,
`formatted(...)`, and `stored(...)`. This is property-complete for the reported
bug because the failing behavior is exactly the choice between stored
microsecond output and interval/date-time output.
