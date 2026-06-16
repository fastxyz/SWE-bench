# FVK Specification for django__django-16263

Status: constructed from public intent and source inspection; not
machine-checked.

## Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "`Book.objects.annotate(Count('chapters')).count()` ... includes the `Count('chapters')`, despite not ... being used" | A terminal count query must not keep selected annotations whose values cannot affect the count. |
| I2 | `benchmark/PROBLEM.md` | "It produces the same results as: `Book.objects.count()`" | The optimized count must preserve cardinality. |
| I3 | `benchmark/PROBLEM.md` | "stripping out any annotations that are not referenced by filters, other annotations or ordering" | An annotation referenced by filters, dependency annotations, or preserved ordering is required and must not be pruned. |
| I4 | public hint | "Same can be done for exists()" | The same safe-pruning rule applies to existence queries when their selected columns are already discarded. |
| I5 | `query.py` implementation comments | Count aggregation uses a subquery for limits, distinct, and set operations so those operations apply before aggregation. | Pruning must not change selected row identity for `distinct()` or compound-query count semantics. |
| I6 | default ORM semantics | `distinct()`, multi-valued joins, and compound queries can affect row cardinality or row identity. | The optimization is valid only when annotation removal cannot change the row set being counted or tested for existence. |

## Modeled State

For the audited functions, model a `Query` as:

- `annotations`: map `annotation alias -> expression`.
- `annotation_select`: selected annotation aliases after the mask.
- `annotation_aliases`: per-annotation table-alias reference-count deltas.
- `annotation_dependencies`: per-annotation references to other annotation aliases.
- `annotation_lookup_refs`: annotation aliases referenced by lookups.
- `where`, `group_by`, `order_by`, `distinct`, `distinct_fields`,
  `is_sliced`, `combinator`, and `alias_refcount`.

The model abstracts SQL string generation into observable properties:

- `selected_annotations(q)`: annotation aliases that would be selected.
- `active_aliases(q)`: table aliases with positive reference counts.
- `count_cardinality(q)`: the row cardinality seen by `COUNT(*)`.
- `exists_truth(q)`: whether the query has at least one row.

## Required Annotation Set

For non-combined terminal count/existence pruning, an annotation alias is
required when it is in the transitive closure of:

- aliases referenced by lookups (`annotation_lookup_refs`);
- aliases found in the `where` expression tree;
- aliases referenced by explicit `group_by` tuples;
- aliases in `distinct_fields`;
- aliases referenced by ordering when ordering must be preserved for slicing or
  distinct-on count semantics;
- all selected annotations when plain `distinct()` count semantics depend on
  selected row identity;
- selected non-aggregate annotations that introduced a multi-valued join.

The transitive closure follows `annotation_dependencies` and any currently
visible annotation references in expression trees.

## Function Contracts

### `Query.add_annotation(annotation, alias, is_summary=False, select=True)`

Precondition: `alias` is syntactically valid.

Postconditions:

- The resolved annotation is stored under `alias`.
- The annotation select mask is updated exactly as before the fix.
- `annotation_aliases[alias]` equals the positive delta between
  `alias_refcount` before and after resolving the annotation.
- `annotation_dependencies[alias]` records annotation aliases referenced by the
  resolved expression.

### `Query.solve_lookup_type(lookup)`

Precondition: `lookup` is a Django lookup path.

Postconditions:

- If a prefix of `lookup` is an annotation alias, the method returns the same
  expression and residual lookup parts as the previous `refs_expression()` path.
- The referenced annotation alias is added to `annotation_lookup_refs`.
- Non-annotation lookup behavior is unchanged.

### `Query.prune_unused_annotations(preserve_selected, preserve_ordering)`

Precondition: called on a cloned terminal query before `count()` or eligible
`exists()` mutation.

Postconditions:

- Every required annotation remains in `annotations`.
- Every non-required annotation is removed from `annotations` and from the
  select mask.
- For each removed annotation, only its recorded alias reference-count delta is
  subtracted.
- If `group_by is True` and all annotations are pruned, `group_by` becomes
  `None`, preventing aggregate-only grouping from leaking into `exists()`.

### `Query.get_count(using)`

Precondition: the query is a valid Django `Query`.

Postconditions:

- If `combinator` is set, selected annotations are not pruned before the
  aggregate count path.
- Otherwise, unused annotations are pruned according to the required set above,
  then `Count("*")` is added and `get_aggregation()` is used as before.
- The returned count equals the cardinality of the original queryset under the
  preservation conditions above.

### `Query.exists(limit=True)`

Precondition: the query is a valid Django `Query`.

Postconditions:

- If `distinct and is_sliced`, pruning is skipped because selected columns are
  preserved by the existing implementation.
- If `combinator` is set, top-level pruning is skipped.
- Otherwise, unused annotations are pruned before the existing select-clearing
  path.
- The returned existence query is true exactly when the original queryset has at
  least one row under the preservation conditions above.

## Adequacy Notes

The spec intentionally preserves selected annotations for `distinct()` count and
skips pruning for compound count queries. This is stronger than the minimal issue
example but follows the public cardinality-preservation obligation in I2 and the
source-code comment in I5. The issue does not require optimizing every possible
query shape; it requires safe stripping of unused annotations.
