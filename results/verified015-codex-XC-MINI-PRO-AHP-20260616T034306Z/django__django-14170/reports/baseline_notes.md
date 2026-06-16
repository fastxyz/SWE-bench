# Baseline Notes

## Root cause

`ExtractIsoYear` registered the same `YearLookup` subclasses used by
`ExtractYear`. When the lookup RHS was a direct value, `YearLookup.as_sql()`
skipped the `EXTRACT` expression and compared the original date/datetime column
against calendar-year bounds. That optimization is valid for `__year`, but
`__iso_year` uses ISO week-numbering years, whose first and last dates can fall
outside January 1 and December 31 of the same calendar year.

For example, ISO year 2020 starts on 2019-12-30 and ends on 2021-01-03, so using
2020-01-01 through 2020-12-31 excludes valid rows and can include invalid rows
around year boundaries.

## Files changed

`repo/django/db/backends/base/operations.py`

Added an `iso_year` option to the central date and datetime year-bound helpers.
For ISO years, the helpers now compute bounds from ISO calendar week 1 day 1 of
the requested year through the moment immediately before ISO calendar week 1 day
1 of the following year. The existing calendar-year behavior remains unchanged
when `iso_year` is false, and the existing backend adaptation and timezone
handling still apply.

`repo/django/db/models/lookups.py`

Updated `YearLookup.year_lookup_bounds()` to detect when the left-hand transform
is `iso_year` and pass that information to the backend bound helpers. This keeps
the index-friendly direct-column comparison while making its bounds match
`ExtractIsoYear`.

## Assumptions and alternatives considered

I assumed the intended fix should preserve the direct-value optimization for
`__iso_year` because ISO years form contiguous date/datetime ranges just like
calendar years, provided the bounds are computed correctly.

I considered removing the `YearLookup` registrations from `ExtractIsoYear`, which
would force `EXTRACT` SQL for ISO-year filters and also fix correctness. I
rejected that because it would unnecessarily drop the existing optimization
instead of correcting the range calculation.

I did not modify tests and did not run tests or other code, per the task
constraints.
