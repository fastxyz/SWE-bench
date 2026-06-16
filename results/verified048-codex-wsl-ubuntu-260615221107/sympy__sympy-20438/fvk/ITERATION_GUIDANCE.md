# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 did not fully stand unchanged. FVK finding F2 exposed an exception path in
the new subset handler: known-finite product sets can still fail enumeration in
symbolic/undecidable cases. V2 keeps the V1 design but catches `TypeError` and
`ValueError` around finite-product enumeration and returns `None`.

The V1 equality handlers stand. They are justified by PO5 and finding F3:
cross-type equality between a `ProductSet` and a `FiniteSet` should resolve by
mutual subsethood for the issue's equivalent finite sets.

## Suggested Public Tests For A Later Test-Enabled Environment

Do not add tests in this benchmark task. In a normal development environment,
add tests covering:

- `ProductSet(FiniteSet(1, 2), FiniteSet(1, 2)).is_subset(FiniteSet((1, 1), (1, 2), (2, 1), (2, 2))) is True`
- `ProductSet(FiniteSet(1, 2), FiniteSet(1, 2)).is_subset(FiniteSet((1, 1))) is False`
- `ProductSet(S.Integers, FiniteSet(1)).is_subset(FiniteSet((1, 1))) is False`
- A symbolic/undecidable finite-product enumeration case returns `None` rather than raising.
- `Eq(ProductSet(FiniteSet(1, 2), FiniteSet(1, 2)), FiniteSet((1, 1), (1, 2), (2, 1), (2, 2)))` resolves to true.

## Machine-Checking Guidance

When a K environment is available, run the commands recorded in
`fvk/PROOF.md`. Treat any non-`#Top` result as a proof-derived finding and
revise either the abstract semantics or the code/spec accordingly.

## Remaining Risks

- The proof is over an abstract mini semantics, not full SymPy execution.
- No runtime validation was performed because the task forbids execution.
- The handler may enumerate very large finite products; this follows existing
  iterable-set behavior and is outside the public issue's correctness claim.

