# Intent Specification

Status: constructed from public evidence, not machine-checked.

## Required behavior

I1. Mixed multiplication with a right-hand `Poly` must be symmetric with the already-working left-hand `Poly` cases when the left operand can be represented as a polynomial over the right operand's generators.

I2. The default multiplication path must evaluate the result directly. The issue examples show bare REPL multiplication expressions, not `.expand()`, `.simplify()`, or another opt-in transform.

I3. For `Poly(x)` and expression `x`, the result of `x*Poly(x)` is `Poly(x**2, x, domain='ZZ')`, matching `Poly(x)*x`.

I4. For `Poly(x)` and SymPy integer `S(-2)`, the result of `S(-2)*Poly(x)` is `Poly(-2*x, x, domain='ZZ')`, matching `Poly(x)*S(-2)` and plain Python `-2*Poly(x)`.

I5. If the left operand cannot be converted to a compatible `Poly`, the existing `Poly.__rmul__` fallback to expression multiplication should be preserved rather than raising or forcing a polynomial result.

I6. The change must not edit tests and must preserve public dispatch compatibility for higher-priority non-ordinary expression objects.

## Observed candidate behavior to check

V1 adds `_op_priority = 10.001` to `Poly`. This is candidate behavior, not intent by itself. It is checked against I1-I6 in the proof obligations and compatibility audit.
