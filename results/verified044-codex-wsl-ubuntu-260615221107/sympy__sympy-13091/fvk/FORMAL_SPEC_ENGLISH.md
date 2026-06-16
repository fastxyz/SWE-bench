# Formal Spec English

Status: constructed, not machine-checked.

## C1

If `Basic.__eq__` receives an operand that cannot be sympified, it returns `NotImplemented`.

## C2

If `Basic.__eq__` sympifies the operand but the result has a different SymPy type than `self`, it returns `NotImplemented`.

## C3

If `Basic.__ne__` calls `Basic.__eq__` and receives `NotImplemented`, it returns `NotImplemented`.

## C4

Python equality dispatch with a left result of `NotImplemented` uses the right reflected result when that result is a boolean.

## C5

Python equality dispatch with both sides returning `NotImplemented` yields final `False`.

## C6

If an `Expr` ordering comparison cannot sympify the other operand, it returns `NotImplemented`.

## C7

If an `Expr` ordering comparison successfully sympifies the other operand and then recognizes a complex or NaN invalid comparison, it still raises the invalid-comparison category rather than returning `NotImplemented`.

## C8

Core numeric equality and ordering overrides return `NotImplemented` for unsupported operands and preserve `NotImplemented` through `__ne__`.

## C9

Core numeric singleton equality returns `True` for the same singleton, `False` for a different known SymPy number, and `NotImplemented` for unsupported non-number operands.

## C10

No public comparison method signature changes.
