# FVK Findings

Status: constructed findings from public intent, source inspection, and proof
obligations. No tests or proof tools were run.

## F1: V1 Pruned Combined Count Queries

Classification: code bug in V1; fixed in V2.

Evidence:

- Intent I2 requires count cardinality preservation.
- Intent I5 records that Django already treats set operations as a subquery
  boundary for aggregation.
- V1 called `prune_unused_annotations()` unconditionally in `get_count()`.

Counterexample shape:

```python
left = Book.objects.annotate(label=...)
right = Book.objects.annotate(label=...)
left.union(right).count()
```

For compound queries, selected expressions are part of the compound query's row
shape and can affect distinct compound row identity. Stripping selected
annotations before `get_aggregation()` is therefore not justified by the issue's
"same results" obligation.

Resolution:

- V2 skips annotation pruning in `get_count()` when `obj.combinator` is set.
- V2 also skips top-level pruning in `exists()` when `q.combinator` is set,
  avoiding a similar shape-risk outside the explicit union-recursive path.

Relevant proof obligations: PO7, PO8.

## F2: Masking Alone Is Insufficient

Classification: confirmed design constraint; V1/V2 address it.

Evidence:

- Intent I1 requires stripping the unused annotation from count SQL.
- Intent I2 requires preserving count cardinality.
- Annotation resolution can add joins by incrementing table alias reference
  counts. If the selected expression is merely masked but its many-to-many join
  remains, `COUNT(*)` can observe duplicate joined rows.

Resolution:

- `add_annotation()` records per-annotation alias reference-count deltas.
- `remove_annotation()` subtracts those deltas when pruning an unused annotation.

Relevant proof obligations: PO1, PO4.

## F3: Filter and Dependency References Must Be Stable

Classification: confirmed design constraint; V1/V2 address it.

Evidence:

- Intent I3 requires preserving annotations referenced by filters and other
  annotations.
- Expression identity alone can be fragile after query cloning or alias
  relabeling.

Resolution:

- `solve_lookup_type()` records annotation aliases referenced by lookups.
- `add_annotation()` records annotation-to-annotation dependencies when the
  expression is resolved.
- `prune_unused_annotations()` computes the transitive closure before pruning.

Relevant proof obligations: PO2, PO3.

## F4: Distinct and Multi-Valued Annotations Are Safety Boundaries

Classification: confirmed conservative scope decision.

Evidence:

- Intent I2 requires count result preservation.
- A selected annotation can affect `distinct()` row identity.
- A selected non-aggregate annotation that introduces a multi-valued join can
  change queryset row cardinality.

Resolution:

- `get_count()` calls pruning with `preserve_selected=obj.distinct`.
- The pruning helper preserves selected non-aggregate annotations that introduced
  multi-valued joins.

Relevant proof obligations: PO5, PO7.

## F5: Constructed, Not Machine-Checked

Classification: proof capability gap, not a code bug.

Evidence:

- The FVK instructions and task forbid running K tooling, tests, or Python.

Resolution:

- `PROOF.md` includes exact commands that should be run in a real environment.
- Test removal is not recommended here; future tests should be kept until
  machine checking and normal Django tests run.

Relevant proof obligations: all, especially PO9.
