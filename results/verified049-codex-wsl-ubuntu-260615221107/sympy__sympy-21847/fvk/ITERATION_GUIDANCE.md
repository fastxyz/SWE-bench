# Iteration Guidance

Status: V2 source changes are complete; no tests or code were executed.

## Decision

Do not keep V1 unchanged. FVK finding F2 exposed an additional boundary violation of the same total-degree contract. V2 keeps the V1 sum-based filter and adds the `min_degree == 0` guard before yielding `S.One` in the early unit-monomial branch.

## Source Changes Justified

- Keep V1 `sum(powers.values()) >= min_degree` in the commutative branch. Justified by F1 and PO-4.
- Keep V1 `sum(powers.values()) >= min_degree` in the non-commutative branch. Justified by F1 and PO-5.
- Add `if min_degree == 0` before yielding `S.One` when `not variables or max_degree == 0`. Justified by F2 and PO-2.

## Suggested Tests for Maintainers

Test files were not modified because the task forbids it. Recommended public tests:

- Integer min/max exact degree: `set(itermonomials([x, y, z], 3, 3))` should include mixed degree-3 monomials.
- Integer min below max: `set(itermonomials([x, y, z], 4, 3))` should include total-degree-3 and total-degree-4 monomials.
- Empty variables with positive minimum: `set(itermonomials([], 2, 1)) == set()`.
- Non-commutative mixed word with total degree meeting the lower bound.

## Residual Risk

The proof is constructed, not machine-checked. The mini-model verifies the total-degree filtering property, not full Python generator mechanics or SymPy expression canonicalization. Keep integration and expression-shape tests until a fuller proof or normal test execution is available.
