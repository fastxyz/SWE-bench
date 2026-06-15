# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Verdict

V1 stands unchanged.

The audit found the operative issue to be shared mutable component query state in
combined queryset clones. V1 addresses that at the correct ownership boundary by
recursively cloning `combined_queries` in `Query.clone()`.

## Code Guidance

No additional source edit is recommended.

Rationale:

- F1 is resolved by PO1-PO4.
- F2 confirms that the existing compiler-local clone is useful but not the
  central ownership contract; V1 supplies that contract.
- F3 and PO5 show no public API or callsite compatibility issue.
- F5 records that no proof obligation exposed a remaining V1 code gap.

## Test Guidance

Do not remove tests. No tests were run in this workspace.

Recommended future regression coverage, to be added only in a normal development
environment:

1. Ordered `union()` queryset remains evaluable after evaluating
   `qs.order_by().values_list('pk', flat=True)`.
2. The same ownership property for nested combined querysets, if Django's
   backend feature gates allow the query shape.
3. Existing combined-query tests should remain until CI confirms backend behavior.

## Formal Verification Guidance

The proof in `fvk/PROOF.md` is constructed but not machine-checked. A future full
FVK pass could encode the abstract `QueryState` model in `mini-query-clone.k` and
the PO1-PO6 claims in `query-clone-spec.k`, then run:

```sh
kompile mini-query-clone.k --backend haskell
kast --backend haskell query-clone-spec.k
kprove query-clone-spec.k
```

Expected result: `#Top` for the ownership claims.

## Residual Risks

The FVK proof is intentionally scoped to ownership of combined query components.
It does not replace Django's backend-specific SQL tests and does not prove every
compiler path. That boundary is recorded as F4 and PO7, not as a reason to change
V1.
