# Baseline Notes

## Root cause

`django.utils.dateformat.DateFormat.Y()` returned `self.data.year` as an
integer. `Formatter.format()` converts formatter results with `str()`, so years
below 1000 were emitted without leading zeros, for example year 42 became
`"42"` instead of the documented four-digit `"0042"`.

## Files changed

`repo/django/utils/dateformat.py`

- Changed `DateFormat.Y()` to format the year with `'%04d'`, matching the
  documented "Year, 4 digits" behavior and Django's existing style for padded
  date/time fields.

`reports/baseline_notes.md`

- Added this required explanation of the root cause, changed files, assumptions,
  and rejected alternatives.

## Assumptions and alternatives considered

- Assumed the issue is limited to the `Y` date format specifier described in the
  problem statement. The existing `y()` implementation already pads two-digit
  years correctly, and the `o` ISO week-numbering year specifier has separate
  semantics not mentioned by the issue.
- Considered changing `Formatter.format()` to pad integer formatter results, but
  rejected it because many specifiers intentionally return unpadded numeric
  values such as `j`, `n`, `w`, and `z`.
- Considered routing through `strftime()` or `datetime_safe`, but rejected that
  as unnecessary because `Y()` can satisfy the documented contract directly with
  the same `'%04d'` padding pattern already used elsewhere in Django.
- No tests or project code were run, per the benchmark instructions.
