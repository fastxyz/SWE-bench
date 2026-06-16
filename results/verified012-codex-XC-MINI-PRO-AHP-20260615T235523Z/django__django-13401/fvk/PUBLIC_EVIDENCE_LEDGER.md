# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Abstract model field should not be equal across models" | Equality must distinguish owning model for copied abstract fields. | Encoded by PO-EQ-OWNER. |
| E2 | prompt | "fields only consider self.creation_counter when comparing for equality" | `creation_counter` alone is insufficient identity. | Encoded by PO-EQ-OWNER and FVK-F1. |
| E3 | prompt | `len({B._meta.get_field('myfield'), C._meta.get_field('myfield')}) == 1` | Set behavior must retain both fields after the fix. | Encoded by PO-SET-CARDINALITY. |
| E4 | prompt | "if the field.model is different, they will compare unequal" | Different `field.model` values imply inequality, even with the same counter. | Encoded by PO-EQ-OWNER. |
| E5 | prompt | "adjust __hash__ and __lt__ to match" | Hash and ordering must be coherent with owner-sensitive equality. | Encoded by PO-HASH-CONSISTENCY and PO-LT-COLLISION. |
| E6 | prompt | "order first by self.creation_counter" | `__lt__` must not reorder ordinary different-counter fields by model. | Encoded by PO-LT-PRIMARY-COUNTER. |
| E7 | implementation | `copy.deepcopy(field)` in abstract inheritance and `self.model = cls` in `contribute_to_class()` | Copied fields preserve counters; model owner is available before `_meta.add_field()` ordering. | Used as implementation semantics for PO-ABSTRACT-CLONE. |
| E8 | implementation | `bisect.insort(self.local_fields, field)` with comment "using the creation_counter" | Field ordering drives local field insertion; preserve counter-first order. | Supports PO-LT-PRIMARY-COUNTER. |
