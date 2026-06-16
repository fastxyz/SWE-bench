# Findings

Status: constructed, not machine-checked.

## F-001: Pre-fix raw RHS Query appears in GROUP BY

Classification: code bug, resolved by V1.

Evidence: The issue shows `GROUP BY ..., (SELECT U0."id", U0."created", ... )`
for `Q(agent__property_groups__in=property_groups) | Q(...__count=0)`, while
the `HAVING` predicate itself uses `IN (SELECT U0."id" ...)`.

Concrete input shape: an annotated queryset filtered by an `OR` between
`related_m2m__in=<non-correlated queryset with default columns>` and an
aggregate count predicate.

Observed before V1: the RHS queryset is added as a grouped expression and
compiles with all default columns, causing PostgreSQL to reject the subquery.

Expected: the RHS queryset should not be grouped as a raw expression when it has
no external-column dependencies; only the related LHS column needs to be added
from that lookup branch.

Resolution: V1 discharges PO-002 and PO-007. No additional code change is
required.

## F-002: Correlated subquery behavior must not be weakened

Classification: compatibility risk, audited and resolved by V1.

Evidence: `Subquery.get_group_by_cols()` preserves scalar external columns and
falls back to grouping by the subquery itself for possibly multivalued external
columns. A raw `Query` used as a lookup RHS should not lose those dependency
signals.

Concrete input shape: a nested queryset containing `OuterRef()` or another
resolved external column reference.

Observed before V1: raw `Query` had no custom grouping contract and inherited
the default expression behavior. That was too broad for non-correlated queries.

Expected: raw `Query` should mirror `Subquery`'s dependency behavior.

Resolution: V1 discharges PO-003, PO-004, and PO-005 by copying the `Subquery`
dependency contract. No additional source edit is required.

## F-003: Formal proof is not machine-checked in this environment

Classification: proof capability gap, not a code bug.

Evidence: The task explicitly forbids running K tooling such as `kompile` or
`kprove`.

Observed: the proof can only be constructed and reviewed statically.

Expected: artifacts must record exact commands and label the proof constructed,
not machine-checked.

Resolution: PO-008 is discharged by `SPEC.md` and `PROOF.md`. Keep all existing
tests; no test deletion is recommended without a future machine check.

## F-004: No new production-code issue found during FVK audit

Classification: confirmation finding.

Evidence: PO-001 through PO-007 cover the full public-intent slice surfaced by
the issue: the bad `GROUP BY` contributor, the valid `HAVING` predicate shape,
the related non-correlated RHS queryset case, and the correlated-query
compatibility frame.

Observed after V1 by static proof: the reported non-correlated RHS contributes
`[]` to group-by collection, while correlated and alias cases preserve the
existing dependency contract.

Expected: V1 stands unchanged.

Resolution: no source changes beyond V1.
