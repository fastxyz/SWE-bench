# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: ISO date bounds are extensionally correct

Statement: For every representable date `D` and every year `Y` with
`1 <= Y < 9999`, `D` has ISO year `Y` if and only if
`isoStart(Y) <= D <= isoEnd(Y)`, where `isoStart(Y)` is ISO week 1 day 1 and
`isoEnd(Y)` is the day before `isoStart(Y + 1)`.

Status: discharged in the constructed proof by the ISO calendar axiom represented
by `isoStart` and `isoEnd` in `fvk/yearlookup-spec.k`.

Finding trace: F-001.

## PO-002: Lookup routing selects ISO helpers exactly for `iso_year`

Statement: `YearLookup.year_lookup_bounds()` must select ISO-specific bound
helpers if and only if `getattr(self.lhs, 'lookup_name', None) == 'iso_year'`.
Otherwise it must select the existing calendar-year helpers.

Status: discharged by symbolic case split on `iso_year` and field kind in
`fvk/mini-django-yearlookup.k`.

Finding trace: F-001.

## PO-003: Maximum representable year does not require year 10000

Statement: For `Y == datetime.MAXYEAR`, ISO date bounds end at `date.max` and
ISO datetime bounds end at `datetime.max`; the code must not evaluate
`fromisocalendar(Y + 1, 1, 1)`.

Status: discharged by V2 branch in both ISO helper methods and by the max-year
claims in `fvk/yearlookup-spec.k`.

Finding trace: F-003.

## PO-004: Year comparison operators remain equivalent to extraction

Statement: Given a contiguous year interval `[start, finish]`, the direct-column
comparisons used by `YearExact`, `YearGt`, `YearGte`, `YearLt`, and `YearLte`
are equivalent to comparing the extracted year value:

- exact: `field BETWEEN start AND finish`;
- greater than: `field > finish`;
- greater than or equal: `field >= start`;
- less than: `field < start`;
- less than or equal: `field <= finish`.

Status: discharged by monotonicity of calendar and ISO year intervals. The code
change supplies the correct interval to the existing operator-specific bound
parameter methods.

Finding trace: F-001.

## PO-005: Calendar-year behavior is framed unchanged

Statement: For non-ISO `year` transforms, date bounds remain January 1 through
December 31, and datetime bounds remain the first through last representable
calendar-year instants.

Status: discharged by unchanged existing helper bodies and the calendar claims in
`fvk/yearlookup-spec.k`.

Finding trace: none; this is a frame condition.

## PO-006: Backend helper dispatch is compatible with existing signatures

Statement: The fix must not call
`year_lookup_bounds_for_date_field(value)` or
`year_lookup_bounds_for_datetime_field(value)` with a new keyword or extra
argument.

Status: V1 failed this obligation. V2 discharges it by preserving the original
helper signatures and dispatching ISO-year lookups to new helper names.

Finding trace: F-002.

## PO-007: Timezone and adaptation behavior is preserved for datetime bounds

Statement: ISO datetime bounds must follow the same timezone and backend
adaptation path as existing calendar datetime bounds: construct naive local
bounds, apply `timezone.make_aware()` when `settings.USE_TZ`, then call
`adapt_datetimefield_value()` on both bounds.

Status: discharged by the shared structure of the new ISO datetime helper and
the existing calendar datetime helper.

Finding trace: F-001.

## Machine-check commands

These commands are recorded only; they were not executed.

```sh
kompile fvk/mini-django-yearlookup.k --backend haskell
kast --backend haskell fvk/yearlookup-spec.k
kprove fvk/yearlookup-spec.k
```
