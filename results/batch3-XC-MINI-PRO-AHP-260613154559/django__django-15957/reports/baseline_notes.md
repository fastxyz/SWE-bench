# Baseline notes — django__django-15957

## Issue

`Prefetch()` objects don't work with sliced querysets. For example:

```python
Category.objects.prefetch_related(Prefetch(
    'post_set',
    queryset=Post.objects.all()[:3],
    to_attr='example_posts',
))
```

raises `TypeError: Cannot filter a query once a slice has been taken.`

The use case is "show a few example children per parent" (e.g. 3 latest posts per
category) *without* loading every related row into memory and slicing in Python.

## Root cause

Prefetching works by taking the user-supplied `Prefetch` queryset and adding an
`<field>__in=<parent instances>` filter to it so the related rows for *all* parents can
be fetched in a single query and then grouped in memory
(`prefetch_one_level()` → each descriptor's `get_prefetch_queryset()`).

`QuerySet.filter()` refuses to add a `WHERE` clause once a `LIMIT`/`OFFSET` (a slice)
has been set (`QuerySet._filter_or_exclude` raises the `TypeError`). So as soon as the
provided queryset is sliced, prefetching blows up.

A correct, efficient implementation cannot simply append `LIMIT n` to the grouped query
(that would limit the *whole* result set, not per parent). The proper SQL is a
*top-N-per-group* query, which Django can now express because filtering against window
functions landed in this release (see `WhereNode.split_having_qualify`, the `QUALIFY`
handling). We can therefore replace the slice with a `ROW_NUMBER()` window partitioned
by the relation field and keep only the rows whose row number falls inside the requested
slice.

## Changes

### 1. `django/db/models/fields/related_descriptors.py`

* New imports: `DEFAULT_DB_ALIAS`, `NotSupportedError` (from `django.db`), `Window`
  (from `django.db.models`), `RowNumber` (from `django.db.models.functions`),
  `GreaterThan`, `LessThanOrEqual` (from `django.db.models.lookups`). All of these are
  already fully importable at the point `related_descriptors` is loaded
  (`django.db.models.__init__` imports `lookups` and `Window` before `fields.related`,
  and nothing in `django.db.models.functions` imports back into the related modules), so
  no circular-import risk is introduced.

* New helper `_filter_prefetch_queryset(queryset, field_name, instances)`:
  * Builds the usual `Q(field_name__in=instances)` predicate.
  * If the queryset is **not** sliced, behaviour is unchanged — it just returns
    `queryset.filter(predicate)`.
  * If it **is** sliced, it
    1. requires `supports_over_clause` (otherwise raises `NotSupportedError` with a clear
       message — window functions are the only portable way to do top-N-per-group),
    2. reads the slice bounds (`low_mark`/`high_mark`),
    3. reuses the queryset's own ordering (`compiler.get_order_by()`) for the window,
    4. adds `RowNumber() OVER (PARTITION BY field_name ORDER BY <ordering>)` bounded by
       `> low_mark` and (if present) `<= high_mark`,
    5. clears the limits and applies everything in a **single** `filter()` call so the
       `__in` join and the window's `partition_by` reuse the same join.

* `create_reverse_many_to_one_manager().get_prefetch_queryset()` and
  `create_forward_many_to_many_manager().get_prefetch_queryset()` now call this helper
  instead of doing `queryset.filter(**{f"{name}__in": instances})` directly. These are
  the two multi-valued relation descriptors where slicing is meaningful. For the m2m case
  the existing `_next_is_sticky()` call is preserved (passed through to the helper) so the
  join created for the `__in` lookup is reused by the window's `partition_by`.

### 2. `django/db/models/query.py`

`QuerySet._filter_or_exclude` raised the slice `TypeError` *before* the
`_defer_next_filter` branch. That branch exists specifically for
`RelatedManager._apply_rel_filters()`, which builds the cached relation queryset used by
prefetch results that have **no** `to_attr` (the result is supplied via `_result_cache`
and the deferred filter is never executed). The guard now also checks
`not self._defer_next_filter`, so a *deferred* filter no longer trips the slice check.

This makes the no-`to_attr` form work too:

```python
Category.objects.prefetch_related(Prefetch('post_set', Post.objects.all()[:3]))
# category.post_set.all() -> the 3 prefetched posts
```

`_defer_next_filter` is only ever set internally by the two `_apply_rel_filters()`
methods, and only on querysets whose results are provided directly, so this does not relax
the slice guard for any user-facing eager `filter()`/`exclude()` call. The existing test
`queries.tests…test_slicing_cannot_filter_queryset_once_sliced`
(`Article.objects.all()[0:5].filter(id=1)`) still raises, because that queryset has
`_defer_next_filter=False`. `queryset_pickle.tests.test_filter_deferred` is unaffected
because its queryset is not sliced.

## Assumptions / alternatives considered

* **Window functions are the intended mechanism.** The ticket discussion explicitly points
  at `Rank/RowNumber(partition_by=…)` + filtering against window functions, and that
  feature is present in this tree (`QUALIFY`/`split_having_qualify`). I relied on it rather
  than `Subquery`/`raw`, which would be less portable and harder to integrate with the
  existing in-memory join.

* **Backends without window functions.** Rather than silently loading everything, the
  helper raises `NotSupportedError` with an explanatory message. This keeps behaviour
  explicit and predictable.

* **Single-valued relations not changed.** `ForwardManyToOneDescriptor` and
  `ReverseOneToOneDescriptor` (forward FK / reverse O2O) return at most one related object
  per instance, so slicing the prefetch queryset is not meaningful; they continue to raise
  the original error. I deliberately did not add window logic there.

* **GenericRelation manager not changed.** Its prefetch query groups by content type with
  OR-ed predicates and per-type object-id sets; a correct partition would need
  `(content_type, object_id)` and is materially more complex. It is out of scope for this
  issue (which is about ordinary reverse-FK / m2m relations) and is left untouched.

* **Reused ordering vs. forcing a deterministic order.** I reuse the queryset's existing
  ordering. If the user supplied none, the window has no `ORDER BY`
  (`OrderByList` renders empty) and the result is non-deterministic — exactly the same
  guarantee an unordered sliced query already gives, so no behaviour is silently changed.

* **No-`to_attr` support.** I chose to support it because the issue title is general
  ("Prefetch objects don't work with slices") and the window fetch is identical with or
  without `to_attr`; the only obstacle was the eager slice guard during cache
  construction. The change is narrowly scoped to the deferred-filter path.
