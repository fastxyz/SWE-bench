# Constructed Proof

Status: constructed, not machine-checked.

## Claim Summary

The proof establishes partial correctness for lookup-bound selection and
construction:

- `__iso_year` date lookups route to ISO date bounds.
- `__iso_year` datetime lookups route to ISO datetime bounds.
- `__year` date and datetime lookups keep calendar-year bounds.
- `datetime.MAXYEAR` is handled without constructing year 10000.
- Existing calendar-year helper dispatch signatures are preserved.

## Symbolic Execution Sketch

1. Start from `YearLookup.year_lookup_bounds(connection, year)`.
2. Evaluate `output_field = self.lhs.lhs.output_field`.
3. Evaluate `iso_year = getattr(self.lhs, 'lookup_name', None) == 'iso_year'`.
4. Case split on `isinstance(output_field, DateTimeField)`.
5. In the datetime branch, case split on `iso_year`.
   - true: select `ops.year_lookup_bounds_for_iso_year_datetime_field`;
   - false: select `ops.year_lookup_bounds_for_datetime_field`.
6. In the date branch, case split on `iso_year`.
   - true: select `ops.year_lookup_bounds_for_iso_year_date_field`;
   - false: select `ops.year_lookup_bounds_for_date_field`.
7. Call the selected helper with the original `year` argument.

This discharges PO-002, PO-005, and PO-006.

## ISO Date Helper Proof

For `1 <= Y < 9999`, the helper constructs:

```text
first = date.fromisocalendar(Y, 1, 1)
second = date.fromisocalendar(Y + 1, 1, 1) - 1 day
```

By the ISO calendar definition, `first` is the first date in ISO year `Y` and
`second` is the last date in ISO year `Y`. Applying `adapt_datefield_value()` to
both bounds preserves their ordering and backend representation role. This
discharges PO-001 for date fields.

For `Y == 9999`, the helper constructs:

```text
first = date.fromisocalendar(9999, 1, 1)
second = date.max
```

Since no Python date can exceed `date.max`, this is the complete representable
upper bound for ISO year 9999. This discharges PO-003 for date fields.

## ISO DateTime Helper Proof

For `1 <= Y < 9999`, the helper constructs the first instant of
`isoStart(Y)` and the instant immediately before the first instant of
`isoStart(Y + 1)`.

For `Y == 9999`, the helper uses `datetime.max` as the upper bound. Since no
Python datetime can exceed `datetime.max`, this covers all representable
datetimes in ISO year 9999.

When `settings.USE_TZ` is true, the helper applies the same current-timezone
conversion as the existing calendar datetime helper, then adapts both values
with `adapt_datetimefield_value()`. This discharges PO-001, PO-003, and PO-007
for datetimes.

## Operator Equivalence Proof

ISO years and calendar years partition representable dates/datetimes into
contiguous, ordered intervals. Therefore:

- exact year comparison is equivalent to membership in the interval;
- `gt` is equivalent to being after the interval's finish;
- `gte` is equivalent to being at or after the interval's start;
- `lt` is equivalent to being before the interval's start;
- `lte` is equivalent to being at or before the interval's finish.

The existing `YearExact`, `YearGt`, `YearGte`, `YearLt`, and `YearLte`
implement these comparisons from a `(start, finish)` pair. Supplying ISO bounds
therefore restores equivalence with `ExtractIsoYear`. This discharges PO-004.

## Adequacy Gate

The English spec in `fvk/SPEC.md` matches the public issue intent:

- it rejects calendar-year bounds for `__iso_year`;
- it preserves calendar-year bounds for `__year`;
- it covers both date and datetime branches;
- it audits backend-operation compatibility instead of treating V1's new keyword
  dispatch as automatically safe.

No obligation depends solely on V1 behavior.

## Machine-check Commands

These commands are recorded for a future environment with K installed. They were
not executed in this session.

```sh
kompile fvk/mini-django-yearlookup.k --backend haskell
kast --backend haskell fvk/yearlookup-spec.k
kprove fvk/yearlookup-spec.k
```

Expected result after machine checking: `kprove` returns `#Top` for the claims in
`fvk/yearlookup-spec.k`.

## Test Recommendation

Do not delete tests based on this constructed proof. Keep existing tests until
the K commands are run and pass. Useful public tests to add or retain include:

- `start_date__iso_year=2020` includes `2019-12-30` and `2021-01-03`;
- `start_datetime__iso_year=2020` covers the same ISO interval at datetime
  precision;
- `__iso_year` exact, `gt`, `gte`, `lt`, and `lte` use correct interval
  boundaries;
- `__year` still uses calendar-year boundaries;
- `__iso_year=9999` does not attempt to construct year 10000;
- a backend operations subclass with legacy calendar helper signatures is not
  called with an unexpected keyword.
