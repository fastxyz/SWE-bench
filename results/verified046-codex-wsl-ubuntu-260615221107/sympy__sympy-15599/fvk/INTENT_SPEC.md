# Intent Spec

Status: intent-only; current implementation behavior is treated as candidate
behavior, not as expected output.

1. `Mod(3*i, 2)` with `i` integer must simplify on the default construction
   path to `Mod(i, 2)`.
2. `Mod` must retain Python's modulo convention: the remainder has the same
   sign as the divisor.
3. The fix must not simplify `Mod(e/2, 2)` for an even symbol `e` to `0`,
   because `e/2` may be odd.
4. The fix must not disturb float or symbolic-divisor behavior that is outside
   the integer coefficient / plain integer divisor case.
5. The fix must not change public APIs, signatures, dispatch protocols, or
   tests.
