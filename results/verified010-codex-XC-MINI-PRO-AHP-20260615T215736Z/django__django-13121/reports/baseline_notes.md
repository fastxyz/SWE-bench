# Baseline Notes

## Root cause

On backends without native duration columns, `DurationField` values are stored
as integer microseconds. `CombinedExpression.as_sql()` routes expressions with a
duration operand through `DurationExpression`, which is also used for mixed
date/time plus duration arithmetic.

`DurationExpression` treated every duration operand as a date/time interval.
That is correct for expressions such as `DateTimeField + DurationField`, but it
is wrong when both operands are durations. On SQLite this sent two microsecond
integers through `django_format_dtdelta()`, which returns a formatted
`timedelta` string. On MySQL it wrapped operands in `INTERVAL ... MICROSECOND`.
The resulting value was no longer the integer microsecond value expected by the
`DurationField` converter, causing conversion failures for annotations such as
`F('estimated_time') + datetime.timedelta(days=1)`.

## Changed files

`repo/django/db/models/expressions.py`

- Added detection for `+` and `-` expressions whose left and right operands both
  produce `DurationField` values.
- For those duration-only expressions, compiled operands as their stored
  microsecond representation and combined them with ordinary backend arithmetic.
- Preserved the existing duration formatting path for mixed date/time and
  duration expressions, where SQLite and MySQL still need backend-specific
  interval handling.

## Assumptions

- Duration-only arithmetic should return another `DurationField` value encoded
  as integer microseconds on non-native-duration backends.
- The reported issue is limited to valid duration addition and subtraction.
  Unsupported operations such as multiplying two durations should not be newly
  enabled by this fix.
- `timedelta` literals wrapped as `DurationValue` need two compilation modes:
  interval SQL for mixed date/time arithmetic, and the normal `Value` path for
  duration-only arithmetic.

## Alternatives considered

- Changing SQLite's `django_format_dtdelta()` to return microseconds when both
  inputs are integers. This would address SQLite only and leave MySQL returning
  interval values for duration-only arithmetic.
- Changing MySQL's interval formatting. That would not address SQLite and would
  risk breaking valid date/time plus duration expressions.
- Always compiling `DurationValue` through `Value.as_sql()`. This would fix
  duration-only arithmetic but break mixed date/time expressions on MySQL, which
  require SQL interval syntax.
