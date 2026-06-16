# Baseline Notes

## Root Cause

`Permutation.__new__` delegated several construction paths to the module-level
`_af_new` alias. That alias was bound to `Permutation._af_new`, and `_af_new`
was a staticmethod that called `Basic.__new__(Perm, perm)`. As a result, those
paths always allocated the base `Permutation` class even when `__new__` was
invoked through a subclass.

The same base-class helper was also used by a number of `Permutation` methods
that create new permutation instances from array forms, so subclass instances
could lose their type after common operations.

## Changed Files

`repo/sympy/combinatorics/permutations.py`

- Changed `Permutation._af_new` from a staticmethod to a classmethod and changed
  allocation from `Basic.__new__(Perm, perm)` to `Basic.__new__(cls, perm)`.
- Updated `Permutation.__new__` fast paths to call `cls._af_new(...)` instead
  of the module-level `_af_new` alias.
- When constructing a subclass from an existing `Permutation`, preserved the
  existing object only if it is already an instance of the requested class;
  otherwise a new instance of the requested class is created.
- Updated subclass-sensitive constructors and operations inside `Permutation`
  to use `self._af_new`, `cls._af_new`, or the current class rather than the
  base-class alias.

`reports/baseline_notes.md`

- Added this report to document the root cause, changed files, assumptions, and
  rejected alternatives required by the task.

## Assumptions and Alternatives

- I treated `_af_new` as an internal fast constructor that should preserve the
  class it is called on. This follows the issue hint and matches Python's
  normal classmethod construction pattern.
- I left module-level aliases in other combinatorics modules alone. Those
  aliases are imported from `Permutation._af_new` and intentionally construct
  plain `Permutation` objects for existing group algorithms.
- I considered changing only `Basic.__new__(Perm, perm)` to
  `Basic.__new__(cls, perm)`, but rejected that as incomplete because
  `Permutation.__new__` still called the already-bound module-level helper.
- I considered adding public tests, but the task explicitly prohibits modifying
  test files.
