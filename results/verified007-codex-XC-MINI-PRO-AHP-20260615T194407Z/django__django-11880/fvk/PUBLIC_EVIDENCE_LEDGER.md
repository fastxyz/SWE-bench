# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`__deepcopy__` ... performs a shallow copy of self and does not include additional treatment for the `error_messages` dictionary." | The field copy operation must explicitly copy `error_messages`. | Encoded by `FIELD-DEEPCOPY-COPY-ERRORS` and PO-1. |
| E2 | `benchmark/PROBLEM.md` | "all copies of the same field share the same dictionary" | The observable defect is shared identity of the error_messages mapping. | Encoded as distinct heap object ids in the K model. |
| E3 | `benchmark/PROBLEM.md` | "any modification of either the dictionary or the error message itself for one formfield is immediately reflected on all other formfields" | The copy must be deep enough to isolate nested mutable message values. | Encoded by PO-2 and the use of `copy.deepcopy()`. |
| E4 | `benchmark/PROBLEM.md` | "each instance of the specific form ... is expected to have a set of fields sealed away from other instances" | The field-copy contract must support form instance isolation through `copy.deepcopy(base_fields)`. | Encoded by PO-4. |
| E5 | `repo/django/forms/forms.py` | `self.fields = copy.deepcopy(self.base_fields)` | Form construction invokes field `__deepcopy__()` on declared fields. | Implementation evidence supporting PO-4. |
| E6 | `repo/django/forms/fields.py` | `result.widget = copy.deepcopy(self.widget, memo)` and `result.validators = self.validators[:]` | The fix should preserve existing widget and validator copy behavior unless intent requires otherwise. | Encoded by PO-3. |
| E7 | `repo/django/forms/fields.py` and `repo/django/forms/models.py` | Field subclasses call `super().__deepcopy__(memo)` or route to `Field.__deepcopy__()`. | The base method fix reaches normal Field subclasses. | Encoded by PO-4 and compatibility audit. |
