# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1 - Resolved Code Bug: Outer Prefetch Overwrote Inner Relation Cache

Input shape: `User.objects.only("email").prefetch_related(Prefetch("profile",
queryset=Profile.objects.prefetch_related(Prefetch("user",
queryset=User.objects.only("kind")))))`.

Observed in the public issue before the fix: `user.profile.user` behaved like
the outer `User.objects.only("email")` instance, so `kind` was deferred and
accessing it issued an extra query.

Expected from intent entries I1-I4: the inner `Profile.user` prefetch must win
for `Profile.user`, preserving the `User` instance whose `kind` field was
loaded.

V1 status: resolved. The reverse one-to-one descriptor now checks
`self.related.field.is_cached(rel_obj)` before seeding `Profile.user` with the
outer origin object.

## F2 - Resolved Code Bug: ForeignKey Reverse Variant Needed Same Rule

Input shape: the same graph with `Profile.user` as a `ForeignKey`, accessed as
`user.profile_set.all()[0].user.kind`.

Observed in the public issue before the fix: the issue states the same extra
query occurs for this ForeignKey variant.

Expected from intent entry I5: reverse many-to-one prefetch must also preserve
an already-cached child forward relation.

V1 status: resolved. The reverse many-to-one related manager now checks
`self.field.is_cached(rel_obj)` before assigning the origin object to the child
forward field.

## F3 - Preserved Behavior: Missing Caches Still Use Origin Object

Input shape: a descriptor prefetch where the fetched related object has no
nested prefetch or select-related cache for the relation being seeded.

Expected from intent entries I4 and I6: Django should keep the existing
optimization that seeds the origin object into the related object's cache.

V1 status: preserved. Each changed branch only skips the write when the relation
cache is already present; if the cache key is absent, the old write still
occurs.

## F4 - No Public Compatibility Finding

V1 changes only conditional guards around existing cache writes. Method
signatures, return tuple shapes, query filters, cache key names, and descriptor
protocols are unchanged.

## Proof-Derived Findings

No additional code bugs were derived from the proof obligations. The main proof
side condition is the intended one: `is_cached(rel_obj)` must mean "the
relation key is present in `_state.fields_cache`." This is directly provided by
`FieldCacheMixin.is_cached()`, so no new precondition or source edit is needed.

The proof is constructed, not machine-checked. Test removal is not recommended.

