# Intent Spec

Status: intent-only; current implementation is treated as a candidate, not as
the specification.

1. Unicode pretty printing must render trailing digit subscripts on actual
   Greek-letter symbol names, e.g. `ω0` should display as `ω₀`.
2. Greek-letter symbol names must not be treated worse than Latin names for the
   existing implicit trailing-digit convention.
3. The implicit trailing-digit convention must continue to support ASCII
   letter names with multi-digit suffixes, e.g. `x10` has suffix `10`.
4. Explicit `_`, `^`, and `__` separator behavior remains in scope and should
   not change.
5. No public function signature or return shape should change.
