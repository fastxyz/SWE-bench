# Control notes — django__django-15957 (review outcome)

The review (`review/FINDINGS.md`) found **no correctness defects** in V1. The fix is
confirmed and kept essentially as-is; the only edit this round is a clarifying
comment. Below, every decision is tied to numbered findings.

## Summary of the V1 design (re-confirmed)

`_filter_prefetch_queryset(queryset, field_name, instances)` adds the standard
`field_name__in=instances` predicate and, when the queryset is sliced, converts the
LIMIT/OFFSET into a `ROW_NUMBER()` window partitioned by `field_name`, bounded by the
slice, and clears the limits. It is used by the reverse-many-to-one and forward-m2m
`get_prefetch_queryset()` methods. `QuerySet._filter_or_exclude` additionally skips
the "cannot filter a sliced query" error for *deferred* filters so the no-`to_attr`
form also works.

## Change made this round

### C1 — Added an explanatory comment to `_filter_or_exclude` (query.py)
Traces to **F18**. The guard `and not self._defer_next_filter` is correct (**F9**,
**F10**) but its intent is non-obvious. Added a 3-line comment explaining that a
deferred filter is never executed and is only ever set internally by
`_apply_rel_filters()`. Behaviour is unchanged.

## Decisions to keep V1 unchanged (with justification)

### C2 — Keep `_filter_prefetch_queryset` and the two descriptor call sites
Justified by **F1** (fixes the reported `to_attr` example), **F2** (m2m
`partition_by` reuses the `__in` join via `setup_joins(can_reuse=None)` →
all-reusable, so no row duplication and the `extra(select=…)` raw-table reference
stays valid), **F3** (reverse-FK partition column equals the grouping key), **F4**
(the `extra` column survives QUALIFY subquery wrapping because extra-select columns
keep their alias and lead `self.select`), **F5** (offset/limit arithmetic matches
Python slices), **F13** (`Q &= <Lookup>` is valid and the shared window dedupes to
one `qualN`). No change needed.

### C3 — Keep the single combined `filter(predicate)` + preserved `_next_is_sticky()`
Justified by **F2** and **F7**. Applying the `__in` predicate and the window in one
`filter()` call is what allows the window's `partition_by` to reuse the lookup's
join; doing them in two calls could create a duplicate join. Passing
`queryset._next_is_sticky()` into the helper preserves the original m2m join-reuse
behaviour, and the non-sliced path stays behaviourally identical to pre-fix code
(**F7**), so existing prefetch tests and query counts are unaffected.

### C4 — Keep the `_filter_or_exclude` slice-guard relaxation
Justified by **F9**, **F10**, **F11**. The relaxation is fully contained to the two
internal `_apply_rel_filters()` deferred-filter call sites; it never affects
user-facing eager filtering, and the two existing tests that assert the slice error
(`test_slicing_cannot_filter_queryset_once_sliced`) and the deferred-filter pickling
(`test_filter_deferred`) both still behave as before. It is required for the
no-`to_attr` form of sliced prefetch (**F11**), which I judged the issue intends to
support ("Prefetch objects don't work with slices", stated generally). I considered
an alternative — clearing limits on a clone inside `prefetch_one_level` before
`_apply_rel_filters()` — and rejected it: it is more code, discards the slice on the
cached query (less faithful introspection), and bypasses the purpose-built
`_defer_next_filter` mechanism.

### C5 — Keep `NotSupportedError` on backends without window functions
Justified by **F8**. Explicit failure with an actionable message is better than
silently loading the entire relation; `supports_over_clause` exists on the base
feature class, so the check cannot raise `AttributeError`.

### C6 — Keep `get_compiler().get_order_by()` for the window ordering
Justified by **F6** and **F17**. Using the compiler's effective ordering honours
`Meta.ordering` (which `query.order_by` alone would miss) and yields valid SQL when
there is no ordering. The only downside (**F17**) is a possible redundant — but
semantically harmless — join when ordering crosses a relation; results stay correct,
so no change.

### C7 — Keep the `GreaterThan(window, low_mark)` predicate unconditional
Justified by **F5**. For `low_mark == 0` the predicate is the always-true
`row_number > 0`; it is harmless (the `<= high_mark` predicate already forces the
QUALIFY path, and both lookups share one window column per **F13**). Leaving it
unconditional keeps the helper simple and avoids deviating from the obvious
implementation. No correctness or measurable performance impact.

### C8 — Leave single-valued and GenericRelation prefetch raising on slices
Justified by **F15**. Slicing a single-valued relation prefetch is meaningless, and
a correct top-N for the content-type-grouped generic query needs a two-column
partition — both outside the reported issue. They continue to raise, by design.

### C9 — Accept the multi-column-FK and multi-DB boundaries as-is
Justified by **F16** and **F19**. The composite-FK `partition_by` limitation is a
pre-existing ORM constraint affecting only an exotic relation shape; the
`queryset._db or DEFAULT_DB_ALIAS` feature check is the only sensible build-time
choice and is already pinned by `.using()`. Neither warrants added complexity.

### C10 — No new imports beyond V1; confirmed no circular import
Justified by **F14**. The import order in `django/db/models/__init__.py` guarantees
`lookups`/`Window` are available before `related_descriptors` loads, and the
`functions` package does not import back into the related/query modules.
