# INTENT_SPEC

Status: intent-only, before accepting candidate behavior as correct.

1. A Cython autowrapped constant expression with an explicit unused
   `MatrixSymbol` argument should return the constant value instead of failing
   during argument conversion.

2. The generated C routine for such a `MatrixSymbol` argument should use a
   pointer argument (`double *x`) rather than a scalar argument (`double x`).

3. Explicit arguments define a requested callable signature even when an
   expression does not reference every argument. The signature must not be
   weakened just because the expression's free-symbol set omits an argument.

4. Matrix argument shape is public metadata carried by `MatrixSymbol`; when the
   argument is explicit and unused, that shape remains available and should be
   used to mark the argument as an array.

5. Scalar redundant arguments remain scalar; the issue does not require all
   redundant arguments to become pointers.

6. An unused unshaped `IndexedBase` has no public shape source in the issue and
   is not part of the required MatrixSymbol fix.

