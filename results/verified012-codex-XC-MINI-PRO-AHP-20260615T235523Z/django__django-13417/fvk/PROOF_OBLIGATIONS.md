# Proof Obligations

Status: constructed, not machine-checked. Each obligation is discharged by the
source audit and the K claims listed below, subject to later `kprove`.

## PO-1 - Intent adequacy of orderedness

Requirement: `QuerySet.ordered` must agree with semantic orderedness of the
query, not merely with the presence of configured model metadata.

Evidence: E1, E2, E3, E5.

Formal claim: `ORDERED-MATCHES-COMPILER`.

Status: discharged by the constructed claim
`ordered(QS:QueryState) => compilerOrdered(QS)`.

## PO-2 - Empty queryset preservation

Requirement: Empty querysets report ordered.

Evidence: E4 and existing property behavior.

Formal class: `isEmpty = true`.

Status: discharged by `ordered(qs(true, ...)) => true`.

## PO-3 - Explicit ordering preservation

Requirement: `extra_order_by` and explicit `order_by` remain ordered, including
when a query is grouped.

Evidence: E4 and E5.

Formal claims: `ORDERED-MATCHES-COMPILER` and
`EXPLICIT-GROUPED-ORDERED`.

Status: discharged; V1 checks explicit ordering before the grouped default
ordering branch.

## PO-4 - Grouped default Meta.ordering suppression

Requirement: Default `Meta.ordering` must not make a grouped aggregate queryset
report ordered.

Evidence: E2, E3, E5, E6.

Formal claim: `GROUPED-META-UNORDERED`.

Status: discharged; V1 adds `not self.query.group_by` to the default-ordering
branch.

## PO-5 - Non-grouped default Meta.ordering preservation

Requirement: Default `Meta.ordering` still reports ordered when no grouping
suppresses it.

Evidence: E4 and E5.

Formal claim: `DEFAULT-NONGROUPED-ORDERED`.

Status: discharged.

## PO-6 - No effective ordering reports unordered

Requirement: A non-empty queryset with no explicit ordering and no effective
default ordering reports unordered.

Evidence: E1 and existing public property semantics.

Formal claim: `NO-EFFECTIVE-ORDERING-UNORDERED`.

Status: discharged.

## PO-7 - Frame and compatibility

Requirement: The fix must not mutate query state or change the public API shape.

Evidence: E7 and source diff.

Formal frame condition: the abstract decision reads `QueryState` and produces a
boolean only.

Status: discharged by source inspection and `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-8 - Honesty gate

Requirement: Because no tests or K tooling were run, all proof conclusions must
remain labeled constructed, not machine-checked; no test deletion is justified.

Evidence: FVK command docs and user no-execution instruction.

Status: discharged by `PROOF.md`, `FINDINGS.md` F4, and
`ITERATION_GUIDANCE.md`.
