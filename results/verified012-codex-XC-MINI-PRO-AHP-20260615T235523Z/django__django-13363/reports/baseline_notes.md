# Baseline Notes

## Root cause

`TruncDate` and `TruncTime` inherit from `TruncBase`, which stores an optional
`tzinfo` argument and provides `TimezoneMixin.get_tzname()` to convert that
argument into the backend timezone name. However, both classes override
`as_sql()` to use backend cast operations instead of `TruncBase.as_sql()`, and
those overrides rebuilt the timezone name with
`timezone.get_current_timezone_name()` whenever `USE_TZ` was enabled. That
discarded any explicit `tzinfo` passed to `TruncDate()` or `TruncTime()`.

## Changed files

`repo/django/db/models/functions/datetime.py`

Changed `TruncDate.as_sql()` and `TruncTime.as_sql()` to call
`self.get_tzname()` before passing the timezone name to
`connection.ops.datetime_cast_date_sql()` and
`connection.ops.datetime_cast_time_sql()`. This keeps the existing behavior when
no explicit `tzinfo` is supplied, keeps `USE_TZ=False` behavior as `None`, and
allows the explicit `tzinfo` stored by `TruncBase.__init__()` to be honored.

## Assumptions and alternatives considered

I assumed the intended behavior for `TruncDate()` and `TruncTime()` should match
the rest of the `TruncBase` subclasses and `Extract`, where an explicit
`tzinfo` overrides the active timezone only when `USE_TZ` is enabled.

I considered changing backend cast methods, but the backend operation signatures
already accept a `tzname`; the wrong value was being supplied by the function
classes.

I considered routing these classes through `TruncBase.as_sql()`, but
`TruncDate` and `TruncTime` intentionally cast to date/time rather than using
the generic truncation operations, so preserving their overrides is the smaller
and more accurate change.
