# Baseline Notes

## Root cause

`Min` and `Max` share construction through `MinMaxBase.__new__` in
`sympy/functions/elementary/miscellaneous.py`. That constructor had an explicit
empty-argument guard that raised `ValueError` before the normal lattice
identity handling could run. The subclasses already define the desired
identities:

- `Max.identity = S.NegativeInfinity`
- `Min.identity = S.Infinity`

Because of the early guard, `Max()` and `Min()` never reached the existing
`if not args: return cls.identity` path used after filtering.

## Files changed

- `repo/sympy/functions/elementary/miscellaneous.py`: changed the
  zero-argument branch in `MinMaxBase.__new__` to return `cls.identity` instead
  of raising. This makes `Max()` return `-oo` and `Min()` return `oo` while
  preserving all existing argument filtering, short-circuiting, and
  simplification behavior for non-empty calls.

## Assumptions and rejected alternatives

- I assumed the issue requests the empty-argument result to be the algebraic
  identity for each operation, not a new unevaluated empty `Min` or `Max`
  expression. This matches the existing `LatticeOp` convention in SymPy and the
  identities already declared on the subclasses.
- I considered removing the empty-argument guard entirely. That would also let
  the later `if not args: return cls.identity` branch handle the case, but the
  explicit return is smaller and keeps the constructor intent clear.
- I rejected adding special cases to `Min` and `Max` separately because the
  behavior is common to both and their identities are already encoded by the
  subclasses.
- I did not modify tests because the task explicitly forbids editing test
  files. I also did not run tests or project code because this benchmark session
  explicitly forbids execution.
