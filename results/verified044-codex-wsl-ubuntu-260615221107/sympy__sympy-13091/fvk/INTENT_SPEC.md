# Intent Spec

Status: constructed from public intent, not from hidden tests.

## Required behavior

I1. When a SymPy rich-comparison method cannot make sense of the other operand, it returns `NotImplemented`, not `False` or an immediate `TypeError`, so Python can try the reflected method on the other operand.

I2. `Basic.__eq__` must return `NotImplemented` both when `_sympify(other)` fails and when the other operand is sympified but remains a different SymPy type. The issue explicitly calls out both branches.

I3. `Basic.__ne__` must preserve the same fallback behavior. If `__eq__` returns `NotImplemented`, `__ne__` must also return `NotImplemented`.

I4. Ordering comparisons on normal SymPy expressions (`<`, `<=`, `>`, `>=`) must also return `NotImplemented` for unsupported unsympifiable operands, so reflected ordering methods can run.

I5. Core numeric classes that override `Basic` or `Expr` comparison methods must not bypass I1-I4. Unsupported operands in those overrides must return `NotImplemented`, and numeric `__ne__` methods must preserve it.

I6. Definite existing numeric comparisons remain definite. The issue asks for fallback on unknown/unsupported operands, not for changing known numeric equality or ordering.

I7. Numeric singleton equality (`oo`, `-oo`, `nan`) must preserve its existing identity/known-number behavior while returning `NotImplemented` only for unsupported non-number operands. V1's added sympification inside these identity equality methods was not required by public intent.

I8. Invalid comparisons that SymPy already recognizes after sympification, such as complex or NaN ordering, remain invalid comparison errors. The fallback rule is for unknown operands, not for in-domain invalid relational mathematics.

I9. Public method signatures and return categories must remain compatible: no new parameters, no changed public call shapes, and no test-file edits.

## Out of scope

O1. A package-wide cleanup of every specialized comparison method is not required by the issue. The public hint says it may be a bonus; it does not impose a complete package refactor.

O2. Machine-checking the K artifacts is out of scope in this environment. All proof text is constructed, not machine-checked.
