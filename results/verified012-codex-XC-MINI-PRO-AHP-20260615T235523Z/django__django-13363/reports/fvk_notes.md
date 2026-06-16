# FVK Notes

## Decision summary

V1 stands unchanged after the FVK audit. No additional production source files
were edited in this pass.

## Trace to findings and proof obligations

`fvk/FINDINGS.md` F1 identifies the original `TruncDate` bug: with
`USE_TZ=True`, active timezone `UTC`, and explicit timezone
`America/New_York`, the pre-V1 method forwarded `UTC` to the backend date cast.
`fvk/PROOF_OBLIGATIONS.md` PO1 and PO4 require explicit timezone priority and
date-cast forwarding. V1 satisfies both because `TruncDate.as_sql()` now calls
`self.get_tzname()` and passes that result to
`datetime_cast_date_sql(lhs, tzname)`.

`fvk/FINDINGS.md` F2 identifies the analogous `TruncTime` bug.
`fvk/PROOF_OBLIGATIONS.md` PO1 and PO5 require explicit timezone priority and
time-cast forwarding. V1 satisfies both because `TruncTime.as_sql()` now calls
`self.get_tzname()` and passes that result to
`datetime_cast_time_sql(lhs, tzname)`.

`fvk/PROOF_OBLIGATIONS.md` PO2 and PO3 require preserving existing fallback
behavior: use the current timezone when `tzinfo` is omitted and `USE_TZ=True`,
and pass no timezone when `USE_TZ=False`. Keeping the existing
`TimezoneMixin.get_tzname()` implementation satisfies these obligations without
additional code.

`fvk/PROOF_OBLIGATIONS.md` PO6 requires compatibility: no public signature,
backend method signature, validation path, null handling behavior, params, or
return shape change. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records that the V1
change only changes the selected `tzname` value and preserves all of those
interfaces.

`fvk/FINDINGS.md` F3 is a test gap, not a production-code defect. The task
forbids modifying tests, so no test file was edited. The future regression
tests are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.

## Rejected changes

I did not change backend operations because `fvk/PUBLIC_EVIDENCE_LEDGER.md` E12
and PO4/PO5 show the backend APIs already accept a `tzname`; the defect was the
caller supplying the wrong one.

I did not route `TruncDate` or `TruncTime` through `TruncBase.as_sql()` because
E9 and PO4/PO5 require preserving the documented cast-specific operations.

I did not add broader timezone-name helper changes because PO1-PO3 are already
discharged by the existing `TimezoneMixin.get_tzname()` contract.

