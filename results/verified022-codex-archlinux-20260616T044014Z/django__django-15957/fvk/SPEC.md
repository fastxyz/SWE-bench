# FVK Spec: Sliced Prefetch Querysets

Status: constructed from public intent and source inspection; not machine-checked.

## Scope

This FVK pass audits the V1/V2 source changes for `django__django-15957`.
The verified unit is the prefetch filtering transformation added in
`repo/django/db/models/fields/related_descriptors.py` and its call sites in:

- reverse many-to-one prefetching;
- many-to-many prefetching;
- reverse generic relation prefetching;
- related-manager cache construction when `Prefetch(..., queryset=...)` is used
  without `to_attr`.

Forward foreign key and reverse one-to-one prefetches are single-valued
relations. They remain outside this spec because the issue's intent is "a
couple of example objects from each category", i.e. a bounded collection per
parent.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "`Prefetch()` objects does not work with sliced querysets" and example raising "Cannot filter a query once a slice has been taken." | A sliced custom queryset on a multi-valued prefetch must not reach Django's public `.filter()` sliced-query guard. | Encoded by PO1. |
| I2 | `benchmark/PROBLEM.md` | "display a list of categories while displaying couple of example objects from each category" | The slice is per parent relation group, not a single global limit across all parents. | Encoded by PO2 and PO3. |
| I3 | `benchmark/PROBLEM.md` | Avoid "loading thousands of objects from the database to display first three" | The implementation must keep the limit in SQL or query construction; clearing the slice and slicing in Python is not acceptable. | Encoded by PO2. |
| I4 | Public hints | "top-n-per-group query" and "window queries" | A row-number/window formulation is a public-intent-compatible mechanism for per-parent limits. | Encoded by PO2. |
| I5 | `benchmark/PROBLEM.md` | Example uses `Post.objects.all()[:3]` without explicit `order_by()` | Unordered sliced prefetches are in scope. Their row order is not guaranteed, but they should not fail solely because no explicit ordering exists. | V1 gap fixed by V2 primary-key fallback; encoded by PO4. |
| I6 | Existing Django source | `QuerySet._filter_or_exclude()` raises on `query.is_sliced` before adding filters. | Any implementation that must add relation filters to a sliced queryset must clear/rewrite limits before calling `.filter()`. | Encoded by PO1. |
| I7 | Existing Django source and public API shape | `Prefetch` rejects raw/values querysets and the issue does not request changing that API. | Existing `Prefetch` queryset validation is preserved. | Frame condition PO7. |
| I8 | Existing Django source | Backends advertise `supports_over_clause`; `Window.as_sql()` raises on unsupported backends. | Sliced prefetch support can require window support and should fail explicitly where unavailable. | Encoded by PO5. |

## Abstract State Model

The formal model abstracts a queryset as:

```text
Query = {
  sliced: Bool,
  low: Int,          # Django low_mark; 0-based inclusive lower bound
  high: Maybe[Int],  # Django high_mark; 0-based exclusive upper bound
  order: List[OrderExpr],
  modelPk: FieldName,
  filters: Predicate,
  limitsCleared: Bool,
  dbSupportsOver: Bool
}
```

The helper receives:

```text
_filter_prefetch_queryset(queryset, predicate, partition_by)
```

where `predicate` is the relation filter and `partition_by` identifies the
parent relation group. For generic relations, `partition_by` is the tuple
`(content_type_field_name, object_id_field_name)`.

## Intended Contract

### C1. Unsliced queryset

If `queryset.query.is_sliced` is false, the helper returns
`queryset.filter(predicate)`. The query limits and ordering are unchanged.

### C2. Sliced queryset on a window-capable backend

If `queryset.query.is_sliced` is true and the chosen database supports window
expressions, the helper:

1. captures `low_mark` and `high_mark`;
2. resolves the queryset ordering;
3. if ordering is empty, uses the model primary-key field as a deterministic
   fallback order for `ROW_NUMBER()`;
4. builds `ROW_NUMBER() OVER (PARTITION BY partition_by ORDER BY ordering)`;
5. conjoins `row_number > low_mark`;
6. conjoins `row_number <= high_mark` when `high_mark` is not `None`;
7. clears the original queryset limits;
8. applies the relation predicate and row-number predicates through `.filter()`.

The observable result is the same set of related rows as slicing each parent's
ordered related-row list by `[low_mark:high_mark]`, without fetching all related
rows and slicing in Python.

### C3. Sliced queryset on a non-window backend

If `queryset.query.is_sliced` is true and the chosen database does not support
window expressions, the helper raises `NotSupportedError` rather than silently
fetching all rows or falling back to the old sliced-query `TypeError`.

### C4. Relation call-site partition keys

Reverse many-to-one prefetch partitions by the foreign-key relation field name.
Many-to-many prefetch partitions by `query_field_name`. Reverse generic relation
prefetch partitions by both content type and object id.

### C5. Cache-assignment path

When `Prefetch(..., queryset=...)` has no `to_attr`, `prefetch_one_level()` asks
the related manager to construct a cached queryset for each parent. The manager
filter path must use the same slice rewrite before applying per-instance
relation filters.

## Formal Claim Sketch

The machine-checkable core is represented by the abstract claims in
`fvk/django-prefetch-spec.k`; the proof is described in `fvk/PROOF.md`.

Primary claims:

- `HELPER-UNSLICED`: unsliced querysets append the predicate directly.
- `HELPER-SLICED-WINDOW`: sliced querysets on window-capable backends clear
  limits and append per-partition row-number predicates.
- `HELPER-SLICED-NO-WINDOW`: sliced querysets on non-window backends raise
  `NotSupportedError`.
- `CALLSITE-REVERSE-M2O`, `CALLSITE-M2M`, `CALLSITE-GENERIC`: call sites supply
  the partition key required by the relation grouping.
- `CACHE-PATH`: manager-level relation filters satisfy the same helper contract
  for sliced custom querysets used without `to_attr`.
