# FVK Notes

## Summary

The FVK audit confirmed V1's core correction: `__iso_year` may keep the
index-friendly year lookup optimization if it uses ISO week-year bounds rather
than calendar-year bounds. That decision is justified by F-001 and PO-001
through PO-004.

The audit also found two V1 issues and both were fixed in V2:

- F-002 / PO-006: V1 changed virtual backend helper dispatch by passing a new
  `iso_year` keyword to existing calendar-year helper methods. V2 preserves the
  original helper signatures and adds separate ISO-specific helper methods.
- F-003 / PO-003: V1 computed ISO end bounds from `value + 1`, which fails for
  `datetime.MAXYEAR`. V2 caps the maximum-year ISO upper bound at `date.max` or
  `datetime.max`.

## Source Decisions

`repo/django/db/models/lookups.py`

Decision: keep the transform-sensitive routing introduced by V1, but route to
separate ISO helper methods instead of passing `iso_year=...` into existing
calendar helper methods.

Trace: F-001 and PO-002 justify detecting `self.lhs.lookup_name == 'iso_year'`;
F-002 and PO-006 justify avoiding the V1 keyword dispatch.

`repo/django/db/backends/base/operations.py`

Decision: keep the existing calendar-year helper bodies and signatures
unchanged, and add `year_lookup_bounds_for_iso_year_date_field()` plus
`year_lookup_bounds_for_iso_year_datetime_field()`.

Trace: PO-005 requires calendar-year behavior to remain unchanged; PO-006
requires compatibility with existing helper signatures; F-001, PO-001, PO-004,
and PO-007 require ISO-specific bounds and existing datetime timezone/adaptation
behavior.

Decision: handle `value == datetime.MAXYEAR` in both ISO helper methods.

Trace: F-003 and PO-003 require avoiding `fromisocalendar(value + 1, 1, 1)` when
`value` is 9999.

## Artifacts

The FVK artifact set is under `fvk/`:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-django-yearlookup.k`
- `fvk/yearlookup-spec.k`

The proof is constructed, not machine-checked. The K commands are recorded in
the artifacts but were not run, per the task constraints.
