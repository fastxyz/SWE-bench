# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F1 - V1 removes the in-domain self-declared incompleteness

Input: `Contains(x, S.Reals).as_set()` with symbolic `x`.

Observed before V1: the issue reports a Boolean `Contains(x, Reals)` result or a non-Set path, which cannot satisfy callers that need Set methods such as `as_relational`.

Expected: a Set representing `{x | Contains(x, S.Reals)}`, which simplifies to `S.Reals`.

V1 status: fixed. `Contains.as_set()` now routes symbolic membership through `ConditionSet(x, Contains(x, set))`, and existing `ConditionSet.__new__` flattens that to `set.intersect(UniversalSet)`, which has `set` as the result.

Linked proof obligations: O1, O2, O5.

## F2 - Existing visible test is SUSPECT legacy behavior

Input: `Contains(x, FiniteSet(y)).as_set()`.

Observed in visible repository test: `repo/sympy/sets/tests/test_contains.py::test_as_set` expects `NotImplementedError`.

Expected from public issue hint: if `x` is a symbol, `Contains(x, set).as_set()` should return `set`; here that means `FiniteSet(y)`.

Classification: SUSPECT legacy-test obligation. The test preserves the exact incompleteness the public issue asks to remove, so it must not veto the intent-derived spec. Per the task instruction, no test files were modified.

Linked proof obligations: O1, O2.

## F3 - Generic Boolean fallback is required and V1 supplies it

Input: any Boolean `P` with exactly one free symbol `x` and no specific `_eval_as_set` implementation.

Observed before V1: `Boolean.as_set()` assumed subclasses supplied `_eval_as_set`; unsupported Boolean subclasses could fail before returning a Set.

Expected: `ConditionSet(x, P)`.

V1 status: fixed for the generic fallback path by `Boolean._eval_as_set()`.

Linked proof obligations: O3.

## F4 - Multivariate Boolean conversion remains intentionally out of scope

Input: a Boolean with more than one free symbol.

Observed: `Boolean.as_set()` still raises `NotImplementedError`.

Expected from public issue hint: multivariate conversion is not implemented and its representation is uncertain.

Classification: not a code bug for this task. The remaining boundary is explicitly acknowledged by the public hint.

Linked proof obligations: O6.

## F5 - Constructed proof is not machine-checked

Input: the FVK K artifacts in `fvk/`.

Observed: K commands were written but not run, as required by the task.

Expected: artifacts must be labeled constructed, not machine-checked, and test removal must remain recommendation-only.

Classification: proof/tooling caveat, not a source-code bug.

Linked proof obligations: O7.
