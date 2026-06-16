# Intent Specification

Status: intent-only, written before using V1 behavior as the expected result.

1. The reported substitution with real `x`, `y`, and `z`:

   ```python
   exp(sinh(Piecewise((x, y > x), (y, True)) / z)).subs({1: 1.0})
   ```

   must not raise `PolynomialError` from `Piecewise` polynomial conversion.

2. The direct modulo reproducer:

   ```python
   (Piecewise((x, y > x), (y, True)) / z) % 1
   ```

   must not raise `PolynomialError` from the optional `Mod` simplification path.

3. `Mod` may return an unevaluated symbolic modulo expression when it cannot
   determine a concrete remainder or safe simplification.

4. Existing successful `Mod` simplifications should be preserved.

5. The repair must not hide real modulo errors such as modulo by zero.

6. This issue does not commit a full branchwise polynomial `gcd` semantics for
   `Piecewise`, and it does not commit a global redesign of old-assumption cache
   rollback.

