# Constructed Proof

Status: constructed, not machine-checked. The commands below are recorded for a
future environment with K installed; they were not executed.

## Proof target

V1 must satisfy:

- PO-1: `split_exclude()` inner queries can resolve filtered relation aliases.
- PO-2: filtered relation predicates survive first-join trimming.
- PO-3: predicates needing a trimmed alias keep the join instead of being moved.
- PO-4: unfiltered and outer-join behavior is framed.
- PO-5: public compatibility is preserved.

## Abstract semantics

`fvk/mini-django-query.k` models only the state relevant to this issue:

- whether the outer query has a filtered relation alias;
- whether the inner query has that alias;
- whether lookup resolution errors;
- whether the first join carries a filtered relation;
- whether the filtered condition is non-empty;
- whether the filtered condition uses an alias that `trim_start()` would
  remove;
- whether the filtered condition is in `WHERE`;
- whether the first join is trimmed.

This abstraction preserves the audited observable: whether the generated
anti-subquery is constrained by both the lookup predicate and the filtered
relation condition.

## Proof sketch

### PO-1

Initial symbolic state:

`outer_has_filtered_relation = true`, `inner_has_filtered_relation = false`,
and `lookup_error = true`.

The V1 transition for `splitExclude` copies the outer filtered relation map to
the inner query before lookup resolution. Symbolically:

`state(true, false, true, ...) => state(true, true, false, ...)`.

This discharges `CLAIM-SPLIT-EXCLUDE-COPIES-FILTERED-RELATIONS`: the lookup
alias is present in the inner query and the reported FieldError path is removed.

### PO-2

Initial symbolic state:

`first_join_filtered = true`, `condition = pred(P)`, `condition_in_where =
false`, `first_join_trimmed = false`, and `condition_uses_trimmed_alias =
false`.

The V1 `trimStart` transition resolves the filtered relation condition, restores
temporary alias refcounts, adds the condition to `WHERE`, and performs the
existing trim:

`state(..., true, true, false, false, false) =>
 state(..., true, true, false, true, true)`.

Because the condition aliases are disjoint from trimmed aliases, every column in
the moved predicate remains valid after trimming. The selected parent-key set is
therefore restricted by the same filtered predicate that was previously in the
join `ON` clause.

### PO-3

Initial symbolic state is the same as PO-2 except
`condition_uses_trimmed_alias = true`.

The V1 transition keeps `condition_in_where = false` and
`first_join_trimmed = false`.

Thus the original join object remains present, and the filtered relation
condition remains in the join `ON` clause where all aliases are valid.

### PO-4

For `first_join_filtered = false`, the V1-specific branch does not fire. The
model transitions to the same abstract state as pre-V1 trim behavior:
`first_join_trimmed = true`, with no new `WHERE` predicate.

For left outer joins, the audited source keeps the existing `else` branch in
`trim_start()` unchanged.

### PO-5

The source diff changes no method signatures and no public files. The
compatibility audit records unchanged public symbols and return shapes.

## Reproduce the machine check later

These commands are intentionally recorded only. They were not run.

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/django-11265-spec.k
kprove fvk/django-11265-spec.k
```

Expected result after machine checking: all claims return `#Top`.

## Residual risk

- This is an abstract mini-semantics proof, not full Python/Django/SQL
  verification.
- It proves partial correctness of the rewrite state, not termination or query
  planner behavior.
- Because K was not run, test removal is not recommended.
