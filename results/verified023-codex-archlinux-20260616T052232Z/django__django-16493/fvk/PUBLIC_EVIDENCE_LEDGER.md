# Public Evidence Ledger

Status: constructed for audit; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | issue | "Callable storage on FileField fails to deconstruct when it returns default_storage" | Callable storage returning `default_storage` is in domain and must deconstruct correctly. | Encoded by O2 and claim `CALLABLE-DEFAULT`. |
| E2 | issue | "it is omitted from the deconstructed form of the field, rather than being included as a reference to the callable as expected" | Expected output has `storage` present and equal to the callable. | Encoded by O2 and FVK-F1/FVK-F2. |
| E3 | issue | "makemigrations will randomly generate a migration that alternately includes or omits storage=myapp.models.get_storage" | Deconstruction must depend on the original callable argument, not its nondeterministic evaluated result. | Encoded by O2 and O5. |
| E4 | issue | "deconstruct method tests if self.storage is not default_storage ... but at this point self.storage is the evaluated version" | Comparing the evaluated storage is the root-cause mechanism for the omission. | Encoded by FVK-F1. |
| E5 | issue hint | "when hasattr(self, '_storage_callable') that should unconditionally be used by deconstruct" | Presence of `_storage_callable` selects the original callable for deconstruction. | Encoded by O2 and O5. |
| E6 | issue hint | "use getattr(self, '_storage_callable', self.storage) in both lines" | The same selected storage value must drive both default comparison and serialized kwarg assignment. | Encoded by O2, O3, O4, O5. |
| E7 | docs/ref/models/fields.txt | "`FileField(storage=None)`" and "A storage object, or a callable which returns a storage object" | Both direct storage objects and callable storage providers are public inputs. | Encoded by O2, O3, O4. |
| E8 | docs/howto/custom-model-fields.txt | "`deconstruct()` ... tell Django ... what arguments to pass to `__init__()` to recreate it" | Deconstruction kwargs should reconstruct the original field configuration. | Encoded by O1 and O2. |
| E9 | public test | "Deconstructing gives the original callable, not the evaluated value." | Existing callable-non-default behavior must be preserved. | Encoded by O4. |
| E10 | implementation | `__init__()` stores callable storage on `_storage_callable` before evaluating it. | Implementation state available for proving callable preservation. | Used in proof model; not an intent source by itself. |
| E11 | implementation | V1 `deconstruct()` uses `storage = getattr(self, "_storage_callable", self.storage)`. | Candidate mechanism selects original callable when present. | Audited by O2-O5. |
