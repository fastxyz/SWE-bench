# Formal Spec English

Status: constructed, not machine-checked.

## Claims

`REL-EVAL-EXACT`:
For any univariate relational modeled with an exact solver result `S`,
`Relational._eval_as_set()` returns `S` unchanged.

`REL-EVAL-UNSOLVED`:
For any univariate relational modeled with solver outcome `cannotSolve`,
`Relational._eval_as_set()` returns
`ConditionSet(symbol, original_relational, Reals)`.

`BOOL-AS-SET-NONPERIODIC-EXACT`:
For a non-periodic univariate relational whose solver returns an exact set `S`,
the public `as_set()` routing returns `S`.

`BOOL-AS-SET-NONPERIODIC-UNSOLVED`:
For a non-periodic univariate relational whose solver cannot solve, the public
`as_set()` routing returns `ConditionSet(symbol, original_relational, Reals)`
instead of `NotImplementedError`.

## Frame Conditions

- The solver API is not changed.
- Exact solver results are preserved.
- Multivariate handling and non-trivial periodic handling remain outside this
  fix unless separately implicated.
- The proof is partial correctness only; no termination claim is needed because
  the modeled paths contain no loop or recursion.

## Side Conditions

The fallback applies only to `NotImplementedError` from the solver call in the
univariate relational conversion path. Other exception classes are not converted
by this spec.
