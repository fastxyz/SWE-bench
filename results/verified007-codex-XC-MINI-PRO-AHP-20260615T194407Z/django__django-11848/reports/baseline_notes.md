# Baseline Notes

## Root cause

`django.utils.http.parse_http_date()` normalized any parsed year below 100
with a fixed POSIX-style cutoff: `00` through `69` became `2000` through
`2069`, and `70` through `99` became `1970` through `1999`. RFC 7231 requires
the interpretation of RFC850 two-digit years to be relative to the recipient's
current year: if the expanded year appears more than 50 years in the future,
it must roll back to the most recent past year with the same last two digits.

Because the cutoff was hard-coded, values such as `69` were always interpreted
as `2069`, even in years where `2069` is more than 50 years in the future and
should therefore be treated as `1969`.

## Changed files

`repo/django/utils/http.py`

Replaced the fixed `70` cutoff in `parse_http_date()` with a calculation based
on the current UTC year. The parser now expands a year below 100 into the
current UTC century, then subtracts 100 years if that candidate is more than
50 years ahead of the current UTC year. This keeps the existing parsing flow
and validation behavior intact while applying the RFC 7231 rollover rule.

## Assumptions and alternatives

I used `datetime.datetime.utcnow().year` rather than local time because HTTP
dates are interpreted in GMT/UTC, and using local date boundaries could change
the result around New Year's depending on server timezone.

I treated "more than 50 years in the future" as a strict comparison
(`candidate_year > current_year + 50`), so a timestamp exactly 50 years ahead
does not roll back.

I kept the existing `year < 100` branch rather than limiting the new logic only
to the RFC850 regex. Although RFC850 is the format with a two-digit year, the
existing function already routed any parsed year below 100 through this
normalization, including four-digit years such as `0037` accepted by the
asctime parser. Narrowing the branch would be a larger behavior change than
the issue requires.

I rejected a fixed `1970`/`2069` window and a fixed `2000`-based expansion
because both would fail once the current year moves relative to the two-digit
value. The chosen implementation derives the century from the current UTC
year, which matches the issue's requirement that the check be relative to the
current year.
