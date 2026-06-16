# Baseline Notes

## Root cause

`django.utils.timesince.timesince()` computes years and months separately, then
constructs a shifted `pivot` datetime to calculate the remaining weeks, days,
hours, and minutes. When that shifted pivot was created for intervals of at
least one month, the constructor omitted `tzinfo`, so an aware input datetime
produced a naive pivot. With `USE_TZ=True`, `timesince()` can supply an aware
`now`, and subtracting that from the naive pivot raised `TypeError: can't
subtract offset-naive and offset-aware datetimes`.

Intervals shorter than a month did not hit this branch because they reuse `d`
as the pivot, preserving its awareness.

## Files changed

`repo/django/utils/timesince.py`

Preserved `d.tzinfo` when constructing the month/year pivot datetime. This keeps
the pivot's timezone awareness aligned with the starting datetime while leaving
the existing month/day clamping and remaining-time calculation unchanged.

## Assumptions and alternatives considered

I assumed the pivot should represent the same wall-clock time as `d` shifted by
the computed year/month count, including the same timezone object. This matches
the shorter-interval path, where `pivot = d` already preserves `tzinfo`.

I considered using `datetime.replace()` on `d`, but rejected it because the
current constructor deliberately controls the shifted year, month, clamped day,
hour, minute, second, and zero microseconds. Keeping that structure minimizes the
behavioral change.

I also considered normalizing both datetimes to UTC before subtraction, but that
would be broader than necessary and could change timezone-sensitive wall-clock
month calculations. Passing through `d.tzinfo` fixes the naive/aware mismatch
without changing the existing algorithm.
