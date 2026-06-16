# Constructed Proof

Status: constructed, not machine-checked. No commands in this file were executed.

## What is proved

For ordinary left-hand SymPy expressions that are convertible to a polynomial over the right-hand `Poly`'s generators, V1 makes default multiplication dispatch to `Poly.__rmul__`, and `Poly.__rmul__` returns the polynomial product. This covers the reported cases `x*Poly(x)` and `S(-2)*Poly(x)`.

For non-convertible left operands, the existing expression fallback in `Poly.__rmul__` is preserved.

## Symbolic execution sketch

1. Start with `dispatchMul(L, P)` where `L` is an ordinary expression or SymPy integer expression and `P` is `Poly(x, gx)`.
2. `dispatchMul` evaluates the modeled `call_highest_priority('__rmul__')` condition.
3. By PO-2, `priority(P) = 10001` and `priority(L) = 10000`, so `priority(P) > priority(L)`.
4. The dispatch rule rewrites `dispatchMul(L, P)` to `polyRmul(P, L)`.
5. For `L = Expr(x)`, `canPoly(L, gx)` is true and `asPoly(L, gx) = Poly(x, gx)`; `polyRmul` rewrites to `PolyProduct(Poly(x, gx), Poly(x, gx))`.
6. For `L = SymInt(sminus2)`, `canPoly(L, gx)` is true and `asPoly(L, gx) = Poly(sminus2, gx)`; `polyRmul` rewrites to `PolyProduct(Poly(sminus2, gx), Poly(x, gx))`.
7. For `L = Expr(nonpoly)`, `canPoly(L, gx)` is false; `polyRmul` rewrites to `ExprProduct(L, P)`, preserving fallback.

There are no loops or recursion in the modeled dispatch fragment, so no circularity claim is required. The proof is direct symbolic rewriting plus first-order priority comparisons.

## Adequacy check

The English paraphrase of the formal claims is in `FORMAL_SPEC_ENGLISH.md`; the claim-by-claim adequacy audit is in `SPEC_AUDIT.md`. All intent-required claims pass. The compatibility claim remains a bounded abstraction over the relevant priority strata, not a whole-repository machine proof.

## Machine-check commands for later

These commands are intentionally recorded only; they were not run in this session.

```sh
kompile fvk/mini-sympy-dispatch.k --backend haskell
kast --backend haskell fvk/poly-dispatch-spec.k
kprove fvk/poly-dispatch-spec.k
```

Expected result: `kprove` discharges the claims to `#Top`.

## Test redundancy recommendation

No test deletion is recommended. The proof is not machine-checked, and this benchmark forbids test edits. In ordinary development, add or keep tests for `x*Poly(x)`, `S(-2)*Poly(x)`, and a non-convertible fallback case until the K proof is machine-checked and the normal SymPy suite passes.

## Residual risk

The mini K semantics abstracts away Python's full data model and SymPy's entire class hierarchy. It is property-complete for the audited defect axis: priority-based selection of `Poly.__rmul__` and conversion/fallback inside that method. It does not prove polynomial algebra correctness, termination, performance, or all interactions with every higher-priority SymPy class.
