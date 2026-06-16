# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Formal claim | Intent item | Result | Notes |
| --- | --- | --- | --- |
| C-INDPTR handles `n_SV >= 0` | Intent 1, Intent 2 | pass | The public issue explicitly names empty `support_vectors_` and expects no error. |
| C-CSR shape `(n_class, n_SV)` | Intent 2, Intent 3 | pass | Matches SVR and classifier documentation for `dual_coef_` row counts. |
| C-NONREGRESSION for `n_SV > 0` | Intent 3, Intent 4 | pass | Ensures ordinary non-empty sparse fits keep the same row boundaries. |
| C-FRAME only changes `dual_coef_indptr` | Intent 4 | pass | The source diff changes one expression and does not alter public call signatures. |

No formal-English obligation is weaker than the public issue intent. No
candidate-derived behavior was accepted as an expected result without public
support.
