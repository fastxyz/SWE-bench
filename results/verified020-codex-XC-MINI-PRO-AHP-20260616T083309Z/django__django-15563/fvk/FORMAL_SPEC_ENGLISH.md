# Formal Spec English

Status: constructed, not machine-checked.

## Claim: preSqlSetup

Starting with a queryset primary-key list `PKIDS` and a map `RIDS` from each
related ancestor model to that model's selected parent-link identifier list,
`preSqlSetup(PKIDS, RIDS)` finishes with:

- the primary queryset filter based on `PKIDS`;
- the unchanged model-keyed related identifier map `RIDS`;
- related filters that map every model `M` to `pk__in(RIDS[M])`.

## Claim: getRelatedUpdates

For every model-keyed related identifier map `RIDS`, `getRelatedUpdates(RIDS)`
produces related update filters using each model's own list: model `M` receives
`pk__in(RIDS[M])`.

## Claim: bugDiscriminator

For the issue shape where child/base primary keys are `[1, 2]` and the linked
`OtherBase` parent IDs are `[3, 4]`, the `OtherBase` update filter is `[3, 4]`.
It is not `[1, 2]`.

## Side conditions

- The selected row order is stable across selected columns because all
  identifiers are read from the same pre-update result rows.
- The proof is partial correctness over the update-planning state and does not
  prove database execution or SQL backend semantics.
