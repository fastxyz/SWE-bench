# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Public evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E-1 | prompt / issue | "`PolyElement.as_expr()` not accepting symbols" | Supplied symbols are in-domain API input for `PolyElement.as_expr`. | Encoded by PO-2 and claim `POLY-AS-EXPR-SUPPLIED`. |
| E-2 | prompt / issue | "supposed to let you set the symbols you want to use" | Same-arity supplied symbols must be the symbols used in the returned expression. | Encoded by PO-2. |
| E-3 | prompt / issue | `f.as_expr(U, V, W)` currently prints with `x, y, z` | Pre-fix behavior using `self.ring.symbols` despite supplied `U, V, W` is the bug, not a behavior to preserve. | Finding F-1. |
| E-4 | prompt / issue | "either you pass the wrong number of symbols, and get an error message" | Wrong arity should keep rejecting; exact error wording is not specified. | Encoded by PO-3. |
| E-5 | public tests | `assert f.as_expr() == g` with `X, Y, Z = R.symbols` | No-argument default should use ring symbols. | Encoded by PO-1. |
| E-6 | public tests | `assert f.as_expr(X, Y, Z) == g` where `X, Y, Z = symbols("x,y,z")` | Same-arity positional symbols are accepted. This does not distinguish same-named symbols from ring symbols. | Supports PO-2; coverage gap in F-2. |
| E-7 | implementation | `expr_from_dict(rep, *gens)` zips `gens` with monomial exponents | The symbol tuple passed to `expr_from_dict` determines expression variables positionally. | Encoded by PO-4. |
| E-8 | implementation | `FracElement.as_expr` returns `self.numer.as_expr(*symbols)/self.denom.as_expr(*symbols)` | Fraction conversion depends on `PolyElement.as_expr` preserving forwarded symbols. | Encoded by PO-5. |

No hidden tests, evaluator output, upstream patch, internet source, or external
benchmark data was used.
