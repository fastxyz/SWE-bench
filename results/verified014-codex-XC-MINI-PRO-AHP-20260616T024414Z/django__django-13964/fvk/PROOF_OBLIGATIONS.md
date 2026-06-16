# Proof Obligations

Status: constructed, not machine-checked.

## O1: Empty-Value Refresh

For a cached relation field with a truthy related object, `obj.pk is not None`,
and `self.<field.attname> in field.empty_values`, save preparation must set
`self.<field.attname> = obj.pk` before cache comparison.

Trace: E1-E7, I1-I2, C1.

V1 status: DISCHARGED by the source change from `is None` to
`in field.empty_values`.

## O2: Unsaved-Object Guard Preservation

For a cached relation field with a truthy related object and `obj.pk is None`,
save preparation must raise the existing `ValueError` before applying the
empty-value refresh.

Trace: E8, I3, C2.

V1 status: DISCHARGED. The guard remains before the refreshed branch.

## O3: Cache Consistency After Refresh Opportunity

After any permitted refresh, if `obj.<target_attname>` differs from
`self.<field.attname>`, save preparation must clear the owner-side relation
cache.

Trace: E9, I4, C3.

V1 status: DISCHARGED. The cache comparison remains after the refresh branch.

## O4: Field-Loop Frame And Independence

The Python loop over `_meta.concrete_fields` must compose the per-field
transition without corrupting unrelated fields. A skipped field must preserve
its state; a processed field may only affect its own local relation value/cache
or raise.

Trace: D1, D3, FORMAL_SPEC_ENGLISH loop/frame obligation.

V1 status: DISCHARGED BY SOURCE STRUCTURE. The loop body refers to the current
`field`, uses that field's descriptors/cache helpers, and doesn't mutate other
fields except through that current field's `attname`.

## O5: Caller Coverage

All save paths that rely on relation-save preparation must use the repaired
function.

Trace: E10, PUBLIC_COMPATIBILITY_AUDIT.

V1 status: DISCHARGED. `save()` and `bulk_create()` both call the same repaired
method.

## O6: No Manual Attname Override Regression

If user code manually changes the local relation attname after caching the
relation, the relation cache must no longer authorize refresh from the old
cached object.

Trace: source `ForeignKeyDeferredAttribute.__set__()`, I5.

V1 status: DISCHARGED BY EXISTING SOURCE STRUCTURE. That descriptor deletes the
cached value when the attname changes, and `_prepare_related_fields_for_save()`
only reconciles fields where `field.is_cached(self)` is still true.
