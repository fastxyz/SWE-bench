# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue title | "Multiplying an expression by a Poly does not evaluate when the expression is on the left side of the multiplication" | Right-hand `Poly` must get control for mixed multiplication with ordinary left-hand expressions. | Encoded in `SPEC.md`, `poly-dispatch-spec.k`, PO-1, PO-2. |
| E2 | prompt issue example | `Poly(x)*x -> Poly(x**2, x, domain='ZZ')` and `x*Poly(x) -> x*Poly(x, x, domain='ZZ')` | The expected `x*Poly(x)` result is the evaluated polynomial product, not an unevaluated `Mul`. | Encoded in I3, F-1, PO-3. |
| E3 | prompt issue example | `-2*Poly(x) -> Poly(-2*x, x, domain='ZZ')`, `S(-2)*Poly(x) -> -2*Poly(x, x, domain='ZZ')`, `Poly(x)*S(-2) -> Poly(-2*x, x, domain='ZZ')` | SymPy integers on the left must follow the same polynomial product path as Python ints and right-hand scalar multiplication. | Encoded in I4, F-1, PO-3. |
| E4 | source `repo/sympy/core/expr.py` | `Expr.__mul__` is decorated with `call_highest_priority('__rmul__')`; `Expr._op_priority = 10.0`. | Dispatch depends on the right operand having strictly higher `_op_priority`. | Encoded in PO-2 and the mini K dispatch rule. |
| E5 | source `repo/sympy/core/decorators.py` | `call_highest_priority` calls the other method only when `other._op_priority > self._op_priority`. | Equal priority explains the pre-fix failure; the fix must make `Poly` strictly higher than ordinary `Expr`. | Encoded in PO-2. |
| E6 | source `repo/sympy/polys/polytools.py` | `Poly.__rmul__` tries `Poly(g, *f.gens)` and returns `g.mul(f)`, falling back to `g*f.as_expr()` on `PolynomialError`. | Once reached, `Poly.__rmul__` implements the intended conversion and fallback. | Encoded in PO-3 and PO-4. |
| E7 | public tests in `repo/sympy/polys/tests/test_polytools.py` | Existing public tests assert `1 + Poly(x, x)`, `1 - Poly(x, x)`, and `2 * Poly(x, x)` evaluate through reverse `Poly` arithmetic. | Reverse arithmetic with `Poly` is already public behavior for convertible operands. | Used as supporting evidence for compatibility in PO-5. |
| E8 | source priority survey | Matrix/vector-like classes use `_op_priority` values at or above `10.001`/`10.01`/`11.0`; ordinary `Expr` is `10.0`. | A minimal `Poly` priority above `Expr` but not above matrix expression priority is a compatibility-conscious dispatch change. | Encoded in PO-5 and `PUBLIC_COMPATIBILITY_AUDIT.md`. |
