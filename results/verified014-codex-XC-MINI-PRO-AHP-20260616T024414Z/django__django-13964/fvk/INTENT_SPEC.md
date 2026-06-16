# Intent Spec

Status: constructed from public issue text and source inspection, not
machine-checked.

## Required Behavior

I1. When a model instance has a cached `ForeignKey` or `OneToOneField`
relation, and the cached related object has acquired a non-`None` primary key
after assignment, saving the owner must not persist a stale empty local foreign
key value. The local relation attname must be refreshed from the related
object's primary key before the write.

I2. The fix must cover the issue sequence:

1. `order.product = Product()` copies the related object's current CharField
   primary-key default, `""`, into `order.product_id`.
2. `order.product.sku = "foo"` changes the related object's primary key.
3. `order.product.save()` saves the related object.
4. `order.save()` must persist `order.product_id == "foo"`, not `""`.

I3. Existing protection against unsaved related objects remains required:
if a cached related object has `obj.pk is None`, save preparation must raise
the existing `ValueError` and must not silently write a nullable or stale
foreign key.

I4. Existing cache-consistency behavior remains required: if the cached related
object's target value no longer equals the owner's local relation attname after
the refresh opportunity, the owner-side relation cache must be cleared.

I5. Frame condition: fields without cached related objects, fields whose cached
related object is falsey, and non-empty local foreign key values are outside
the reported stale-empty-value repair and must keep existing behavior.

## Domain

D1. The formalized domain is `_prepare_related_fields_for_save()` for concrete
relation fields that are cached on the model instance.

D2. The primary target case is a `ForeignKey` to a related model whose primary
key is a non-auto `CharField`, because the issue gives this exact model family
and failure trace.

D3. The proof is partial correctness: if save preparation reaches the modeled
branch, the resulting local relation value and cache state satisfy I1-I5.
Termination of Django's finite concrete-field loop is assumed from ordinary
Python iteration over `_meta.concrete_fields`; no test or K tool was run.
