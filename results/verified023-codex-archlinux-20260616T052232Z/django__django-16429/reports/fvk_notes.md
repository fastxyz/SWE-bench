# FVK Notes

The FVK audit confirms V1 and makes no additional source edits.

Decision: add `fvk/mini-timesince.k` and `fvk/timesince-spec.k` alongside the
five requested markdown artifacts. FVK requires a formal core, and PO-001 and
PO-003 require the audit to model the mechanism that produces the reported
TypeError rather than only describe it in prose. The K files encode the
awareness-preservation property recorded in F-001 and F-002.

Decision: keep `repo/django/utils/timesince.py` unchanged from V1. Finding
F-001 localizes the pre-fix crash to the month/year pivot dropping timezone
awareness, and F-002 shows V1 fixes that by passing `tzinfo=d.tzinfo`. This
traces to PO-003, which requires the pivot to preserve the start datetime's
aware/naive subtraction class, and PO-007, which discharges the reported
`timezone.now() - timedelta(days=31 or 40)` regression path.

Decision: do not broaden the fix to normalize datetimes to UTC or alter the
calendar calculation. PO-006 requires preserving month/day clamping, ignored
microseconds, depth handling, translation, and public call surfaces. F-006
records the full formatting behavior as a frame obligation rather than a new
formal proof target, because the V1 diff does not edit that code.

Decision: do not alter `timeuntil()` or template/humanize callers. F-004 shows
`timeuntil()` is covered through the same post-swap pivot invariant, and F-005
shows the public API/callsite compatibility audit has no unresolved issue. These
decisions trace to PO-005 and PO-006.

Decision: do not add `fold=d.fold` in this iteration. F-007 identifies fold as a
possible future precision question, but PO-009 rejects it as a required source
change here because the allowed public issue evidence identifies omitted
`tzinfo`, not fold, as the operative defect.

No tests, Python, `kompile`, or `kprove` were run, and no test files were
modified. PO-008 records this honesty gate.
