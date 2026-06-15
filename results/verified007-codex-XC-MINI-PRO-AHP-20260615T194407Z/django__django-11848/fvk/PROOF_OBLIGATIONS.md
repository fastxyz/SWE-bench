# Proof Obligations

Status: constructed for FVK audit, not machine-checked.

## PO-001: Intent Adequacy

The formal contract must be derived from the public problem, not from V1 output.

Evidence: E2, E3, E4, E5, E6.

Discharge: `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`
agree on the same current-year-relative rollover rule.

## PO-002: Non-Rollover Branch

For all `CY >= 100` and `0 <= YY < 100`, if:

```text
CANDIDATE = CY - (CY mod 100) + YY
CANDIDATE <= CY + 50
```

then the normalized year is `CANDIDATE`.

Discharge: first claim in `http-date-spec.k`; V1 lines 182-186 add the current
century and do not subtract 100 when the strict comparison is false.

## PO-003: Rollover Branch

For all `CY >= 100` and `0 <= YY < 100`, if:

```text
CANDIDATE = CY - (CY mod 100) + YY
CANDIDATE > CY + 50
```

then the normalized year is `CANDIDATE - 100`.

The result must be in the past relative to `CY` and have the same last two
digits as `YY`.

Discharge: second claim in `http-date-spec.k`; V1 line 186 subtracts exactly
100 under the strict future comparison.

## PO-004: Fixed-Cutoff Rejection

There must be no hard-coded `70` threshold in the normalized result.

Discriminator:

```text
CY = 2018, YY = 69
legacy fixed cutoff -> 2069
required result -> 1969
```

Discharge: third claim in `http-date-spec.k`; V1 computes `2069 > 2018 + 50`
and rolls back.

## PO-005: UTC Current Year

The current-year source must be UTC/GMT-aligned, not local date.

Discharge: V1 line 182 uses `datetime.datetime.utcnow().year`.

## PO-006: Parser Frame Conditions

The change must not alter format matching, month lookup, day/time validation,
timestamp conversion, exception wrapping, or `parse_http_date_safe()` behavior.

Discharge: V1 changes only lines 178-186 in `parse_http_date()`; no public
signature, regex, month/day/time, `datetime`, `calendar.timegm()`, or safe
wrapper code changes.

## PO-007: Compatibility of Broad `year < 100` Branch

The issue intent is RFC850-specific, but the existing code and public test
suite also route parsed numeric years below 100 through the same branch.
Narrowing the branch to RFC850-only would be a behavior change outside the
requested fix.

Discharge: V1 keeps the existing `if year < 100` branch and changes only how
that branch computes the century.
