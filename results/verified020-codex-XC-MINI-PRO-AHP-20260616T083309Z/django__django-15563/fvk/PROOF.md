# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
command was executed.

## Claims

The proof is over the abstract update-planning semantics in
`mini-update-planner.k` and the claims in `update-related-ids-spec.k`.

1. `preSqlSetup(PKIDS, RIDS)` reaches a state whose primary filter uses `PKIDS`
   and whose related filters use `RIDS[M]` for every model `M`.
2. `getRelatedUpdates(RIDS)` reaches related filters that use `RIDS[M]` for every
   model `M`.
3. The bug discriminator with child/base primary keys `[1, 2]` and `OtherBase`
   parent-link IDs `[3, 4]` reaches an `OtherBase` filter of `[3, 4]`.

## Proof sketch

### preSqlSetup claim

Symbolic execution applies the `preSqlSetup` rule once:

`preSqlSetup(PKIDS, RIDS) => done(PKIDS, RIDS, makeFilters(RIDS))`.

The frame is empty in the mini semantics, so the post-state preserves `PKIDS` and
`RIDS` exactly. By the definition of `makeFilters`, every model key in `RIDS`
maps to the same identifier list in the related filter map. This discharges PO1,
PO3, PO4, and PO5 at the update-planning abstraction level.

### getRelatedUpdates claim

Symbolic execution applies the `getRelatedUpdates` rule once:

`getRelatedUpdates(RIDS) => relatedDone(makeFilters(RIDS))`.

The `makeFilters` definition gives `RELATED_FILTERS[M] = RIDS[M]` for every model
key. In the source, this corresponds to
`query.add_filter("pk__in", self.related_ids[model])`. This discharges PO2.

### bug discriminator claim

Symbolic execution applies the `bugDiscriminator` rule once:

`bugDiscriminator([1, 2], [3, 4]) => bugDone("OtherBase" |-> [3, 4])`.

The child/base primary-key list is present as an input but is not used for the
`OtherBase` filter. This separates V1 from the reported pre-fix behavior and
discharges PO7.

## Source correspondence

- `SQLUpdateCompiler.pre_sql_setup()` implements the abstract `preSqlSetup` by
  selecting the primary key first, then one parent-link lookup per related update
  model, and collecting row columns into `idents` and `related_ids[model]`.
- `UpdateQuery.get_related_updates()` implements the abstract
  `getRelatedUpdates` by filtering each related update query with
  `self.related_ids[model]`.
- `_get_update_related_id_lookup()` supplies the parent-link path used to
  instantiate `RIDS[M]`.

## Machine-check commands

These commands are intentionally not executed in this task:

```sh
cd fvk
kompile mini-update-planner.k --backend haskell
kast --backend haskell update-related-ids-spec.k
kprove update-related-ids-spec.k
```

Expected machine-check result after any K syntax repair required by the local K
version: `#Top`.

## Test-redundancy recommendation

No tests are removed or marked redundant in this benchmark. Public regression
tests for concrete MTI multiple-parent updates should be kept or added until the
constructed proof is machine-checked, and integration/database tests remain
outside this abstract proof's scope.
