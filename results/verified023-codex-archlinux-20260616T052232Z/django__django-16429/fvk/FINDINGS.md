# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations only.

## F-001: Pre-fix month/year pivot dropped timezone awareness

Input: an aware datetime `d` at least one month in the past, with `now` omitted
so `timesince()` supplies an aware UTC `now`.

Observed pre-fix behavior: `delta = now - d` is defined, but the month/year
branch constructs `pivot` without `tzinfo`, making `remaining_time = now -
pivot` a mixed aware/naive subtraction and raising `TypeError`.

Expected behavior: the month/year branch should remain in the same awareness
class as the initial subtraction and proceed to produce the formatted elapsed
time.

Classification: code bug, fixed by V1. Related obligations: PO-001, PO-003,
PO-007.

## F-002: V1 preserves the awareness property required by the issue

Input: the same in-domain aware long-interval input as F-001.

Observed V1 behavior by source inspection and formal model: the pivot
constructor receives `tzinfo=d.tzinfo`, so the pivot no longer falls back to a
naive datetime solely because it was reconstructed for the month/year branch.

Expected behavior: if `now - d` was defined before the pivot, `now - pivot` is
also defined for Django-supported standard aware/naive datetime inputs.

Classification: resolved proof finding. Related obligations: PO-002, PO-003.

## F-003: Shorter intervals were already correct with respect to timezone awareness

Input: any in-domain interval where `years == 0` and `months == 0`.

Observed behavior: the code uses `pivot = d`, preserving all of `d`'s datetime
metadata. The regression cannot be localized to this branch.

Expected behavior: V1 should leave this branch unchanged.

Classification: no code change needed. Related obligations: PO-004, PO-006.

## F-004: `timeuntil()` is covered through the same pivot invariant

Input: an aware future datetime at least one month away, via `timeuntil()`.

Observed behavior: `timeuntil()` delegates to `timesince(..., reversed=True)`.
After the swap, the month/year pivot is still built from the start datetime of
the measured interval, and V1 preserves that datetime's `tzinfo`.

Expected behavior: the wrapper should not need a separate fix or API change.

Classification: no code change needed. Related obligations: PO-005.

## F-005: Public API compatibility has no unresolved issue

Input: public call paths through `timesince()`, `timeuntil()`, template filters,
and humanize helpers.

Observed behavior: V1 changes only an argument passed to an internal
`datetime.datetime()` constructor. No Django public signature, dispatch path, or
return type is changed.

Expected behavior: callers keep the same API surface.

Classification: compatibility pass. Related obligations: PO-006.

## F-006: Full formatting and localization are frame obligations, not newly proved

Input: arbitrary in-domain `timesince()` calls involving custom `time_strings`,
translation, `avoid_wrapping()`, and depth-limited result joining.

Observed behavior: V1 does not edit the formatting loop, translation call, depth
logic, or `time_strings` handling.

Expected behavior: those behaviors remain covered by existing tests and by
source frame inspection, not by this small K model.

Classification: residual proof-scope limitation, not a source bug. Related
obligations: PO-006, PO-008.

## F-007: `fold` preservation is a possible future precision question

Input: a zoneinfo-aware ambiguous datetime with `fold=1` whose shifted pivot
date is also ambiguous.

Observed behavior: V1 preserves `tzinfo` but leaves `fold` at the constructor
default. The public issue and existing `timesince()` evidence identify
`tzinfo`, not `fold`, as the regression source.

Expected behavior: unspecified by the allowed public evidence for this task.

Classification: underspecified intent / possible future test gap. This does not
block V1 for django__django-16429 because the reported TypeError is discharged
by preserving `tzinfo`. Related obligations: PO-009.
