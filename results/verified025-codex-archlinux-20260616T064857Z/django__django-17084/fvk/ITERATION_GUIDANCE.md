# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged.

The audit found one resolved issue, F1, and one out-of-scope ambiguity, F2.
F1 is discharged by PO1, PO2, and PO3. PO4 and PO5 show the change is narrow:
existing wrapper triggers remain intact, the no-trigger path remains direct, and
no public API surface changed.

## Suggested Tests for a Real Execution Environment

Do not edit tests in this benchmark task. For a normal Django development pass,
add tests equivalent to:

1. Annotate a cumulative window value and aggregate `Sum()` over that selected
   annotation.
2. Aggregate both a regular field and the selected window annotation in the same
   `aggregate()` call.
3. Use a wrapper expression such as `Coalesce(Window(...), 0)` as the selected
   annotation, matching the issue example.
4. Confirm an aggregate over a non-window annotation still follows the existing
   behavior and does not gain unnecessary wrapping when no trigger is present.

## Open Question for Future Work

Should Django support direct aggregate expressions containing a `Window`, such
as `aggregate(total=Sum(Window(...)))`?

If yes, a future patch should not merely broaden the wrapper condition. It
should lift the topmost window-containing expression into the inner query,
replace it with an outer `Ref`, and prove that this expression-lifting rewrite
preserves semantics.

## Commands to Run Later

The FVK commands to machine-check later are recorded in `fvk/PROOF.md`. The
Django tests were intentionally not run in this session.
