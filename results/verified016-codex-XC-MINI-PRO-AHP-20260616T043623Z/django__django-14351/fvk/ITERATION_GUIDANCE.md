# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The audit found the original defect as F-001 and confirmed that V1 discharges
the relevant proof obligations: PO-002 removes non-correlated RHS queries from
group-by contribution, and PO-007 shows that this prevents the reported
multi-column RHS subquery from appearing in `GROUP BY`.

## Why No Additional Code Change

Do not move the fix into `RelatedIn.as_sql()`. F-002 and PO-003 through PO-005
show that the more general `Query.get_group_by_cols()` contract is the right
level: the bug is in group-by dependency reporting for raw nested queries, not
only in rendering related `IN` predicates.

Do not special-case `Lookup.get_group_by_cols()` to drop RHS querysets. That
would satisfy F-001 for non-correlated `IN` lookups but would risk violating
F-002 by hiding legitimate correlated-subquery dependencies.

Do not alter test files. The task forbids it, and F-003 keeps all test-removal
recommendations conditional on a future machine check.

## Recommended Future Checks

When an execution environment exists, run Django's relevant ORM aggregation and
lookup tests plus a regression test for this issue shape. Separately, in a K
environment, run the commands recorded in `fvk/PROOF.md`.

## Next Prompt for a Code Generator

Keep `Query.get_group_by_cols()` aligned with `Subquery.get_group_by_cols()`.
If future review finds another raw-`Query` expression context, verify whether
that context needs the same dependency-only grouping behavior rather than
grouping by the raw subquery expression.
