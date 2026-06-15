# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Leading minus negates a no-day standard duration

- Evidence: E3.
- Formal claim: `STD-NODAYS-NEG`.
- Required result: `stdNoDays(neg, H, M, S, U)` returns
  `tdUs(-TIME_US(H, M, S, U))`.
- V1 status: discharged by regex `(?P<sign>-?)` before the time portion and by
  `sign * datetime.timedelta(**kw)` in `parse_duration()`.

## PO-2: Signs after colons are invalid standard syntax

- Evidence: E4 and E5.
- Formal claim: `STD-INTERNAL-SIGN-INVALID`.
- Required result: `stdInternalSign` returns `none`.
- V1 status: discharged because `hours`, `minutes`, and `seconds` in
  `standard_duration_re` no longer allow `-`.

## PO-3: Signed day standard strings preserve day-component semantics

- Evidence: E7.
- Formal claim: `STD-DAYS-PRESERVE`.
- Required result: `stdDays(D, pos, H, M, S, U)` returns
  `tdUs(daysUs(D) + TIME_US(H, M, S, U))`.
- V1 status: discharged because the day component still permits `-?` and the
  time sign is empty for Django/Python duration strings such as `-1 01:03:05`.

## PO-4: A second time sign after a day component is invalid

- Evidence: E4 and E5 generalized to non-leading signs.
- Formal claim: `STD-DAYS-SIGNED-TIME-INVALID`.
- Required result: `stdDays(D, neg, H, M, S, U)` returns `none`.
- V1 status: discharged by the explicit guard:
  `if match.re is standard_duration_re and kw.get('days') and kw.get('sign') == '-': return None`.

## PO-5: Reported concrete cases derive from the general claims

- Evidence: E3.
- Formal claims: `REPORTED-HMS` and `REPORTED-MS`.
- Required results:
  - `-00:01:01` is negative 61 seconds.
  - `-01:01` is negative 61 seconds.
- V1 status: discharged by PO-1.

## PO-6: Other format families are framed

- Evidence: E6 and public PostgreSQL tests.
- Required result: ISO 8601 and PostgreSQL day-time interval behavior is not
  changed by the standard-format sign fix.
- V1 status: discharged structurally: their regex definitions and arithmetic
  remain unchanged. PostgreSQL strings with textual `day`/`days` markers do not
  match the standard regex first.

## PO-7: Public API compatibility is preserved

- Evidence: E9.
- Required result: `parse_duration(value)` keeps the same signature and return
  type family, and existing callers continue to handle parsed and invalid
  values.
- V1 status: discharged by unchanged function signature and unchanged
  `datetime.timedelta`/`None` result convention.

## Non-blocking observation

After V1, the branch that prefixes microseconds when `seconds.startswith('-')`
is unreachable for all three regex families. It is dead legacy support for the
old component-signed standard regex. It does not contradict any proof obligation
and was left unchanged to keep the production patch focused.
