# Formal Spec English

1. For all integers `C`, `Q`, and `T` with `Q != 0`, replacing the dividend
   `C*T` by `(C % Q)*T` preserves its value modulo `Q`.
2. With `C = 3` and `Q = 2`, the coefficient reducer returns a `Mod` expression
   with dividend `T` and divisor `2`.
3. If the extracted coefficient is not integer, the coefficient reducer does
   nothing.
4. If the divisor has a remaining symbolic factor after coefficient extraction,
   the coefficient reducer does nothing.
5. If the dividend tail is not known integer, the coefficient reducer does
   nothing.
