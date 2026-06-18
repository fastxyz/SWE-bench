# Findings

Status: constructed, not machine-checked.

## F1: Reported solver-incomplete relational as_set bug

Input:
`Eq(n*cos(n) - 3*sin(n), 0).as_set()`

Observed before V1:
`NotImplementedError` escaped from the solver-backed relational conversion.

Expected from public intent:
`ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), Reals)`.

Classification:
code bug, fixed by V1.

Evidence:
ledger entries E1, E2, E3, and claims `REL-EVAL-UNSOLVED` and
`BOOL-AS-SET-NONPERIODIC-UNSOLVED`.

Decision:
V1 discharges this finding by catching solver `NotImplementedError` in
`Relational._eval_as_set()` and returning `ConditionSet(x, self, S.Reals)`.

## F2: Regression frame for solved relationals

Scenarios:
`Eq(x, 0).as_set()`, `(x > 0).as_set()`, `Ne(x, 0).as_set()`, and
`(x**2 >= 4).as_set()`.

Expected:
Exact sets from the solver-backed conversion remain unchanged.

Classification:
regression-prevention obligation.

Evidence:
ledger entry E7 and claims `REL-EVAL-EXACT` and
`BOOL-AS-SET-NONPERIODIC-EXACT`.

Decision:
No V2 edit is required. V1 preserves exact solver results by returning from the
`try` block unchanged when no `NotImplementedError` is raised.

## F3: No proof-derived counterexample requiring source edits

The adequacy audit passed, the compatibility audit found no unhandled callsite or
override, and the constructed claims cover the intended issue path plus the
solved-result regression frame.

Classification:
confirm V1.

Decision:
Keep V1 unchanged. A broader rewrite, solver API change, or additional catch
would add unforced behavior and is rejected by the revision discipline.

## Proof-derived findings from `/verify`

No unmet proof obligation produced a concrete counterexample to V1. The proof
package remains `constructed, not machine-checked` because K tooling was not run
under the task constraints.

## Test Guidance

Do not remove tests. Existing solved-relational tests are part of the regression
frame and should be kept unless the K claims are later machine-checked and the
project maintainers choose to treat point tests as redundant. A new regression
test for the reported `ConditionSet` behavior would be useful, but this task
forbids modifying tests.
