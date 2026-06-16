# FVK Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were executed.

## Claim Summary

The proof establishes partial correctness for the local join-reuse policy:

1. Normal query construction reuses only strong-equal joins, so two
   `FilteredRelation` aliases with the same relation path but different
   filters or aliases cannot collapse into one alias.
2. Filtered-relation ON-clause condition compilation reuses weak-equal joins
   only inside the current filtered relation path, so condition lookups bind to
   the join being compiled without creating unrelated joins.
3. The V1 source implements both modes and preserves existing default behavior
   for callers that do not opt in.

## Proof Sketch

### Normal join construction

Start with an alias map containing `A1 -> J1`. Let `J2` be a candidate join for
a second filtered alias on the same relation path.

For the reported issue shape:

- `J1.table_name == J2.table_name`
- `J1.parent_alias == J2.parent_alias`
- `J1.join_field == J2.join_field`
- `J1.filtered_relation != J2.filtered_relation`

Therefore `weakEq(J1, J2)` holds and `strongEq(J1, J2)` does not hold.

In V1, `Query.join()` with `reuse_with_filtered_relation=False` computes
`reuse_aliases` with:

```python
if (reuse is None or a in reuse) and j == join
```

`j == join` dispatches to `Join.__eq__()`, whose identity includes
`filtered_relation`. Thus `A1` is excluded from `reuse_aliases`. With no other
strong-equal alias available, the function reaches the "No reuse is possible"
branch, creates a new alias, sets `join.table_alias`, stores `alias_map[alias] =
join`, and returns the new alias.

This discharges PO-NORMAL-DISTINCT.

### Same identity reuse

If `J1.filtered_relation == J2.filtered_relation` as well as the structural
join fields being equal, then `Join.__eq__()` holds. In the normal branch,
`A1` is included when allowed by `reuse`, reference count is incremented, and
`A1` is returned.

This discharges PO-NORMAL-SAME-IDENTITY-REUSE and preserves repeated reference
behavior.

### FilteredRelation condition compilation

When rendering `Join.as_sql()` for a filtered join, `FilteredRelation.as_sql()`
calls:

```python
query.build_filtered_relation_q(self.condition, reuse=set(self.path))
```

V1 passes `reuse_with_filtered_relation=True` through `build_filter()` and
`setup_joins()` for each condition child. `setup_joins()` then uses:

```python
reuse = can_reuse if join.m2m or reuse_with_filtered_relation else None
```

and calls `Query.join(..., reuse_with_filtered_relation=True)`.

In that opted-in branch, `Query.join()` computes reusable aliases with:

```python
if a in reuse and j.equals(join)
```

`Join.equals()` ignores `filtered_relation`, so the condition lookup's plain
relation candidate can match the filtered path join. The `a in reuse` guard
limits this weak comparison to aliases from `set(self.path)`, preventing global
weak reuse.

This discharges PO-FILTERED-PATH-REUSE and PO-REUSE-SET-SCOPE.

### SQL observable

After PO-NORMAL-DISTINCT, the alias map contains separate `Join` instances for
the two filtered aliases. Each `Join` carries its own `filtered_relation`.
`Join.as_sql()` appends the compiled filtered relation to that join's ON
conditions. Therefore the generated query has independent JOIN contributors for
the two aliases, which is the observable behavior required by the issue.

This discharges PO-SQL-OBSERVABLE.

### Compatibility

The new parameters are defaulted. Source inspection found no existing callsite
that passes positional arguments into the new slots and no override definitions
under `repo/`. Callers that do not opt in keep the normal strong-equality path.

This discharges PO-CALLSITE-COMPATIBILITY.

## K Artifact Commands

The intended machine-check commands are:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-join-spec.k
kprove fvk/query-join-spec.k
```

Expected outcome after making the abstract K files concrete enough for the
installed K version: `kprove` returns `#Top` for the local join-reuse claims.

## Test Redundancy Recommendation

No tests should be removed. The proof is constructed but not machine-checked,
and it covers the local alias reuse policy rather than Django's full compiler
and database integration. Existing `FilteredRelation` tests and the public
hint's regression shape should be kept.

## Residual Risk

- The proof is not machine-checked.
- The mini-model abstracts SQL rendering and database execution.
- Termination is not a separate concern for these finite join-selection
  branches, but the proof is still stated as partial correctness.

These risks do not justify another code change; they justify keeping tests and
not claiming machine-verified confidence.

