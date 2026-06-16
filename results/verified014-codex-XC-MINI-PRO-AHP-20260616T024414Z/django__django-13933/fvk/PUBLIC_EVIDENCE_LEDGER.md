# Public Evidence Ledger

Status: constructed from public evidence, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "ModelChoiceField does not provide value of invalid choice when raising ValidationError" | Invalid-choice errors must expose the rejected value. | Encoded by PO-2 and K claims `INVALID-SUBMITTED` / `INVALID-MODEL-KEY` / `INVALID-BAD-TYPE`. |
| E-002 | `benchmark/PROBLEM.md` | "Compared with ChoiceField and others" | Match the established choice-field convention for `%(value)s`. | Encoded by PO-3. |
| E-003 | `benchmark/PROBLEM.md` | "Passing in parameters with the invalid value and modifying the default error message for the code invalid_choice should fix this." | Both params and default message must change; either change alone is incomplete. | Encoded by PO-2 and PO-3. |
| E-004 | `repo/django/forms/fields.py` | `ChoiceField.validate()` raises `ValidationError(..., params={'value': value})`. | `params['value']` is the public convention for invalid choices. | Supporting evidence for PO-2. |
| E-005 | `repo/django/forms/models.py` | `ModelMultipleChoiceField.default_error_messages['invalid_choice']` includes `%(value)s` and `_check_values()` passes `params={'value': val}`. | Single and multiple model choice fields should expose invalid values consistently. | Supporting evidence for PO-2 and PO-3. |
| E-006 | `repo/django/forms/models.py` | `ModelChoiceField.to_python()` returns `None` for empty values and returns `queryset.get(...)` for valid values. | Preserve existing non-error behavior. | Encoded by PO-4. |
| E-007 | Public test evidence | Existing tests in `tests/model_forms/test_modelchoicefield.py` assert the old default text. | These are legacy-behavior evidence, not an oracle, because the issue names the old text as the defect. | Recorded as F-002; no test files edited. |

