# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Verdict

V1 should stand unchanged.

The FVK audit found the same root defect as the baseline notes and no additional
source-level defect. The public intent is to add `positive=True` while retaining
other assumptions for symbols whose positivity is unknown. V1 implements that
operation directly by copying `s.assumptions0`, setting `positive=True`, and
constructing the replacement dummy from the merged assumption dictionary.

## Trace to Findings and Proof Obligations

1. Keep V1 assumption merge: F1 and F2 are resolved by PO2 and PO3.
2. Keep the existing `s.is_positive is None` guard: F3 is confirmed by PO1 and
   PO6. Broadening the branch would risk changing behavior for symbols whose
   positivity is already known.
3. Keep the existing reverse-map and iterable logic: F4 is confirmed by PO4,
   PO5, and PO7. The bug is in dummy construction, not mapping direction or
   iterable traversal.
4. Do not edit tests in this benchmark: F5 and PO8 require proof-honesty
   labeling, and the task explicitly forbids test-file changes.

## Rejected Follow-Up Edits

1. Preserve only `finite=True`: rejected because F2 and `SPEC.md` E3-E4 make the
   intended contract a family over all existing assumptions, not a single fact.
2. Change `Symbol` or `Dummy`: rejected because F1 and F2 localize the defect to
   `posify` passing too few assumptions to `Dummy`; PO2 and PO3 are discharged by
   a local source change.
3. Change public return shape or replacement-map direction: rejected because F4
   and PO4-PO7 confirm those behaviors are already compatible and publicly
   exercised.
4. Add a new consistency filter beyond `s.is_positive is None`: rejected because
   PO6 identifies the existing assumptions-engine query as the intended
   eligibility check for positive narrowing. A broader guard would be
   implementation-derived without public evidence.

## Recommended Follow-Up Tests

These are recommendations only; no test files were edited.

1. Add coverage for `Symbol('x', finite=True)` through `posify`.
2. Add at least one non-finiteness assumption preservation case, such as
   `integer=True` or `rational=True`.
3. Keep restoration checks using the returned replacement map.
4. Keep existing tests for positive, negative, iterable, and noncommutative
   inputs.

## Machine-Checking Follow-Up

The FVK commands recorded in `PROOF.md` should be run in an environment with K
available before claiming machine-checked verification or removing any tests.
Expected success is `kprove` reducing the claims to `#Top`.
