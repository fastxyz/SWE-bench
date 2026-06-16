# Iteration Guidance

Status: constructed, not machine-checked.

## Decisions Applied In V2

1. Keep V1's core idea of correcting ISO-year bounds instead of disabling the
   optimization.
   - Justification: F-001 and PO-001 through PO-004 show that ISO years are
     contiguous intervals, so `BETWEEN` remains valid with correct bounds.

2. Replace V1's `iso_year` keyword on existing backend helpers with new
   ISO-specific helper methods.
   - Justification: F-002 and PO-006 show that calling virtual backend methods
     with a new keyword is a compatibility risk.

3. Add a `datetime.MAXYEAR` branch to ISO bound helpers.
   - Justification: F-003 and PO-003 show that `value + 1` is not representable
     for `value == 9999`.

## Follow-up Tests To Add Or Keep

These are recommendations only; test files were not modified.

- Date ISO boundary exact lookup: ISO year 2020 includes `2019-12-30` and
  `2021-01-03`, and excludes adjacent dates outside that ISO year.
- DateTime ISO boundary exact lookup with timezone settings enabled and disabled.
- Inequality lookups for ISO year: `gt`, `gte`, `lt`, and `lte` around ISO
  boundary instants.
- Calendar `__year` regression tests proving January 1 through December 31
  behavior remains unchanged.
- `iso_year=9999` date and datetime lookups.
- Compatibility regression using a backend operations subclass whose calendar
  helper overrides accept only `(self, value)`.

## Residual Risks

- The FVK proof is constructed over a mini semantics and was not machine-checked.
- The mini semantics abstracts ISO calendar arithmetic through `isoStart` and
  `isoEnd`; this is appropriate for the routing/bounds property but not a full
  proof of Python's `datetime` implementation.
- Total correctness and SQL backend execution are outside this proof. The code
  has no loops in the audited fragment, but generated SQL should still be covered
  by integration tests.

## Commands For A Future Machine Check

Do not run these in this benchmark session. They are recorded for a future
environment with K installed.

```sh
kompile fvk/mini-django-yearlookup.k --backend haskell
kast --backend haskell fvk/yearlookup-spec.k
kprove fvk/yearlookup-spec.k
```
