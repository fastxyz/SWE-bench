# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Target

`django.utils.http.parse_http_date(date)` parses HTTP-date strings accepted by
RFC 7231 section 7.1.1.1 and returns an integer UTC epoch timestamp. This FVK
pass focuses on the changed year-normalization branch while recording frame
conditions for the rest of the parser.

## Intent-Derived Obligations

1. RFC850 dates use a two-digit year and must not be expanded with a fixed
   `00-69` / `70-99` cutoff.

2. For a two-digit year `YY`, the expansion must be relative to the current UTC
   year `CY`, not to a hard-coded epoch window.

3. Let `CC = CY - (CY mod 100)` and `candidate = CC + YY`. If `candidate` is
   more than 50 years in the future, the interpreted year must be
   `candidate - 100`; otherwise it must be `candidate`.

4. "More than 50 years in the future" is a strict year comparison against
   `CY + 50`. A candidate exactly 50 years ahead is not rolled back.

5. The current year source must be UTC/GMT-aligned because HTTP dates are GMT.
   Local calendar date must not affect the result at timezone boundaries.

6. The fix must preserve the public API shape: `parse_http_date()` still returns
   an integer epoch timestamp or raises `ValueError`; `parse_http_date_safe()`
   still returns that value or `None`.

7. The fix must preserve non-year parsing behavior: recognized RFC1123,
   RFC850, and asctime syntax, month/day/time validation through
   `datetime.datetime`, and `calendar.timegm()` conversion remain unchanged.

8. Existing public behavior for parsed numeric years below 100 outside RFC850,
   such as the asctime public test using `0037`, is compatibility evidence for
   keeping the existing `year < 100` normalization branch rather than narrowing
   it only to the RFC850 regex.

