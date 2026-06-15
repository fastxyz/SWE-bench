# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt/problem | "`delete()` on instances of models without any dependencies doesn't clear PKs." | The no-dependencies fast-delete case is in scope. | Encoded in PO1 and `OPT-FAST-SINGLE-CLEAR-PK`. |
| E2 | prompt/problem | "It should be set to None after .delete() call." | Successful instance deletion must set the model instance's PK attribute to `None`. | Encoded in PO1. |
| E3 | prompt/hint | "mimics what ... does for multiple objects" | Existing collected-instance cleanup is the reference behavior. | Encoded in PO2 and `NORMAL-COLLECTED-CLEAR-PK`. |
| E4 | source: `repo/django/db/models/base.py` | `Model.delete()` asserts `self.pk is not None`, collects `[self]`, then returns `collector.delete()`. | The observable instance-delete contract is implemented by `Collector.delete()`. | Used to localize the proof target. |
| E5 | source: `repo/django/db/models/deletion.py` | `can_fast_delete()` requires no cascades, parents, delete/m2m signal listeners, or private bulk-related fields. | A true fast-delete predicate excludes the relation/update paths that populate `field_updates`. | Encoded in PO3. |
| E6 | source: `repo/django/db/models/deletion.py` | The normal path updates field values, then sets `model._meta.pk.attname` to `None` for collected instances. | Normal collected deletes already satisfy PK cleanup. | Encoded in PO2. |
| E7 | source: `repo/django/db/models/query.py` | `QuerySet.delete()` deletes a queryset and clears `_result_cache`; it does not return or mutate a specific instance. | Queryset-only fast deletes are a frame condition, not the reported instance-state obligation. | Encoded in PO6. |
| E8 | source diff | V1 adds `setattr(instance, model._meta.pk.attname, None)` after `delete_batch()` in the optimized branch. | V1 directly discharges the missing cleanup after successful SQL deletion. | Finding F1 resolved. |
