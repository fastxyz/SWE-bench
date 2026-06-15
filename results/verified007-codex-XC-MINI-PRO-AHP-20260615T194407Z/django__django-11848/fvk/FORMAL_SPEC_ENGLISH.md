# Formal Spec English

Status: constructed for FVK audit, not machine-checked.

The K core in `mini-http-date.k` and `http-date-spec.k` models the arithmetic
year-normalization slice of `parse_http_date()`. Regex matching, month/day/time
validation, and epoch conversion are frame conditions rather than reimplemented
in the mini semantics.

## Claim C1: Current-Century Candidate Branch

For every current UTC year `CY >= 100` and two-digit parsed year
`0 <= YY < 100`, define:

`CC = CY - (CY mod 100)`

`CANDIDATE = CC + YY`

If `CANDIDATE <= CY + 50`, `normalize2(YY, CY)` returns `CANDIDATE`.

## Claim C2: Rollover Branch

For every current UTC year `CY >= 100` and two-digit parsed year
`0 <= YY < 100`, define `CC` and `CANDIDATE` as above.

If `CANDIDATE > CY + 50`, `normalize2(YY, CY)` returns
`CANDIDATE - 100`.

The result is in the past relative to `CY`, has the same last two digits as
`YY`, and is the most recent past year with those last two digits.

## Claim C3: Example Discriminator

For `CY = 2018` and `YY = 69`, the fixed-window legacy result is `2069`, but
the spec result is `1969` because `2069 > 2018 + 50`.

## Claim C4: Boundary

For `CANDIDATE = CY + 50`, the result is `CANDIDATE`, not
`CANDIDATE - 100`, because the RFC wording says "more than 50 years".

## Claim C5: Frame Conditions

The proof does not alter or claim new semantics for regex recognition,
month lookup, day/time validity, timestamp conversion, exception wrapping, or
the public signatures of `parse_http_date()` and `parse_http_date_safe()`.
