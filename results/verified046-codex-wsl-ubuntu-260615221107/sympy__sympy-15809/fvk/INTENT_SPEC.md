# Intent Spec

Status: constructed from public evidence only, before accepting candidate
implementation behavior as the expected result.

## Required Behaviors

1. `Min()` with zero arguments must return SymPy positive infinity, written
   `oo`.
   - Source: `benchmark/PROBLEM.md`
   - Evidence: "have them return `oo`"
   - Classification: intent-derived postcondition for the empty-input boundary
     case.

2. `Max()` with zero arguments must return SymPy negative infinity, written
   `-oo`.
   - Source: `benchmark/PROBLEM.md`
   - Evidence: "and `-oo`, respectively"
   - Classification: intent-derived postcondition for the empty-input boundary
     case.

3. The empty-input results are mathematical lattice identities over extended
   real numbers, not unevaluated empty `Min` or `Max` expressions.
   - Source: `benchmark/PROBLEM.md` plus the local `LatticeOp` API contract.
   - Evidence: the issue cites extended-real empty-set identities; `LatticeOp`
     documents an identity element for lattice operations.
   - Classification: intent-derived/default-domain boundary convention.

4. Non-empty `Min` and `Max` behavior should be preserved except where ordinary
   identity filtering already applies.
   - Source: class docstrings and public API names in
     `sympy/functions/elementary/miscellaneous.py`.
   - Evidence: `Min` finds minimum values and `Max` finds maximum values; the
     issue names only the zero-argument error.
   - Classification: frame condition over existing intended public behavior.

5. Existing public tests that assert `raises(ValueError, lambda: Min())` or
   `raises(ValueError, lambda: Max())` encode the behavior the issue identifies
   as the bug.
   - Source: `repo/sympy/functions/elementary/tests/test_miscellaneous.py`
   - Classification: SUSPECT legacy-test evidence; not an oracle for the
     expected behavior.

