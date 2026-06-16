# Public Evidence Ledger

Status: constructed from allowed public inputs only.

| ID | Evidence | Obligation |
| --- | --- | --- |
| E1 | "Unexpected `PolynomialError` when using simple `subs()`" | The reported `subs` operation should not raise this exception. |
| E2 | "`(Piecewise((x, y > x), (y, True)) / z) % 1`" followed by "`PolynomialError`" and "That should be fixed." | Direct `Mod` construction with this `Piecewise` input should not leak the polynomial exception. |
| E3 | "Some functions call `Mod` when evaluated... calling `gcd` will lead to `PolynomialError`. That error should be caught..." | The correct repair edge is `Mod.eval`'s optional `gcd` call. |
| E4 | `Mod` docstring example `x**2 % y` returns `Mod(x**2, y)`. | Symbolic unevaluated `Mod` is a normal result when concrete evaluation is not possible. |
| E5 | Code comment "extract gcd; any further simplification should be done by the user" | Common-factor extraction is simplification, not required failure behavior. |
| E6 | Traceback reaches `sympy/core/mod.py`, `G = gcd(p, q)`. | The source of the observed exception is localized to the `gcd` extraction block. |
| E7 | Existing code raises `ZeroDivisionError("Modulo by zero")` before the `gcd` block. | Legitimate modulo-by-zero errors must be preserved. |
| E8 | Branchwise `gcd(Piecewise(...), x)` is discussed as "potential new behavior" and the two-`Piecewise` case "gets messier". | Do not treat branchwise `gcd` as a settled requirement for this patch. |
| E9 | Assumptions-cache `None` behavior is identified as separate and changing it causes many `RecursionError` examples. | Do not replace the localized `Mod` repair with a broad assumptions-cache rewrite. |

