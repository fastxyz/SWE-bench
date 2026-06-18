# Public Compatibility Audit

Status: pass for the V1 change.

## Changed Symbol

`sympy.solvers.diophantine.diophantine`

The public signature remains:

`diophantine(eq, param=symbols("t", integer=True), syms=None, permute=False)`

V1 changes only an internal recursive call from `diophantine(eq, param)` to
`diophantine(eq, param, permute=permute)`.

## Callers And Consumers

`repo/sympy/sets/handlers/intersection.py` calls
`diophantine(fn - gm, syms=(n, m))`. It does not pass `permute`, so the default
`False` is forwarded in V1 and the result shape remains a set of tuples.

`repo/sympy/solvers/diophantine.py` contains internal calls without `syms` in
other solver helpers. V1 does not alter those call signatures or argument
orders.

There are no public subclass overrides because `diophantine` is a module-level
function, not a virtual method.

## Compatibility Result

No public callsite needs an update. V1 does not add a required argument, remove
an argument, change a return type, or change a producer/consumer protocol. The
only affected behavior is the intended one: reordered `syms` calls now preserve
the caller's existing `permute` flag during the internal recursive solve.
