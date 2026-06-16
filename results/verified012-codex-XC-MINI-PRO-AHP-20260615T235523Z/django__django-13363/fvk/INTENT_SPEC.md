# Intent Spec

Status: constructed, not machine-checked.

## Required behavior

1. `TruncDate(expression, tzinfo=tz)` must use the explicit `tzinfo` when
   converting a `DateTimeField` value before casting it to a date in SQL.
2. `TruncTime(expression, tzinfo=tz)` must use the explicit `tzinfo` when
   converting a `DateTimeField` value before casting it to a time in SQL.
3. When `tzinfo` is omitted and `USE_TZ` is enabled, both functions must keep
   the existing fallback to Django's current timezone.
4. When `USE_TZ` is disabled, both functions must pass no timezone conversion
   request to the backend, matching the existing `TimezoneMixin.get_tzname()`
   behavior.
5. Both functions must continue to cast rather than call the generic truncation
   SQL operation, because the public docs distinguish `TruncDate` and
   `TruncTime` from the generic `TruncBase.as_sql()` path on that point.
6. The compiled left-hand SQL and params returned by `compiler.compile()` must
   be preserved. The fix must change only timezone selection, not query
   structure, params, return shape, public signatures, or validation behavior.

## Domain

The audited domain is `TruncDate.as_sql()` and `TruncTime.as_sql()` after
expression resolution has accepted the input expression, for all combinations
of:

- `settings.USE_TZ` true or false;
- `self.tzinfo` absent or present;
- any current timezone name;
- any compiled left-hand SQL string and params object.

The formal model abstracts a concrete `tzinfo` object as the timezone name
returned by `timezone._get_timezone_name(self.tzinfo)`. It does not attempt to
prove the correctness of Django's timezone-name helper or the database-specific
SQL emitted by each backend.

