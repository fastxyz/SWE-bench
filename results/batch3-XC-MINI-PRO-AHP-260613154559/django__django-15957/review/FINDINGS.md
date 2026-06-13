# Code review findings — django__django-15957 (V1 fix)

Scope of V1: `django/db/models/fields/related_descriptors.py` (new
`_filter_prefetch_queryset()` helper + new imports; reverse-FK and forward-m2m
`get_prefetch_queryset()` now call it) and `django/db/models/query.py`
(`_filter_or_exclude` slice guard relaxed when `_defer_next_filter` is set).

Legend: ✅ confirmed correct · ⚠️ acceptable limitation / minor · ✏️ change made.

---

## F1 — Core issue (sliced `Prefetch` with `to_attr`) is fixed ✅
The reported failure is `Category.objects.prefetch_related(Prefetch('post_set',
Post.objects.all()[:3], to_attr='example_posts'))`. `post_set` resolves to the
reverse-many-to-one manager, whose `get_prefetch_queryset()` previously did
`queryset.filter(**{field__in: instances})` — which raises on a sliced queryset.
V1 routes through `_filter_prefetch_queryset`, which (when sliced) replaces the
LIMIT/OFFSET with a `ROW_NUMBER()` window partitioned by the relation field and a
`row_number` range predicate, then `clear_limits()`. The `to_attr` branch of
`prefetch_one_level` only does `setattr(obj, to_attr, vals)`, so the exact example
now works.

## F2 — m2m: window `partition_by` reuses the `__in` join (no row duplication) ✅
This was the highest-risk correctness question. If `partition_by=query_field_name`
created a *second* join to the through table, the result rows would multiply and the
raw-table `extra(select=…)` (which references the through table by its real name)
would be wrong. Traced the resolution: in `Query.build_filter`, a conditional
expression is resolved via `filter_expr.resolve_expression(self, allow_joins=…)`
with `reuse` defaulting to `None`; `resolve_ref`→`setup_joins(can_reuse=None)` and
its docstring (query.py:1771-1774) states **`can_reuse=None` means all joins are
reusable**. `trim_joins` then reduces `F(query_field_name)` to the same
`through.<source>_id` column the `__in` lookup already filters on. Because the
`__in` predicate and the window are applied in a **single** `filter(predicate)`
call (and `_next_is_sticky()` is preserved), the existing join is reused — no
duplicate join, and `partition_by` matches the `_prefetch_related_val_*` grouping
key. Correct.

## F3 — reverse-FK: partition key matches the grouping key ✅
`rel_obj_attr = self.field.get_local_related_value` (e.g. `post.category_id`) is the
key used to bucket results in `prefetch_one_level`. `partition_by=self.field.name`
resolves to the same local FK column (forward FK = local column, no join). So
"top-N per partition" buckets exactly match how rows are distributed to parents.
Correct.

## F4 — m2m `extra(select=…)` survives the QUALIFY subquery wrapping ✅
A window predicate in the WHERE makes the compiler take the `get_qualify_sql()`
path (compiler.py:590), wrapping the query in `SELECT * FROM (…) WHERE <row_number
predicate>` and, because the window must be unmasked as `qualN`, a final mask
`SELECT <aliases> FROM (…)`. `get_select()` (compiler.py:254-257) places
`extra_select` columns first in `self.select`, and `with_col_aliases=True` does not
rename columns that already carry an alias (compiler.py:310). Therefore
`_prefetch_related_val_*` keeps its name through the inner query, `SELECT *`, and
the outer mask, and remains positionally consistent with `self.select`, so
`ModelIterable` still reads it. Correct.

## F5 — Slice arithmetic (offset/limit) is right ✅
`predicate &= GreaterThan(window, low_mark)` and (if `high_mark is not None`)
`LessThanOrEqual(window, high_mark)`. `ROW_NUMBER()` is 1-based, so `[:3]`→`(>0
and <=3)`→rows 1-3; `[2:5]`→`(>2 and <=5)`→rows 3-5 (0-indexed 2,3,4); `[2:]`→`>2`,
no upper bound. All match Python slice semantics. `[:0]`/`[n:n]` already trigger
`set_empty()` and the predicate is independently impossible — still empty.

## F6 — No-ordering case produces valid SQL ✅
For `Post.objects.all()[:3]` with no explicit/Meta ordering, the throwaway
compiler's `get_order_by()` returns `[]`; `Window(order_by=[])`→`OrderByList()`,
whose `as_sql` returns `('', ())` (expressions.py:1209-1211). Result:
`ROW_NUMBER() OVER (PARTITION BY …)` — valid on all window-capable backends, with
the same non-deterministic ordering an unordered sliced query already has.

## F7 — Non-sliced path is behaviourally unchanged (no regression) ✅
When `queryset.query.is_sliced` is False (the overwhelmingly common
`prefetch_related('post_set')` / unsliced-`Prefetch` case), the helper returns
`queryset.filter(Q(field__in=instances))`. This is equivalent to the old
`queryset.filter(**{field__in: instances})` — `filter(Q(x))` wraps in one extra
transparent AND node (identical SQL semantics, only redundant parentheses), and the
m2m `_next_is_sticky()` is preserved. Query count is unchanged.

## F8 — Backends without window functions error explicitly ✅
The helper raises `NotSupportedError` with an actionable message when
`connections[db].features.supports_over_clause` is False. `supports_over_clause`
is defined on the base feature class (=False), so no `AttributeError` risk. This
is preferable to silently loading the whole relation.

## F9 — `_filter_or_exclude` relaxation is fully contained ✅
The new `and not self._defer_next_filter` clause only suppresses the slice
`TypeError` when a filter is being *deferred*. `_defer_next_filter = True` is set in
exactly two internal places — the reverse-FK and m2m `_apply_rel_filters()` — and
both are called either (a) from `get_queryset()` with a fresh **unsliced**
`super().get_queryset()` (so `is_sliced` is False and the clause is irrelevant), or
(b) from `prefetch_one_level` (query.py:2523) for the **no-`to_attr`** case, where
the returned queryset immediately gets `_result_cache = vals` and is never
executed. No user-facing eager `filter()`/`exclude()` is affected.

## F10 — Existing slice/deferred tests still pass ✅
`queries.tests.test_slicing_cannot_filter_queryset_once_sliced`
(`Article.objects.all()[0:5].filter(id=1)`): the sliced clone has
`_defer_next_filter=False`, so `True and True and not False` → still raises.
`queryset_pickle.tests.test_filter_deferred` (`_defer_next_filter=True` on an
**unsliced** qs): `is_sliced` is False, so the new clause is never reached — defers
as before.

## F11 — No-`to_attr` sliced prefetch now works and yields correct results ✅
For `Prefetch('post_set', Post.objects.all()[:3])` (no `to_attr`),
`prefetch_one_level` builds the cached manager queryset via
`manager._apply_rel_filters(lookup.queryset)`. With F9 this no longer raises; the
relation filter is deferred and `_result_cache` is set to the windowed `vals`.
`category.post_set.all()`/`len`/`count` all read `_result_cache` → the (up to 3)
prefetched rows. Re-filtering the cached, still-sliced queryset
(`category.post_set.filter(...)`) raises the normal slice `TypeError`, which is
expected and consistent with sliced-queryset semantics.

## F12 — `Prefetch.queryset` is not mutated; reuse/nesting safe ✅
`get_prefetch_queryset` clones via `.using()` before the helper, and `.filter()`
clones again, so the helper's `clear_limits()` operates on a clone — the original
`Prefetch.queryset` keeps its slice and is reusable. `_prefetch_related_lookups`
(nested prefetches) are copied across clones, so nested prefetch on a sliced
queryset is preserved.

## F13 — Combining `Q &= GreaterThan(...)` is valid ✅
`Q._combine` requires the other operand to be "conditional". `Lookup.output_field`
is `BooleanField()` (lookups.py:150-152) and `Expression.conditional` returns
`isinstance(output_field, BooleanField)` (expressions.py:284-286), so lookups are
conditional and combine into the `Q`. The single shared `window` instance is used by
both lookups, so `get_qualify_sql` emits exactly one `qualN` window column.

## F14 — Imports do not introduce circular imports ✅
`django.db.models.__init__` imports `lookups` (line 45) and `Window` (line 35)
before `fields.related` (line 52, which pulls in `related_descriptors`), and nothing
under `django.db.models.functions` imports back into `query`/`related`*. The new
`DEFAULT_DB_ALIAS`/`NotSupportedError` come from `django.db` (already imported).

## F15 — Out-of-scope relations still raise (acceptable) ⚠️
Single-valued relations (`ForwardManyToOneDescriptor`, `ReverseOneToOneDescriptor`)
and the GenericRelation manager were not changed; slicing those prefetch querysets
still raises. Slicing a single-valued prefetch is meaningless, and the
content-type-grouped generic query would need a `(content_type, object_id)`
partition — materially more complex and outside the reported issue. These remain
errors by design.

## F16 — Boundary: multi-column reverse FK ⚠️
`partition_by=self.field.name` for a (rare) composite/multi-column FK would hit
"Referencing multicolumn fields with F() objects isn't supported". This is an
obscure, pre-existing ORM limitation; single-column FKs (the normal case) are fine.
No action.

## F17 — Boundary: relational `order_by` may add a redundant join ⚠️
The throwaway `get_compiler().get_order_by()` resolves ordering against
`queryset.query` with `reuse=None`; for ordering across a relation this can leave an
extra join that recompilation may not fully coalesce. Worst case is a redundant
(semantically identical) join — results stay correct, only marginally less
efficient — and only for the uncommon "slice a prefetch ordered by a related
field". Using `get_order_by()` (vs raw `query.order_by`) is necessary to honour
`Meta.ordering`. No action.

## F18 — Clarity of the `_filter_or_exclude` guard ✏️
The bare `and not self._defer_next_filter` is non-obvious to future readers. Added a
short explanatory comment (no behaviour change). See `reports/control_notes.md`.

## F19 — Multi-DB feature check uses `queryset._db or DEFAULT_DB_ALIAS` ⚠️
The `supports_over_clause` check and order-by compiler use
`queryset._db or DEFAULT_DB_ALIAS`. Under DB routing the executing alias could in
principle differ, but `.using()` has already pinned `_db` from the prefetch hint,
and falling back to the default alias is the only sensible choice at build time.
Acceptable.
