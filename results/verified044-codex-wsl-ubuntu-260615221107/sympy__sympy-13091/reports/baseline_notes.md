# Baseline Notes

## Root cause

`Basic.__eq__` returned `False` when the right-hand operand could not be
sympified, and also when sympification succeeded but the two SymPy object
types still differed. In Python rich comparison methods, returning `False`
means "definitely unequal" and stops dispatch. For unknown or unsupported
operand types, the method should return `NotImplemented` so Python can try the
reflected comparison method on the other object.

`Basic.__ne__` also directly negated `self.__eq__(other)`, which would have
turned a new `NotImplemented` result into `False` instead of preserving the
rich-comparison fallback.

The same fallback problem existed in the core ordering methods on `Expr` and
in the core numeric comparison overrides in `numbers.py`: unsympifiable
operands raised `TypeError` or returned `False` before Python could delegate to
the reflected comparison method.

## Files changed

`repo/sympy/core/basic.py`

- Changed the unsupported branches in `Basic.__eq__` from `False` to
  `NotImplemented`.
- Updated `Basic.__ne__` to return `NotImplemented` when `__eq__` does, rather
  than negating it.

`repo/sympy/core/expr.py`

- Changed `Expr.__lt__`, `Expr.__le__`, `Expr.__gt__`, and `Expr.__ge__` to
  return `NotImplemented` when `_sympify(other)` fails. Existing `TypeError`
  behavior for successfully sympified invalid comparisons, such as complex and
  NaN ordering, was left intact.

`repo/sympy/core/numbers.py`

- Applied the same `NotImplemented` fallback to core numeric comparison
  overrides, including `Float`, `Rational`, `Integer`, infinities, `NaN`, and
  `NumberSymbol`, so numeric SymPy objects do not bypass the fixed `Basic` and
  `Expr` behavior.
- Updated numeric `__ne__` implementations that negated `__eq__` so they
  preserve `NotImplemented`.
- Kept existing definitive numeric results, such as numeric equality and
  inequality among known SymPy numbers, unchanged.

## Assumptions and rejected alternatives

- I treated the issue as applying to normal SymPy core objects, not only the
  exact `Basic.__eq__` line mentioned in the issue. Changing only that line
  would leave mismatched SymPy subclasses, `!=`, ordering, and numeric atoms
  with the same non-delegating behavior.
- I did not modify non-core domain-specific classes that define their own
  comparisons. The issue and hints point to `Basic` and rich comparison
  behavior for ordinary SymPy objects; changing unrelated algebra, geometry, or
  matrix comparison semantics would be a broader refactor.
- I left comparisons that SymPy can evaluate definitively as boolean results.
  `NotImplemented` is used only when the operand is unsupported or outside the
  method's comparison domain.
- I did not add or modify tests, and I did not run tests or execute project
  code, per the task instructions.
