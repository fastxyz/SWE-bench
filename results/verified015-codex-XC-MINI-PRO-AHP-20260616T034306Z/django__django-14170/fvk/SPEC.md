# FVK Spec

Status: constructed, not machine-checked.

## Scope

This audit covers the V1 change for `django__django-14170` and the V2 edits made
after formalization. The verified units are:

- `YearLookup.year_lookup_bounds()` in `repo/django/db/models/lookups.py`.
- `BaseDatabaseOperations.year_lookup_bounds_for_iso_year_date_field()` in
  `repo/django/db/backends/base/operations.py`.
- `BaseDatabaseOperations.year_lookup_bounds_for_iso_year_datetime_field()` in
  `repo/django/db/backends/base/operations.py`.

The proof models the routing and bound construction behavior needed for
`__year` and `__iso_year` lookups. It abstracts backend SQL rendering and date
arithmetic into spec symbols while preserving the observable property under
audit: whether a lookup uses calendar-year or ISO week-year bounds.

## Intent Spec

I-001: `__iso_year` filters must return the same row set as extracting ISO year
with `ExtractIsoYear`.

Evidence: `benchmark/PROBLEM.md` says the optimization is registered for
`"__iso_year"` and "breaks the functionality provided by ExtractIsoYear when
used via the lookup."

I-002: Direct-value year lookup optimization may use `BETWEEN`, but the bounds
must match the transform being optimized.

Evidence: the issue identifies the bad SQL as `BETWEEN 2020-01-01 AND
2020-12-31` for `start_date__iso_year=2020`, and says this "results in the wrong
data being returned by filters using iso_year."

I-003: Existing `__year` behavior must remain calendar-year based.

Evidence: the issue is specifically about `__iso_year`; the existing
`YearLookup` optimization is described as valid for year extraction and only
wrong when applied with ISO-year semantics.

I-004: The fix must cover `DateField` and `DateTimeField`.

Evidence: `YearLookup.year_lookup_bounds()` branches on `DateTimeField` versus
date fields, and `ExtractIsoYear` is registered on `DateField` while
`DateTimeField` inherits date transforms.

I-005: Backend operation dispatch must remain compatible with existing public
overrides where possible.

Evidence: `BaseDatabaseOperations` methods are virtual backend operations; FVK's
compatibility rule requires auditing changed method signatures and virtual
dispatch.

I-006: The in-domain year range includes Python/Django's representable
`datetime.MAXYEAR` value unless the public contract excludes it.

Evidence: existing calendar-year helpers accept year integers and construct
Python `date`/`datetime` values through year 9999; the issue gives no narrower
domain for ISO-year filters.

## Public Evidence Ledger

E-001, prompt: "filtering by `__iso_year`" is broken. Obligation: preserve
`ExtractIsoYear` semantics when the transform is used through lookups. Status:
encoded by PO-001 and PO-002.

E-002, prompt: example SQL uses calendar bounds for `iso_year=2020`.
Obligation: ISO year 2020 must include dates outside calendar year 2020 when
the ISO week-year does. Status: encoded by PO-001.

E-003, code/name: `ExtractIsoYear.lookup_name = 'iso_year'`. Obligation:
`YearLookup` can identify ISO-year transforms from the left-hand transform's
lookup name. Status: encoded by PO-002.

E-004, code: `YearExact`, `YearGt`, `YearGte`, `YearLt`, and `YearLte` consume
the lower/upper bound pair to produce exact and inequality filters. Obligation:
the bound pair must denote the complete contiguous ISO year interval. Status:
encoded by PO-004.

E-005, compatibility: `grep` found no in-repo overrides of
`year_lookup_bounds_for_date_field()` or
`year_lookup_bounds_for_datetime_field()`, but these are virtual backend
operation hooks. Obligation: do not call the legacy hooks with a new keyword.
Status: encoded by PO-006 and resolved in V2.

E-006, default-domain: Python's `datetime.MAXYEAR` is 9999. Obligation:
`iso_year=9999` must not require constructing year 10000 as an intermediate.
Status: encoded by PO-003 and resolved in V2.

## Formal Spec English

FSE-001: For every representable year `Y` with `1 <= Y < 9999`,
`route(date, isoYear, Y)` reaches `dateBounds(isoStart(Y), isoEnd(Y))`.

FSE-002: For every representable year `Y` with `1 <= Y < 9999`,
`route(datetime, isoYear, Y)` reaches
`datetimeBounds(dtStartOf(isoStart(Y)), dtEndOf(isoEnd(Y)))`.

FSE-003: For `Y == 9999`, date ISO-year routing reaches
`dateBounds(isoStart(9999), maxDate)`, and datetime ISO-year routing reaches
`datetimeBounds(dtStartOf(isoStart(9999)), maxDateTime)`.

FSE-004: For every representable year `Y`, calendar `year` routing reaches
January 1 through December 31 calendar bounds for dates, and first through last
calendar instants for datetimes.

FSE-005: `YearLookup.year_lookup_bounds()` selects an ISO helper if and only if
the left-hand transform's `lookup_name` is `iso_year`; otherwise it selects the
existing calendar-year helper.

FSE-006: Existing calendar-year helper signatures remain one-argument methods,
and `YearLookup` does not dispatch to them with the V1-only `iso_year` keyword.

## Spec Audit

FSE-001 passes I-001 and I-002: it states ISO-year bounds, not calendar bounds.

FSE-002 passes I-001, I-002, and I-004: it lifts the date interval to datetime
instants.

FSE-003 passes I-006: it makes the maximum-year boundary explicit and avoids the
unrepresentable year 10000 intermediate.

FSE-004 passes I-003: calendar `__year` behavior is framed unchanged.

FSE-005 passes I-001 and E-003: the routing condition comes from the public
transform name used by Django's lookup registration.

FSE-006 passes I-005: the V2 dispatch avoids the compatibility issue found in
V1.

No formal-English obligation is candidate-derived without independent public or
default-domain evidence.

## Public Compatibility Audit

Changed virtual surface:

- V1 changed `year_lookup_bounds_for_date_field(value)` and
  `year_lookup_bounds_for_datetime_field(value)` to accept `iso_year=False` and
  called them with `iso_year=...`.
- V2 restores those signatures and adds
  `year_lookup_bounds_for_iso_year_date_field(value)` and
  `year_lookup_bounds_for_iso_year_datetime_field(value)`.

In-repo overrides:

- A repository-wide search found no overrides of the two existing year-bound
  helper methods.

Callsites:

- Calendar `__year` routing continues to call the existing one-argument helpers.
- ISO-year routing calls the new ISO-specific helpers, inherited from
  `BaseDatabaseOperations` by standard backend operations classes.

Compatibility verdict:

- V1 had a compatibility finding because a third-party backend overriding the
  old helper signatures could reject the new keyword dispatch.
- V2 resolves the in-repo and normal subclass compatibility concern by leaving
  the legacy method signatures and calls unchanged.

## Formal Core

The K fragment and claims are emitted as:

- `fvk/mini-django-yearlookup.k`
- `fvk/yearlookup-spec.k`

They are intentionally a mini semantics for the lookup-routing and bound-shape
fragment, not a full Python or Django semantics.
