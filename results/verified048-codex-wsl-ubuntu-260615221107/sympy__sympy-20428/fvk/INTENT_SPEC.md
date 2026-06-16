# Intent Spec

Status: intent-only, before accepting candidate behavior.

`clear_denoms` is intended to clear denominators while returning a valid dense
polynomial representation. The issue identifies the invalid behavior as an
unstripped dense zero: a polynomial that prints as `Poly(0, x, domain='EX')` but
has `bad_poly.rep == DMP([EX(0)], EX, None)` and `bad_poly.is_zero == False`.

Required behaviors:

1. The returned coefficient is the common denominator multiplier used to clear
   all ground-coefficient denominators.
2. The returned dense polynomial denotes the input polynomial multiplied by that
   coefficient, with optional conversion preserving the same polynomial value.
3. If the multiplication causes any leading coefficient to become exact zero,
   the dense result is stripped to the canonical representation.
4. In the univariate zero case, the canonical dense representation is `[]`.
5. In the recursive multivariate case, stripping must be recursive so an inner
   `[0]` cannot prevent the outer zero test from recognizing a zero coefficient
   polynomial.
6. `Poly.clear_denoms()` must not produce a `DMP` that merely prints as zero
   while reporting `is_zero == False` or breaking dense methods such as
   `terms_gcd()`.

Out of scope:

- Changing the mathematical simplification rules that decide whether an `EX`
  coefficient is zero.
- Changing public method signatures or tuple return shapes.
- Proving termination; the relevant code uses finite list traversal, and this
  audit is a partial-correctness construction only.
