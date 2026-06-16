# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`acreate()`, `aget_or_create()`, and `aupdate_or_create()` doesn't work as intended on related managers" | All three async methods must be audited as a family on related managers. | Encoded by PO1-PO3. |
| E2 | prompt | "they don't call `create()`, `get_or_create()`, and `update_or_create()` respectively from a related manager but from the `QuerySet`" | The postcondition is dispatch to the related manager sync method, not to the queryset proxy. | Encoded by K claims and PO1-PO3. |
| E3 | prompt hint | Added `sync_to_async` import and local `acreate()` examples in `related_descriptors.py` | Proper async wrappers may be implemented as `sync_to_async(self.<sync_method>)`. | Implemented in V1 and encoded by PO1-PO2. |
| E4 | source | `BaseManager._get_queryset_methods()` creates manager proxies that call `getattr(self.get_queryset(), name)(*args, **kwargs)` | Missing local async methods on a manager cause dispatch to `self.get_queryset()` and then to queryset methods. | Root-cause model in `mini-related-manager.k`. |
| E5 | source | Reverse many-to-one sync `create()`/`get_or_create()`/`update_or_create()` set `kwargs[self.field.name] = self.instance` | Reverse FK async methods must preserve bound-instance injection. | PO1. |
| E6 | source | Many-to-many sync `create()` calls `self.add(new_obj, through_defaults=through_defaults)`; get/update add on creation | M2M async methods must preserve link creation and `through_defaults`. | PO2. |
| E7 | public tests | `m2m_through` tests require `through_defaults` on `create()`, `get_or_create()`, and `update_or_create()` | The async m2m wrappers should expose and forward `through_defaults`, not only `**kwargs`. | PO2 and PO5. |
| E8 | source/tests | `GenericRelatedObjectManager` sync methods populate content type and object id; generic relation tests state related-manager get/update-or-create should work | Generic relations are the same dispatch shape and should receive async wrappers. | PO3. |
| E9 | source/tests | Normal queryset async tests cover `SimpleModel.objects.acreate()` and related methods | Do not alter normal manager/queryset async dispatch. | PO4. |
| E10 | source/prompt hint | Sync related methods and issue hint mark mutating methods with `alters_data = True` | New async wrappers should be marked mutating. | PO6. |

