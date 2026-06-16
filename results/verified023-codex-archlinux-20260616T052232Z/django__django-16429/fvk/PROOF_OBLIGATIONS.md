# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Localize the reported symptom to the pivot branch

Requirement: derive the reported `TypeError` from the modeled mechanism rather
than from the V1 diff alone.

Evidence: F-001 shows that pre-fix `now - d` is aware/aware and defined, while
pre-fix `now - pivot` is aware/naive and fails only after `years or months` is
true.

Status: discharged.

## PO-002: Fix the domain from public intent

Requirement: prove the month/year pivot property for inputs where the initial
`delta = now - d` subtraction is defined. Do not widen the contract to explicit
naive/aware mismatches that public template-filter tests intentionally handle by
catching `TypeError`.

Evidence: public issue concerns `timezone.now() - timedelta(...)`, an aware
input; public filter tests expect `""` when explicit naive/aware mismatches
raise.

Status: discharged.

## PO-003: Preserve timezone awareness on constructed pivots

Requirement: in the `years or months` branch, the constructed pivot must have
the same aware/naive subtraction class as the start datetime `d`.

Constructed formal claim: `pivotV1` in `fvk/timesince-spec.k`.

Proof idea: V1 passes `tzinfo=d.tzinfo` to the pivot constructor. In the mini
semantics, `makePivotV1(..., TZ)` returns a pivot with the same `TZ`, while the
pre-fix `makePivotV0` returns `Naive`.

Status: discharged for Django-supported standard aware/naive datetime inputs.

## PO-004: Preserve the short-interval branch

Requirement: when `years == 0` and `months == 0`, V1 must not disturb the
existing `pivot = d` behavior.

Proof idea: the diff is inside the constructor used only when `years or months`
is true. The `else: pivot = d` branch is unchanged.

Status: discharged by source frame inspection.

## PO-005: Cover `timeuntil()`

Requirement: the wrapper `timeuntil()` must inherit the same fix for long aware
future intervals.

Proof idea: `timeuntil()` still delegates to `timesince(d, now, reversed=True,
...)`. The swap happens before month/year pivot construction, so the V1 pivot
preserves the timezone information of the post-swap start datetime used in the
same measured interval.

Status: discharged.

## PO-006: Preserve public behavior outside timezone awareness

Requirement: V1 must not change public signatures, date conversion, month/day
clamping, ignored microseconds, depth handling, translation, wrapping, or
template/humanize call surfaces.

Proof idea: the diff adds only `tzinfo=d.tzinfo` to the existing
`datetime.datetime()` constructor. The calendar fields, clamped day expression,
formatting loop, and public callers are unchanged.

Status: discharged by source diff and callsite inspection.

## PO-007: Discharge the concrete issue example

Requirement: for `d = timezone.now() - timedelta(days=31)` or the clarified
`days=40` variant under timezone-aware operation, `timesince(d)` should not
raise the reported `TypeError` and should reach the existing month-formatting
path.

Proof idea: `d` is aware, omitted `now` is aware UTC because `is_aware(d)` is
true, and total months is at least one. V1's pivot is aware, so the
remaining-time subtraction is defined. The first nonzero part remains the
month count because the numeric calendar calculation is unchanged.

Status: discharged constructively, not executed.

## PO-008: Honesty gate

Requirement: no test removal, no claim of machine-checked proof, and no inferred
test results.

Evidence: no tests, Python, `kompile`, or `kprove` were run.

Status: discharged.

## PO-009: Decide whether to edit for `fold`

Requirement: audit the named possible improvement of also preserving
`datetime.fold`.

Evidence: Django timezone utilities recognize `fold`, but the public issue and
the reproduced failure identify omitted `tzinfo` as the operative defect.
`timesince()` evidence does not define fold behavior for shifted month/year
pivots.

Status: no source change. Classified as F-007 future precision/test-gap rather
than an obligation for this fix.
