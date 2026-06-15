# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Decision

V1 stands unchanged.

## Trace To Findings And Proof Obligations

The audit confirmed the original V1 diagnosis. FINDING F1 and PO1/PO2 show that `split_exclude()` introduces an extra generated query level and that a user `OuterRef('pk')` must therefore be shifted from one outer-reference level to two before the generated query resolves it. The current V1 source does exactly that with `OuterRef(filter_rhs)`.

I did not change `OuterRef.resolve_expression()`. FINDING F4 and PO1 show that the existing nested-`OuterRef` semantics are needed: `OuterRef(OuterRef('pk'))` loses one wrapper per resolution pass, which is precisely how the reference survives until the enclosing `Number` query.

I did not change `Query.resolve_expression()` or generic lookup resolution. FINDING F4 and PO2 localize the bad V0 behavior to `split_exclude()` failing to compensate for the query level it adds; changing shared subquery resolution would be broader than the demonstrated defect.

I did not alter the plain `F()` branch. FINDING F2 and PO3 require preserving the existing behavior for local `F()` values, and the V1 edit leaves `elif isinstance(filter_rhs, F): filter_expr = (filter_lhs, OuterRef(filter_rhs.name))` intact.

I did not add compatibility changes. FINDING F3, PO4, and PO5 show non-expression RHS values and the `split_exclude()` method signature remain unchanged.

## Residual Risk

FINDING F5 and PO6 record the deliberate abstraction boundary: the FVK model proves the reference-scope property, not full SQL generation or database execution. FINDING F6 records that all verification is constructed only; test removal and machine-checked confidence require running the emitted commands and Django tests in a real execution environment.

