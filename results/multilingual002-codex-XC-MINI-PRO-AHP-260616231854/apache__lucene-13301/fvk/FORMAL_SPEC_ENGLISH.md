# Formal Spec, in English

Status: constructed, not machine-checked.

1. `XYPoint.equals` returns true for two `XYPoint` instances exactly when both
   coordinate bit keys compare equal under `Float.compare`. If it returns true,
   the Java hash formula using `Float.hashCode` returns the same value for both
   points.
2. `XYCircle.equals` returns true for two `XYCircle` instances exactly when center
   `x`, center `y`, and `radius` compare equal under `Float.compare`. If it returns
   true, the Java hash formula using `Float.hashCode` returns the same value for
   both circles.
3. `XYRectangle` already uses the same compare-sensitive relation for all four
   float bounds; its existing hash formula is consistent with that relation.
4. `Point.equals` and `Circle.equals` use `Double.compare` for their double fields,
   so signed zero is not equated while `Double.hashCode` remains signed-zero-sensitive.
5. `Rectangle2D.equals` uses `Double.compare` for its four double bounds, so its
   `Objects.hash` result over boxed doubles is consistent when equality is true.
6. The model treats finite floating-point values as canonical hash-relevant bit keys;
   therefore `-0.0` and `+0.0` are distinct keys and a signed-zero mismatch makes
   equality false rather than producing equal objects with unequal hashes.
