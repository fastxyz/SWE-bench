# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO1 - Preserve Already-Cached Relation

For any fetched related object `REL`, relation cache key `KEY`, origin object
`ORIGIN`, and existing cached value `INNER`, if `REL.KEY` is cached before the
descriptor prefetch cache-seeding step, then after the step `REL.KEY` remains
`INNER`.

Trace: intent entries I1-I4; findings F1 and F2.

Discharge: V1 uses `if not <field>.is_cached(rel_obj)` before each descriptor
cache write. Since `FieldCacheMixin.is_cached()` is exactly key membership in
`_state.fields_cache`, the write is skipped when `INNER` is already cached.

## PO2 - Seed Missing Relation With Origin

For any fetched related object `REL`, relation cache key `KEY`, and origin
object `ORIGIN`, if `REL.KEY` is not cached before the descriptor prefetch
cache-seeding step, then after the step `REL.KEY == ORIGIN`.

Trace: intent entries I4 and I6; finding F3.

Discharge: the V1 guard is only `if not is_cached(...)`; the original
`set_cached_value()` or `setattr()` write remains inside that branch.

## PO3 - Cover the Public Relation Family

The preserve/seed winner rule must apply to:

- reverse one-to-one prefetch, for `User.profile` followed by
  `Profile.user`;
- reverse many-to-one prefetch, for `User.profile_set` followed by
  `Profile.user`;
- forward many-to-one prefetch where a non-multiple reverse cache is manually
  seeded.

Trace: intent entries I1, I4, I5, and I6; findings F1 and F2.

Discharge: V1 edits all three descriptor-side manual cache-seeding loops in
`related_descriptors.py`.

## PO4 - Frame Conditions

The fix must not change query construction, filtering, result matching,
prefetch tuple shape, public method signatures, or test files.

Trace: intent entry I6; finding F4.

Discharge: V1 adds only guards around existing writes. The surrounding
`queryset.filter()`, `rel_obj_attr`, `instance_attr`, `cache_name`, `single`,
and returned tuple values are unchanged.

## PO5 - Adequacy of the Abstract K Model

The model must distinguish the failing pre-fix behavior from the V1 behavior.

Trace: F1 and F2.

Discharge: the `seedIfMissing` transition has two branches. The cached branch
leaves the cache map unchanged; the missing branch writes the origin. Replacing
V1 with the pre-fix unconditional write would falsify `PRESERVE-CACHED-RELATION`
because the map entry would become `ORIGIN` instead of `INNER`.

