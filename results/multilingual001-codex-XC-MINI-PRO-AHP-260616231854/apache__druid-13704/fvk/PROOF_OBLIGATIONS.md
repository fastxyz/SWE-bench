# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: `pow` is a known arithmetic operation

- Claim: `Ops.lookup("pow") = POW`.
- Source: `ArithmeticPostAggregator.java:251-264`.
- Evidence: `POW("pow")` is an enum value; the static initializer inserts every `Ops.values()` entry into `LOOKUP_MAP` using `op.getFn()`.
- K claim: `LOOKUP-POW`.

## PO-2: Pairwise `pow` computes Java `Math.pow`

- Claim: for all double values `lhs` and `rhs`, `POW.compute(lhs, rhs) = Math.pow(lhs, rhs)`.
- Source: `ArithmeticPostAggregator.java:251-256`.
- Evidence: the `POW` override directly returns `Math.pow(lhs, rhs)`.
- K claim: `POW-PAIR`.

## PO-3: Arithmetic `compute` folds `pow` left-to-right

- Claim: for non-null numeric field outputs `[d0, d1, ..., dn]` with `n >= 1`, `compute` returns `foldPow([d0, d1, ..., dn])`, where `foldPow([a,b]) = Math.pow(a,b)` and `foldPow([a,b,c,...]) = foldPow([Math.pow(a,b), c, ...])`.
- Source: `ArithmeticPostAggregator.java:110-130`.
- Evidence: `retVal` is initialized from the first field and the loop repeatedly sets `retVal = op.compute(retVal, nextVal.doubleValue())`.
- K claims: `POW-FOLD-TWO`, `POW-FOLD-THREE`.

## PO-4: Existing null propagation applies to `pow`

- Claim: if any field result is `null`, `compute` returns `null` before invoking `POW.compute`.
- Source: `ArithmeticPostAggregator.java:115-127`.
- Evidence: both the first field and each subsequent field are null-checked with immediate `return null`.
- K claim: `POW-NULL`.

## PO-5: `pow` cache keys preserve field order

- Claim: `preserveFieldOrderInCacheKey(POW) = true`, and therefore `getCacheKey` calls `appendCacheables(fields)` instead of `appendCacheablesIgnoringOrder(fields)`.
- Source: `ArithmeticPostAggregator.java:153-164` and `198-211`.
- Evidence: V1 adds `case POW` to the true-returning switch arm.
- K claim: `POW-CACHE-ORDER`.

## PO-6: Existing arithmetic operations are framed unchanged

- Claim: V1 does not change the compute bodies or cache-order classification for `+`, `-`, `*`, `/`, or `quotient`.
- Source: diff only adds `POW` and does not edit existing enum constants.
- Evidence: existing switch arms remain: `PLUS` and `MULT` ignore field order; `MINUS`, `DIV`, and `QUOTIENT` preserve it.
- K claim: represented by unchanged mini-semantics rules for existing operations; proof is a source-diff frame condition.

## PO-7: Public API compatibility is preserved

- Claim: V1 does not change constructor signatures, JSON property names, method signatures, return types, or existing function names.
- Source: `ArithmeticPostAggregator.java`.
- Evidence: only a new enum constant and cache switch arm are added.
- K claim: compatibility is recorded in `PUBLIC_COMPATIBILITY_AUDIT.md`; no K runtime claim is needed.

## PO-8: Adequacy of `pow` spelling

- Claim: the formal contract names only `pow`, not `power`.
- Evidence: issue title/proposal use `pow`; Druid expression docs define `pow(x, y)`; SQL `POWER` maps to expression `"pow"`.
- K claim: `LOOKUP-POW`; `power` is intentionally outside the proven domain.
