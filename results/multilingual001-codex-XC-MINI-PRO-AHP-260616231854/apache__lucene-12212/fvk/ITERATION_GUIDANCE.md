# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code changes justified by FVK

1. Keep the V1 base-approximation fix. It discharges F1, F2, O2, O3, O4, and O5.
2. Keep the V1 chunked-base explicit confirmation changes. They prevent approximation-only base docs after the initial movement change.
3. Add the V2 parenthesized live-doc guard in `doDrillDownAdvanceScoring` for `dims[1]`. It discharges F3, O6, and O7.

## No further production changes recommended

No public API or callsite compatibility issue was found. The remaining limitations are proof-tooling limitations caused by the task's no-execution constraint, not source defects.

## Tests to add or keep

Do not edit tests in this task. For a future test pass, keep or add coverage for:

- a phrase-backed base query in query-first scoring;
- a phrase-backed base query in drill-down-advance scoring;
- a phrase-backed base query in union scoring;
- a phrase-backed second drill-down dimension with `acceptDocs == null` in drill-down-advance scoring;
- a no-two-phase scorer path, to show the exact-iterator behavior is unchanged.

No test-removal recommendation is made because the proof is constructed, not machine-checked.
