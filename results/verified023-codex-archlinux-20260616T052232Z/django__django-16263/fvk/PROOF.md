# FVK Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Adequacy Gate

The English intent in `SPEC.md` is derived from the public issue text:

- unused annotations should be stripped from count queries;
- count results must remain the same;
- annotations referenced by filters, other annotations, or preserved ordering
  are not unused;
- eligible exists queries can receive the same treatment.

The proof obligations do not claim that all query shapes are optimized. They
claim only safe pruning under the safety boundaries needed for cardinality and
row-shape preservation.

## Proof Sketch

### PO1: Annotation Alias Delta

`add_annotation()` snapshots `alias_refcount` before expression resolution. The
existing resolver runs unchanged. After resolution, V2 stores only positive
differences between the post-resolution refcounts and the snapshot. Therefore
the recorded delta is exactly the alias-refcount contribution introduced by that
annotation, assuming Django's existing resolver is the source of all refcount
increments during annotation resolution.

### PO2: Lookup Reference Preservation

The old `refs_expression()` path selected the first annotation prefix of a
lookup path and returned the residual lookup parts. V2's
`_annotation_ref_from_name()` enumerates the same prefixes. When a prefix is
found, `solve_lookup_type()` returns the same expression and residual lookup
parts and additionally records the alias in `_annotation_lookup_refs`. Thus
filters that reference an annotation seed the required set.

### PO3: Dependency Closure

`add_annotation()` records dependencies before inserting the new annotation, so
the annotation cannot depend on itself merely because it is now present in
`annotations`. `prune_unused_annotations()` computes a queue-based closure over
recorded dependencies and visible expression references. By induction on the
dependency path length, every dependency of a required annotation is also added
to the required set.

### PO4: Pruning

The pruning transition computes `Required`, iterates over
`annotations - Required`, and removes each such alias. Removal updates the
select mask and subtracts the alias deltas recorded for that annotation. Because
required aliases are excluded from the removal set, required annotations remain.
Because only recorded deltas are subtracted, aliases introduced by filters,
grouping, values selection, or other retained annotations are not intentionally
removed by this transition.

### PO5: Cardinality Safety

For plain `distinct()` counts, V2 treats selected annotations as required.
Therefore distinct row identity is preserved. For selected non-aggregate
annotations that introduced multi-valued joins, V2 treats the annotation as
required, preserving row multiplicity. These are conservative obligations: they
may leave some optimizable annotations in place, but they preserve the public
"same results" requirement.

### PO6: Group-By Cleanup

If pruning removes every annotation and `group_by is True`, then the only
remaining known source of that boolean grouping flag is an aggregate annotation
that was just removed. Setting `group_by = None` prevents the later
`exists()` path from converting the stale flag into grouped selected fields.

### PO7: Count

For non-combined queries, `get_count()` now runs pruning before adding
`Count("*")`. The added aggregate is not part of the original annotations and is
used solely by the existing aggregation path. For combined queries, V2 skips
pruning, which discharges Finding F1 by preserving compound row shape and row
identity.

### PO8: Exists

For non-combined, non-distinct-sliced queries, `exists()` prunes before the
existing select-clearing logic. Since the selected values are not returned by
that path, removing unused annotations cannot change the existence truth under
the required-set rules. Combined queries and distinct-sliced queries keep the
pre-existing selected-column-sensitive behavior.

### PO9: Compatibility

The signatures of `Query.get_count()`, `Query.exists()`, `Query.add_annotation()`,
and `Query.solve_lookup_type()` are unchanged. The `QuerySet.count()` and
`QuerySet.exists()` public entry points continue to call the same query methods.
No tests were edited.

## Machine-Check Commands Not Run

These are the commands a future environment should run after completing concrete
`.k` files from the obligations:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-prune-spec.k
kprove fvk/query-prune-spec.k --definition fvk/mini-django-query-kompiled
```

Expected result if the constructed proof is encoded faithfully: `kprove`
returns `#Top` for PO1-PO9. This expectation is not an execution result.

## Test Recommendation

No existing tests should be removed. Useful future tests would assert:

- an unused aggregate annotation is absent from count SQL and count matches the
  unannotated count;
- an unused annotation is absent from eligible exists SQL;
- an annotation used in a filter remains available;
- an annotation dependency is preserved;
- combined-query counts do not prune selected annotations.

The recommendation is conditioned on ordinary Django test execution and any
future K machine check.
