# FVK Proof

Status: constructed, not machine-checked. Per task instructions, no tests,
Python, `kompile`, `kast`, or `kprove` commands were run.

## Proof Target

The proof target is the abstract transformation:

```text
_filter_prefetch_queryset(queryset, predicate, partition_by)
```

and the collection-prefetch call sites that supply `predicate` and
`partition_by`.

The proof is partial correctness: if query construction returns normally, the
returned queryset satisfies the contract in `fvk/SPEC.md`. Termination is not a
separate concern for the helper because it contains no unbounded loop or
recursion.

## Machine-Check Commands To Run Later

These commands are intentionally not executed in this environment:

```sh
kompile fvk/mini-django-prefetch.k --backend haskell
kast --backend haskell fvk/django-prefetch-spec.k
kprove fvk/django-prefetch-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.

## Abstract Claim Summary

The K-style claims are represented in `fvk/django-prefetch-spec.k`.

- `HELPER-UNSLICED`: unsliced querysets append the relation predicate directly.
- `HELPER-SLICED-WINDOW`: sliced querysets on window-capable backends are
  rewritten into relation predicate plus per-partition row-number predicates.
- `HELPER-SLICED-NO-WINDOW`: sliced querysets on non-window backends raise
  `NotSupportedError`.
- `CALLSITE-REVERSE-M2O`: reverse many-to-one passes the foreign-key field name
  as the partition key.
- `CALLSITE-M2M`: many-to-many passes `query_field_name` and preserves sticky
  filtering.
- `CALLSITE-GENERIC`: reverse generic relations partition by content type and
  object id.
- `CACHE-PATH`: manager-level relation filtering uses the same helper for
  sliced custom querysets.

## Constructed Proof

### Helper, unsliced path

Assume `queryset.query.is_sliced == False`.

The helper skips the sliced branch and returns `queryset.filter(predicate)`.
Therefore no limits are cleared, no rank predicates are introduced, and the
observable query filter is exactly the relation predicate. This discharges PO7
for the helper and preserves pre-V1 unsliced behavior.

### Helper, sliced path on a window-capable backend

Assume:

- `queryset.query.is_sliced == True`;
- `connections[queryset.db].features.supports_over_clause == True`;
- `low_mark = L`;
- `high_mark = H`, where `H` is either `None` or an integer.

The helper reads `L` and `H` before clearing limits. It resolves the queryset
ordering through the compiler. If the resolved ordering is empty, V2 substitutes
the model primary key field name. This preserves ordered queryset semantics and
chooses a deterministic, backend-valid order for unordered querysets, which have
no public order guarantee. This discharges PO4 and fixes FINDINGS F2.

The helper constructs:

```text
window = ROW_NUMBER() OVER (PARTITION BY partition_by ORDER BY order_by)
```

and conjoins:

```text
window > L
window <= H    # only when H is not None
```

Because SQL window filtering is applied after ordinary `WHERE` filtering in
Django's qualify machinery, and because the relation predicate is a normal
non-window predicate, the row number is computed inside each related-parent
partition after the relation candidate set is constrained. `ROW_NUMBER()` is
1-based, while Django's `low_mark`/`high_mark` slice bounds are 0-based. Thus:

- `window > L` drops exactly the first `L` rows in each partition;
- `window <= H` keeps at most the first `H` rows in each partition when `H`
  exists;
- together they describe `[L:H]` per parent;
- when `H` is `None`, the upper bound is absent, describing `[L:]`.

The helper then clears queryset limits before calling `.filter()`, so the public
sliced-query guard in `QuerySet._filter_or_exclude()` no longer applies. This
discharges PO1 and PO2.

### Helper, sliced path on a non-window backend

Assume:

- `queryset.query.is_sliced == True`;
- `supports_over_clause == False`.

The helper raises `NotSupportedError` before constructing a `Window` expression
or clearing limits. This is the expected explicit capability failure because the
public intent rejects fetching all related rows and slicing in Python. This
discharges PO5 and FINDINGS F3.

### Reverse many-to-one call sites

For reverse many-to-one prefetch, the related model rows contain the foreign key
named `self.field.name` pointing back to the parent. The call site builds:

```text
Q("%s__in" % self.field.name = instances)
partition_by = self.field.name
```

All rows for a given parent share the same value of `self.field.name`; rows for
different parents have different relation keys. Therefore PO3 holds for reverse
many-to-one prefetches. The manager-level `_apply_rel_filters()` path uses
`Q(**self.core_filters)` and the same partition key when the custom queryset is
sliced, discharging PO6 for no-`to_attr` cache construction.

### Many-to-many call sites

For many-to-many prefetch, `self.query_field_name` is the relation name used by
the existing prefetch relation filter. The V2 call site builds:

```text
Q("%s__in" % self.query_field_name = instances)
partition_by = self.query_field_name
```

and passes `queryset._next_is_sticky()` into the helper. The same relation path
that filters rows for the source instances is used to partition them, so the
row-number bounds apply per source parent. Preserving `_next_is_sticky()`
maintains Django's existing many-to-many join reuse behavior. This discharges
PO3, PO6, and PO7 for many-to-many prefetches.

### Reverse generic relation call sites

For reverse generic relations, object ids are not globally unique across content
types. The V2 call site uses the existing content-type/object-id predicate and
passes:

```text
partition_by = (self.content_type_field_name, self.object_id_field_name)
```

Thus two rows with the same object id but different content types are in
different row-number partitions. This discharges PO3 and FINDINGS F6.

### Compatibility and frame proof

No public method signature changed. The `get_prefetch_queryset()` return tuple
shape remains the same. `Prefetch` validation for `raw()`, `values()`, and
`values_list()` querysets remains unchanged. Unsliced manager paths preserve the
existing `_defer_next_filter` and `_next_is_sticky()` behavior. This discharges
PO7 and PO9.

## Adequacy Gate

The formal English obligations match the intent ledger:

- no sliced-query `TypeError` for covered multi-valued prefetches;
- per-parent top-N behavior, not global top-N;
- no Python-side fetch-all fallback;
- explicit backend capability failure when window expressions are unavailable;
- unordered sliced querysets remain accepted without promising a public order.

The only V1 adequacy failure was FINDINGS F2. V2 repairs it by adding a primary
key fallback order.

## Test Recommendations

No tests were modified. Because this proof is constructed but not
machine-checked, no existing tests should be removed.

Recommended tests to add or keep:

- reverse many-to-one sliced prefetch with `to_attr`;
- reverse many-to-one sliced prefetch without `to_attr`;
- offset slice such as `[1:3]`;
- many-to-many sliced prefetch;
- reverse generic relation sliced prefetch with overlapping object ids under
  different content types;
- unsupported `supports_over_clause=False` backend path expecting
  `NotSupportedError`;
- unordered sliced queryset path to cover the primary-key fallback.
