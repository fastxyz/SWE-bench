# FVK Specification

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or `kprove` were run.

## Scope

Target under audit: V1 change in `repo/sympy/polys/polytools.py`, adding `_op_priority = 10.001` to `Poly`.

Behavior under audit: mixed multiplication where a SymPy expression or SymPy integer is on the left and a compatible `Poly` is on the right.

## Public intent ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E3: the issue requires `x*Poly(x)` and `S(-2)*Poly(x)` to evaluate to polynomial products, matching the already-working mirrored examples.
- E4-E5: SymPy's dispatch decorator delegates to the right-hand operand only when the right-hand operand has strictly higher `_op_priority`.
- E6: `Poly.__rmul__` already implements the needed conversion and fallback once dispatch reaches it.
- E7-E8: reverse `Poly` arithmetic is already public behavior for scalar operands, and the chosen priority is narrowly above ordinary `Expr`.

## Intent-derived contract

For every ordinary left operand `lhs` that is convertible to a `Poly` over the right operand's generators, and every right operand `rhs` that is a `Poly`, default multiplication `lhs * rhs` must dispatch to `Poly.__rmul__` and return the same polynomial multiplication result as `Poly(lhs, *rhs.gens).mul(rhs)`.

Required concrete instances:

- `x*Poly(x)` returns the evaluated polynomial product represented by `Poly(x**2, x, domain='ZZ')`.
- `S(-2)*Poly(x)` returns the evaluated polynomial product represented by `Poly(-2*x, x, domain='ZZ')`.

Fallback condition:

- If `lhs` cannot be converted to a compatible `Poly`, `Poly.__rmul__` must preserve its existing expression fallback rather than forcing a polynomial result.

Compatibility condition:

- The fix must raise `Poly` above ordinary `Expr` dispatch priority, but should not outrank higher-priority dispatch owners such as matrix-like expression classes.

## Formal model

`fvk/mini-sympy-dispatch.k` models only the property-relevant fragment:

- ordinary expression objects with priority `10000`;
- `Poly` objects with priority `10001`;
- higher-priority matrix-like objects with priority `10010`;
- `dispatchMul(lhs, rhs)`, the part of `Expr.__mul__` governed by `call_highest_priority('__rmul__')`;
- `polyRmul(poly, lhs)`, the part of `Poly.__rmul__` that converts compatible operands and falls back to expression multiplication otherwise.

`fvk/poly-dispatch-spec.k` contains the reachability claims:

- `POLY-RMUL-X`: `dispatchMul(Expr(x), Poly(x, gx))` reaches `PolyProduct(Poly(x, gx), Poly(x, gx))`.
- `POLY-RMUL-SMINUS2`: `dispatchMul(SymInt(sminus2), Poly(x, gx))` reaches `PolyProduct(Poly(sminus2, gx), Poly(x, gx))`.
- `POLY-RMUL-FALLBACK`: incompatible left operands reach the expression fallback.
- `POLY-PRIORITY-ORDINARY-EXPR`: `priority(Poly) > priority(Expr)`.
- `POLY-PRIORITY-COMPAT`: `priority(Poly) <= priority(MatrixLike)`.

The model abstracts polynomial coefficient algebra: it proves the dispatch reaches polynomial multiplication with converted operands, while trusting SymPy's existing `Poly.mul` implementation for the algebraic product. That is adequate for this issue because the reported defect is dispatch asymmetry, not polynomial multiplication correctness.

## Adequacy

The adequacy round trip is recorded in:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

All formal claims pass the intent audit. The compatibility claim is intentionally narrower than a whole-repository proof and remains a residual risk until machine checking and tests are run outside this no-execution session.
