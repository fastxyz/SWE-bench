# Public Evidence Ledger

Status: public evidence only. Hidden tests, evaluator output, internet access,
and upstream patches were not used.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue | "Saving parent object after setting on child leads to data loss for parents with non-numeric primary key." | Saving the owner after saving the related object must not lose the related object's final primary key. | Encoded by I1, O1, C1. |
| E2 | prompt issue | `Product.sku = models.CharField(primary_key=True, max_length=50)` and `Order.product = models.ForeignKey(Product, ...)` | The in-scope concrete family is a `ForeignKey` to a `CharField` primary key. | Encoded by I2 and the `EmptyVal` claim. |
| E3 | prompt issue | `order.product = Product(); order.product.sku = "foo"; order.product.save(); order.save()` | Assignment happens before the primary key is populated; save preparation must reconcile the cached object with the local FK value. | Encoded by C1. |
| E4 | prompt issue | `Order.objects.filter(product_id="").exists()` succeeds but "shouldn't"; filtering by `product=order.product` fails. | Persisting `""` is the bug; the expected persisted value is `"foo"`. | Encoded by C1 and Finding F1. |
| E5 | public hint | "`product_id` is an empty string in `_prepare_related_fields_for_save()` that's why pk from a related object is not used. We could use `empty_values`..." | The repair target is the existing save-preparation branch that only refreshed on `None`; empty string must also be treated as unset for this reconciliation. | Encoded by O1 and C1. |
| E6 | source code | `ForwardManyToOneDescriptor.__set__()` copies `getattr(value, rh_field.attname)` into the local relation attname and caches the related instance. | The stale value is produced at assignment time and remains visible to save preparation while the relation cache is present. | Used as implementation evidence for the mini semantics. |
| E7 | source code | `Field._get_default()` returns `str` when empty strings are allowed and no default is provided. | A new `CharField(primary_key=True)` instance has `""` before the user assigns `"foo"`. | Used as implementation evidence for the `EmptyVal` pre-state. |
| E8 | source code | `_prepare_related_fields_for_save()` raises when `obj.pk is None`. | The unsaved-object protection is an independent required behavior. | Encoded by I3, O2, C2. |
| E9 | source code | `_prepare_related_fields_for_save()` clears the cached relation when target value and local attname differ. | Cache invalidation must remain after the refresh opportunity. | Encoded by I4, O3, C3. |
| E10 | source code | `save()` and `bulk_create()` both call `_prepare_related_fields_for_save()`. | The repaired transition applies to both save paths that use this shared preparation function. | Encoded by O5. |
