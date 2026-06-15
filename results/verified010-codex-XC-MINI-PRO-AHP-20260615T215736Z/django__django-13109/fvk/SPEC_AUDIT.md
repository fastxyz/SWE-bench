# Spec Audit

Status: constructed for audit; not machine-checked.

| Formal claim or condition | Intent match | Reason |
| --- | --- | --- |
| `FK_BASE_MANAGER_ACCEPTS` | Pass | Directly matches E1, E2, E3, and E4. |
| `FK_BASE_MANAGER_REJECTS_MISSING` | Pass | Existence validation still rejects values not visible through the base manager; this is the DB-existence purpose named by E4. |
| `FK_LIMIT_CHOICES_STILL_APPLIES` | Pass | E6 shows explicit relation limits are already part of validation, and the issue only changes manager selection. |
| `FK_LEGACY_DEFAULT_MANAGER_FAILS_ARCHIVED` | Pass as symptom model, not desired behavior | This claim localizes the bug by showing how the legacy manager choice produces E3. It is not used to justify current behavior. |
| Routing frame condition | Pass | E8 shows routing is existing behavior and public intent does not request routing changes. |
| Formfield defaults unchanged | Pass | E5 places the change in model validation; the form example already demonstrates overriding the field queryset. |

No formal-English obligation is candidate-derived without public evidence. No
claim depends on a hidden test, original upstream fix, or evaluator result.
