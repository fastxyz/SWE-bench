# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

## Why

FINDING F1 and PO1/PO2 localize the pre-V1 defect to an insufficient scope shift for existing `OuterRef` values when `split_exclude()` introduces a generated nested query. V1 directly repairs that by wrapping the existing `OuterRef` object, not merely its name.

FINDING F2 and PO3 show the existing plain `F()` behavior remains intact. FINDING F3 and PO4 show non-expression RHS values remain unchanged. PO5 shows no public compatibility change.

## Do Not Change

- Do not change `OuterRef.resolve_expression()`. The existing nested `OuterRef` behavior is the mechanism V1 relies on.
- Do not change `Query.resolve_expression()` or lookup resolution. Those are shared subquery mechanisms, and the audit found the missing shift at the point where `split_exclude()` adds an extra query level.
- Do not edit tests in this benchmark setting.

## Future Work In An Execution-Capable Environment

- Run Django's relevant query tests.
- Add or keep coverage for both `exclude()` and `filter(~Q(...))` with `OuterRef()` inside `Exists()`.
- Add or keep a regression for plain `F()` RHS values through `split_exclude()`.
- Optionally machine-check the emitted K claims with the commands in `PROOF.md`.
