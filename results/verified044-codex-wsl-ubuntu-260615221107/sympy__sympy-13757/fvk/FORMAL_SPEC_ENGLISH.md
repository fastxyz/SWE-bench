# Formal Spec in English

Status: constructed, not machine-checked.

The K claims in `poly-dispatch-spec.k` state the following:

1. `POLY-RMUL-X`: For an ordinary expression object representing `x` on the left and `Poly(x, x)` on the right, `dispatchMul` first compares priorities. Because `priority(Poly) = 10001` and `priority(Expr) = 10000`, the right-hand reflected method is selected. `Poly.__rmul__` converts the left expression to a compatible `Poly` over the same generator and returns the polynomial product.

2. `POLY-RMUL-SMINUS2`: For a SymPy integer expression representing `S(-2)` on the left and `Poly(x, x)` on the right, the same priority rule selects `Poly.__rmul__`. The left integer is converted into a compatible constant polynomial and multiplication returns a polynomial product.

3. `POLY-RMUL-FALLBACK`: If a left operand is not convertible to a compatible polynomial over the right-hand `Poly`'s generator, right-hand dispatch still reaches `Poly.__rmul__`, but the method returns the existing expression-level fallback product rather than raising or inventing a polynomial result.

4. `POLY-PRIORITY-ORDINARY-EXPR`: `Poly` priority is strictly greater than ordinary `Expr` priority. This is the side condition needed for the dispatch decorator to choose `Poly.__rmul__`.

5. `POLY-PRIORITY-COMPAT`: `Poly` priority remains no greater than the explicit-matrix priority stratum modeled in the spec. This captures the compatibility intent that V1 should not outrank higher-priority non-ordinary dispatch owners.
