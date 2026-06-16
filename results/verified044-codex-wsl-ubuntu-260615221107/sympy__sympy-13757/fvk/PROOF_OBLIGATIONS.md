# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Intent adequacy

Claim: The formal claims must express the public issue intent, not the pre-fix behavior.

Evidence: E1-E3; adequacy files `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`.

Discharge: Passed. The pre-fix unevaluated outputs are recorded as symptoms in F-1, not as expected behavior.

## PO-2: Priority delegation

Claim: For ordinary left-hand `Expr` operands and right-hand `Poly`, SymPy multiplication must choose `Poly.__rmul__`.

Required side condition: `Poly._op_priority > Expr._op_priority`.

Evidence: E4-E5.

Discharge: V1 sets `Poly._op_priority = 10.001`, while `Expr._op_priority = 10.0`. This satisfies strict `>`.

Formal claim: `POLY-PRIORITY-ORDINARY-EXPR` and the dispatch step in `POLY-RMUL-X` / `POLY-RMUL-SMINUS2`.

## PO-3: Converted polynomial product

Claim: Once dispatch reaches `Poly.__rmul__`, compatible left operands are converted to `Poly` over the right operand's generators and multiplied as polynomials.

Evidence: E2, E3, E6.

Discharge: `Poly.__rmul__` already performs `g = f.__class__(g, *f.gens)` followed by `g.mul(f)`. V1 makes the method reachable for ordinary left-hand expressions.

Formal claims: `POLY-RMUL-X`, `POLY-RMUL-SMINUS2`.

## PO-4: Fallback preservation

Claim: Incompatible left operands should retain existing expression-level fallback behavior.

Evidence: E6.

Discharge: `Poly.__rmul__` catches `PolynomialError` and returns `g*f.as_expr()`. V1 does not alter this branch.

Formal claim: `POLY-RMUL-FALLBACK`.

## PO-5: Public compatibility of priority value

Claim: The priority value should be high enough to beat ordinary `Expr`, but not needlessly high relative to other public dispatch owners.

Evidence: E7-E8; `PUBLIC_COMPATIBILITY_AUDIT.md`.

Discharge: `10.001` is minimally above `10.0`, below concrete matrix priority `10.01`, and below matrix-expression priority `11.0`. Equal priority with `ImmutableDenseMatrix` does not force delegation because the decorator requires strict `>`.

Formal claim: `POLY-PRIORITY-COMPAT`.

## PO-6: Honesty gate

Claim: The proof artifacts must be labeled constructed, not machine-checked, and no test-removal or source-confidence claim may depend on unrun tooling.

Evidence: FVK `/verify` honesty gate and benchmark no-execution rule.

Discharge: All artifacts carry the constructed/not-machine-checked caveat. No tests were modified or run. No test deletion is recommended.
