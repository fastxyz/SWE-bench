# Spec Audit

Status: adequacy gate for the constructed formalization.

| Formal claim | Intent entries | Audit | Notes |
| --- | --- | --- | --- |
| C1: `canDelete=False` adds no `DELETE`. | I6 | Pass | Directly follows from the public option name and existing formset behavior. |
| C2: `canDeleteExtra=True` permits `DELETE` on extra/empty forms. | I5 | Pass | Default behavior keeps deletion for extra forms; empty form is the extra-form template. |
| C3: empty form with extra deletion disabled adds no `DELETE` and raises no exception. | I1, I2, I3 | Pass | This is the reported bug and the intended repair. |
| C4: initial indexed forms keep `DELETE` when extra deletion is disabled. | I4 | Pass | Supported by public tests and deletion semantics for existing objects. |
| C5: indexed extra forms omit `DELETE` when extra deletion is disabled. | I3 | Pass | Supported by docs and public tests. |
| C6: nonnegative count/index domain. | I8 | Pass | `initial_form_count()` is a count; normal form indexes are nonnegative. |
| C7: frame compatibility. | I7 | Pass | The patch changes only the delete condition and preserves signature/dispatch. |

No claim is derived solely from V1 behavior. No claim preserves the reported
legacy `TypeError`. No required behavior is marked ambiguous or failed.
