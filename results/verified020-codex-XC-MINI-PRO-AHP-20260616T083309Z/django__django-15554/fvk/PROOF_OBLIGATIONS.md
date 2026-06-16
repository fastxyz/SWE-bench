# FVK Proof Obligations

Status: constructed for audit, not machine-checked.

## Formal core

The local proof uses these abstract operations:

- `strongEq(a, b)` equals `Join.__eq__()`.
- `weakEq(a, b)` equals `Join.equals()`.
- `allowed(alias, reuse)` is true when `reuse is None` or `alias in reuse`.
- `joinNormal(alias_map, candidate, reuse)` is the V1 `Query.join()` path with
  `reuse_with_filtered_relation=False`.
- `joinFilteredCondition(alias_map, candidate, reuse)` is the V1 `Query.join()`
  path with `reuse_with_filtered_relation=True`.

K artifacts are represented by:

- `fvk/mini-django-query.k`
- `fvk/query-join-spec.k`

The commands to run later, if a K environment exists, are:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-join-spec.k
kprove fvk/query-join-spec.k
```

These commands were not executed.

## Obligations

### PO-NORMAL-DISTINCT

Given an alias map containing `A1 -> J1`, and a candidate `J2` such that:

- `weakEq(J1, J2)` is true,
- `strongEq(J1, J2)` is false because `J1.filtered_relation !=
  J2.filtered_relation`,
- `reuse is None` or `A1 in reuse`,
- `reuse_with_filtered_relation` is false,

then `Query.join(J2, reuse)` must not return `A1`. It must create a new alias
for `J2`.

Evidence: SPEC E1-E4.

Discharged by V1: the normal branch in `Query.join()` filters reusable aliases
with `j == join`, which is strong equality.

### PO-NORMAL-SAME-IDENTITY-REUSE

Given an alias map containing `A1 -> J1`, and a candidate `J2` such that:

- `strongEq(J1, J2)` is true,
- `reuse is None` or `A1 in reuse`,
- `reuse_with_filtered_relation` is false,

then `Query.join(J2, reuse)` may return `A1` and must increment its reference
count.

Evidence: existing ordinary join reuse semantics and SPEC E5.

Discharged by V1: the normal branch still reuses aliases where `j == join`.

### PO-FILTERED-PATH-REUSE

Given a filtered relation with path aliases `P`, and an ON-clause condition
lookup that constructs candidate join `JC` such that:

- some `A in P` maps to existing join `JP`,
- `weakEq(JP, JC)` is true,
- `strongEq(JP, JC)` may be false because `JC.filtered_relation` is absent,
- `reuse_with_filtered_relation` is true,

then `Query.join(JC, reuse=P, reuse_with_filtered_relation=True)` must return
an alias from `P`, not create an extra unfiltered join.

Evidence: SPEC E5/E8.

Discharged by V1: `build_filtered_relation_q()` passes
`reuse_with_filtered_relation=True`; `setup_joins()` forwards the flag and uses
`reuse=can_reuse`; `Query.join()` uses `j.equals(join)` only in that opted-in
path.

### PO-REUSE-SET-SCOPE

In filtered-relation condition compilation, an alias not in
`set(filtered_relation.path)` must not be reusable, even if it is weakly equal
to the candidate join.

Evidence: SPEC E6/E8.

Discharged by V1: the opted-in branch uses `if a in reuse and j.equals(join)`,
not global weak equality.

### PO-SQL-OBSERVABLE

If `PO-NORMAL-DISTINCT` creates separate aliases for `relation_zone` and
`relation_all`, and each `Join` carries its own `filtered_relation`, then SQL
generation has two independent contributors to the FROM/JOIN clause, each with
its own compiled ON-clause filter.

Evidence: SPEC E2/E5.

Discharged by source structure: `Join.as_sql()` appends
`compiler.compile(self.filtered_relation)` to that join's ON conditions, and
the compiler iterates active aliases from `query.alias_map`.

### PO-ALIAS-BINDING

References such as `F("relation_zone__price")` and
`F("relation_all__price")` must resolve through their annotation aliases rather
than the default relation name or another filtered alias.

Evidence: SPEC E3/E6.

Discharged by source structure: `names_to_path()` resolves an initial name in
`self._filtered_relations` to that `FilteredRelation`, and `Join.identity`
contains the annotation alias through `FilteredRelation.__eq__()`.

### PO-CALLSITE-COMPATIBILITY

Adding the internal `reuse_with_filtered_relation` parameters must not change
existing source callsites that do not opt in.

Evidence: SPEC Public Compatibility Audit.

Discharged by source inspection: the parameters have defaults and no existing
source callsite passes a positional argument in the affected slot.

