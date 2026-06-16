# Baseline Notes

## Root cause

`Prefetch()` accepts a custom queryset, but reverse relation prefetching adds
the relation constraint after receiving that queryset. When the custom queryset
has already been sliced, the later `.filter()` call trips Django's guard against
filtering a sliced query and raises `TypeError: Cannot filter a query once a
slice has been taken.`

For multi-valued relations, preserving the useful meaning of a sliced prefetch
requires applying the limit per related parent, not globally. The fix rewrites
the slice into `ROW_NUMBER()` window predicates partitioned by the relation key,
clears the original query limits, and then applies the normal prefetch relation
filter.

## Changed files

`repo/django/db/models/fields/related_descriptors.py`

Added `_filter_prefetch_queryset()`, which detects sliced querysets, checks that
the selected database supports window functions, converts `low_mark` and
`high_mark` into row-number predicates, clears the queryset limits, and applies
the supplied prefetch predicate. Reverse many-to-one and many-to-many prefetch
paths now use this helper. Their manager-level `_apply_rel_filters()` paths also
use it for sliced custom querysets so prefetches without `to_attr` do not fail
when the cached related manager queryset is constructed.

`repo/django/contrib/contenttypes/fields.py`

Updated reverse generic relation prefetching and its manager-level relation
filter path to use the same helper. Generic relations partition by both content
type and object id so the slice is applied per concrete source object.

## Assumptions and alternatives

I assumed sliced prefetch support is intended for multi-valued relations, where
`[:N]` naturally means "the first N related objects for each parent." I did not
change forward foreign key or reverse one-to-one prefetching because those are
single-valued relations and a per-parent top-N rewrite would not add useful
behavior.

I considered simply clearing the slice before applying the relation filter, but
that would fetch all related rows and recreate the performance problem described
in the issue. I also considered applying the slice globally after the relation
filter, but that would return only N total related rows across all parents,
which does not match the use case in the issue. The window-function approach
keeps the limit in SQL while applying it independently for each parent.

I did not run tests or project code, per the task instructions.
