# Proof

Status: constructed, not machine-checked.

## Claims Proved Constructively

The formal core is in:

- `mini-sympy-relational.k`
- `relational-as-set-spec.k`

There are no loops and no recursive functions in the audited fragment, so no
circularity claim is required.

## Function Claim: Relational._eval_as_set

`REL-EVAL-EXACT`:
If the abstract solver outcome is `exact(S)`, the rule for
`relEvalAsSet(rel(X, P, exact(S)))` rewrites in one semantic step to `ret(S)`.
This models the V1 `try` path where `solve_univariate_inequality` returns
normally.

`REL-EVAL-UNSOLVED`:
If the abstract solver outcome is `cannotSolve`, the rule for
`relEvalAsSet(rel(X, P, cannotSolve))` rewrites in one semantic step to
`ret(conditionSet(X, rel(X, P, cannotSolve), reals))`. This models the V1
`except NotImplementedError` path.

## Public Routing Claim: Boolean.as_set

`BOOL-AS-SET-NONPERIODIC-EXACT`:
For a non-periodic univariate relational, `boolAsSet` first rewrites to
`relEvalAsSet`, then the exact solver claim rewrites to `ret(S)`.

`BOOL-AS-SET-NONPERIODIC-UNSOLVED`:
For a non-periodic univariate relational with solver outcome `cannotSolve`,
`boolAsSet` first rewrites to `relEvalAsSet`, then the unsolved solver claim
rewrites to `ret(conditionSet(X, rel(X, nonPeriodic, cannotSolve), reals))`.
This removes the reported `NotImplementedError` observable.

## Regression Argument

V1 touches only the exceptional path after the solver call. The exact path still
returns immediately from `solve_univariate_inequality`; in the model this is
`REL-EVAL-EXACT`. Therefore already-solved relationals keep their exact sets.

The public wrapper path for non-periodic univariate relationals delegates to the
helper both before and after V1. Therefore the wrapper inherits the helper's
exact-result preservation and the new unsolved-result fallback.

## Residual Risk

This is a partial-correctness proof over a small abstract SymPy-relational
semantics, not a full Python or full SymPy semantics. The trusted base is:

- the adequacy of the abstraction in `mini-sympy-relational.k`;
- the K reachability proof system and Haskell backend, if the commands below are
  run later;
- the source-level fact that the reported expression reaches the non-periodic
  univariate `_eval_as_set()` path.

No termination proof is needed for the modeled fragment because it has no loops
or recursion.

## Commands Not Run

The task forbids running K tooling. These are the commands to reproduce the
machine check later:

```sh
cd fvk
kompile mini-sympy-relational.k --backend haskell
kast relational-as-set-spec.k --definition mini-sympy-relational-kompiled --module RELATIONAL-AS-SET-SPEC --sort Claim
kprove relational-as-set-spec.k --definition mini-sympy-relational-kompiled --spec-module RELATIONAL-AS-SET-SPEC
```

Expected result if the constructed claims and syntax are accepted by K:
`kprove` returns `#Top`. Until that command actually returns `#Top`, this proof
is not machine-checked.

## Test-Redundancy Recommendation

No tests should be removed in this task. Existing solved-relational tests are
covered by the regression-frame claims only after machine-checking, and this task
does not allow test edits. A future test for the reported fallback behavior would
be useful but is outside this task's allowed edits.
