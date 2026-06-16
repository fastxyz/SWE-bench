# Intent Spec

This file records public intent only; candidate implementation behavior is not
used as expected behavior unless independently supported.

1. `simplify(cos(x)**I)` must not raise `TypeError: Invalid comparison of
   complex I` during trigonometric simplification.
2. `_TR56` is an even-integer-power trigonometric identity helper. It should not
   try to apply that identity to exponents that are not known integers.
3. Exponents known negative or known greater than `max` are outside the rewrite
   range and remain unchanged.
4. Exponent `2` rewrites to the base Pythagorean identity; exponent `4` rewrites
   to the square of that identity.
5. With `pow=False`, even integer exponents within `max` may be rewritten and
   odd integer exponents remain unchanged.
6. With `pow=True`, only exponents expressible as powers of two may be
   rewritten. Non-powers of two and undecidable symbolic integer exponents
   remain unchanged.
7. The public wrapper APIs and return category remain compatible.
