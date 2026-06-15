# Intent Spec

This intent-only spec is derived from `benchmark/PROBLEM.md`, public hints, and
source comments/docstrings. It does not treat V1 behavior as expected merely
because V1 implements it.

1. `Quantity.__array_ufunc__` must not treat every object with a `unit`
   attribute as Astropy Quantity-like.
2. For unrecognized unit-bearing duck arrays, `Quantity.__array_ufunc__` must
   return `NotImplemented` early enough for NumPy/reflected duck-array dispatch.
3. The early return must happen before converter application, because converter
   application to the duck object is the reported failure.
4. Quantity, ndarray subclasses, and table Columns must continue to work through
   the existing Quantity path.
5. Plain non-unit objects must not be newly rejected by the guard.
6. The check should include possible `out` values as well as inputs.

