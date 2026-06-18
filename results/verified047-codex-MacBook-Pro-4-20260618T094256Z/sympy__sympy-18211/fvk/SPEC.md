# Relational as_set Specification

Status: constructed, not machine-checked.

## Scope

This FVK package audits the V1 fix for the reported public behavior:
`Eq(n*cos(n) - 3*sin(n), 0).as_set()` should return an unevaluated real
`ConditionSet` instead of raising `NotImplementedError`.

The functions under audit are:

- `Relational._eval_as_set()` in `repo/sympy/core/relational.py`
- the non-periodic univariate routing path of `Boolean.as_set()` in
  `repo/sympy/logic/boolalg.py`

There are no loops or recursive calls in the changed function.

## Developer Spec

For any univariate relational `R` with one free symbol `x`:

- If `solve_univariate_inequality(R, x, relational=False)` returns a set `S`,
  `_eval_as_set()` returns `S`.
- If that solver raises `NotImplementedError`, `_eval_as_set()` returns
  `ConditionSet(x, R, S.Reals)`.
- For a non-periodic univariate relational, `Boolean.as_set()` delegates to
  `_eval_as_set()`, so the public observable result is the same set.

## Public Evidence Mirror

- E1/E2/E3 from `benchmark/PROBLEM.md` establish the bug and expected
  `ConditionSet(..., Reals)` fallback.
- E4 from the public hint identifies the intended repair boundary.
- E5 from `Boolean.as_set()` documentation establishes real-set conversion.
- E6 from `solve_univariate_inequality` documentation establishes that
  `NotImplementedError` is an expected solver limitation signal.
- E7 from existing public tests establishes the regression frame for exact
  solved relationals.
- E8 from implementation control flow establishes unchanged out-of-scope paths:
  multivariate expressions and non-trivial periodic relationals.

## K Model Summary

`mini-sympy-relational.k` models a relation by:

- its single symbol;
- its periodicity class for the `Boolean.as_set()` routing decision;
- the abstract solver outcome: either `exact(Set)` or `cannotSolve`.

The observable result is either `ret(Set)` or `raisesNotImplemented`. This is
enough to distinguish V0's failure from V1's intended result and to preserve the
exact-solver regression frame.
