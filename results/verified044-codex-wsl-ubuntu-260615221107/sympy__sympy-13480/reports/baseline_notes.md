## Root cause

`coth.eval` handles additive arguments by peeling off an imaginary-period
multiple with `_peeloff_ipi(arg)`. In that branch it computes `cothm = coth(m)`,
but then tested `cotm` instead of `cothm`. Since `cotm` is not defined, inputs
that reach this branch raise `NameError` during substitution/evaluation instead
of simplifying according to the periodic part.

## Files changed

`repo/sympy/functions/elementary/hyperbolic.py`

- Corrected the typo in `coth.eval` so the branch tests the computed `cothm`
  value against `S.ComplexInfinity`.
- Left the surrounding simplification logic unchanged, matching the neighboring
  `tanh.eval` implementation pattern.

## Assumptions and alternatives considered

- Assumed the public hint identifies the intended fix because the local code
  computes `cothm` immediately before the failing condition and there is no
  `cotm` binding in scope.
- Considered whether the branch should call the trigonometric `cot` function
  instead, but rejected that interpretation because this is the hyperbolic
  cotangent periodic-offset branch and the neighboring `tanh` logic tests the
  value it just computed.
- Did not modify tests because the task explicitly fixes the hidden test suite
  and forbids editing test files.
