# Baseline Notes

## Root cause

During `prefetch_related()`, Django seeds relation caches on fetched related
objects so they point back to the origin instances. For example, when
prefetching `User.profile`, the fetched `Profile` has its `user` cache set to
the outer `User` instance.

That optimization did not check whether the relation had already been cached by
an explicit nested prefetch on the related queryset. In the reported case,
`Profile.objects.prefetch_related(Prefetch("user", queryset=User.objects.only("kind")))`
correctly cached a `Profile.user` instance with `kind` loaded, but the outer
`User.profile` prefetch then overwrote that cache with the origin `User`
instance loaded by `User.objects.only("email")`. Accessing
`user.profile.user.kind` therefore saw `kind` as deferred and issued an extra
query.

## Changed files

`repo/django/db/models/fields/related_descriptors.py`

The manual cache seeding in forward many-to-one, reverse one-to-one, and reverse
many-to-one prefetch paths now checks whether the target relation is already
cached before writing the origin instance. This preserves the existing
origin-object cache behavior when no nested prefetch or select-related object
has populated the relation, while allowing explicit nested prefetch results to
remain attached to the fetched object.

## Assumptions

The nested prefetch or select-related cache is more specific than the generic
origin-object assignment and should take precedence when it is already present.
This follows the issue's expectation that `Profile.user` should be the instance
loaded by the inner `User.objects.only("kind")` queryset.

The same precedence rule should apply to reverse many-to-one prefetches because
the issue states the same deferred-field behavior occurs for a `ForeignKey`
reverse relation.

## Alternatives considered

One option was to merge loaded fields from the nested `User` instance into the
outer origin `User` instance. I rejected that because Django model instances do
not generally merge partially-loaded state during prefetch, and doing so would
be broader and riskier than preserving the explicit cached relation.

Another option was to raise an exception for this graph shape. I rejected that
because the requested behavior is well-defined: the inner prefetch has already
loaded the requested fields, and preserving its cache fixes the extra query
without making the query unsupported.

I also considered changing `prefetch_one_level()` directly, but the overwrite
happens in the descriptor `get_prefetch_queryset()` methods while they seed
reverse/forward caches. Guarding those existing writes is the narrower fix.
