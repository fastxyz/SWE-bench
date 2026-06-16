# FVK Findings

Status: constructed, not machine-checked.

## F-001: Original ISO-year filters used calendar-year bounds

Classification: code bug, resolved.

Input: `start_date__iso_year=2020` with a row whose date is `2019-12-30`.

Observed before the fix: the optimized lookup used `BETWEEN 2020-01-01 AND
2020-12-31`, so `2019-12-30` was excluded even though it belongs to ISO year
2020.

Expected: the filter should use ISO year 2020's full date interval, starting at
ISO week 1 day 1 and ending at the last representable instant before ISO year
2021 starts.

Evidence: `benchmark/PROBLEM.md`; PO-001, PO-002, PO-004.

Resolution: V2 routes `iso_year` lookups to ISO-specific bound helpers while
leaving calendar `year` lookups on the existing helpers.

## F-002: V1 introduced a backend-operation keyword compatibility risk

Classification: compatibility bug in V1, resolved.

Input: a backend operations subclass that overrides
`year_lookup_bounds_for_date_field(self, value)` or
`year_lookup_bounds_for_datetime_field(self, value)` with the existing
one-argument signature.

Observed in V1: `YearLookup` called those virtual methods with
`iso_year=...`. Such an override would raise `TypeError` before producing SQL.

Expected: the fix should not require existing backend overrides of calendar-year
helpers to accept a new keyword.

Evidence: FVK public compatibility audit; PO-006.

Resolution: V2 restores the original helper signatures and adds separate
ISO-year helper methods. Calendar-year dispatch remains unchanged.

## F-003: V1's ISO-year end calculation excluded `datetime.MAXYEAR`

Classification: boundary bug in V1, resolved.

Input: `start_date__iso_year=9999` or `start_datetime__iso_year=9999`.

Observed in V1: ISO end bounds were computed from
`date.fromisocalendar(value + 1, 1, 1)`, which requires constructing ISO year
10000 for `value == 9999`.

Expected: year 9999 is within Python/Django's representable date/datetime range,
so an ISO-year lookup for 9999 should use the maximum representable date or
datetime as the upper bound rather than attempting year 10000.

Evidence: default Python date domain; PO-003.

Resolution: V2 special-cases `datetime.MAXYEAR`, using `date.max` and
`datetime.max` as the upper bounds.

## F-004: Proof is constructed over a mini semantics, not machine-checked

Classification: proof capability gap, not a code bug.

The emitted K files model lookup routing and bound shape, with abstract ISO
calendar functions (`isoStart`, `isoEnd`) rather than a full Python/Django date
semantics. This is adequate for the audit property because it distinguishes the
failing calendar interval from the passing ISO interval, but it is not a full
machine-checked proof of Django.

Recommended action: keep tests until the recorded `kompile` and `kprove`
commands are run and the proof returns `#Top`.

## Proof-derived findings from `/verify`

No additional unresolved code bugs were found after V2. The proof obligations
that blocked V1 are F-002 and F-003; both are addressed in source.
