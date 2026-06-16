# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Formal claim | Status |
| --- | --- | --- | --- | --- |
| PO-1 | DataFrame `fit` with fixed contamination emits no invalid-feature-names warning. | E-001, E-003, E-004, E-005 | C-FIT-NON-AUTO-NO-WARNING | Discharged in constructed proof. |
| PO-2 | Fixed-contamination `offset_` is still computed from training scores on the already validated training representation. | E-006, E-007 | C-FIT-NON-AUTO-OFFSET-FRAME | Discharged in constructed proof. |
| PO-3 | Public `score_samples` keeps reset=False validation and warning behavior for public user input. | E-008, E-013 | C-PUBLIC-SCORE-ARRAY-AFTER-NAMES-WARNS and C-PUBLIC-SCORE-DATAFRAME-AFTER-NAMES-NO-WARN | Discharged in constructed proof. |
| PO-4 | `contamination == "auto"` remains unchanged and does not use the non-auto scoring path. | E-002, E-006 | C-FIT-AUTO-UNCHANGED | Discharged in constructed proof. |
| PO-5 | Sparse fit data is scored as CSR when public validation is bypassed. | E-010, E-012 | C-SPARSE-FIT-SCORES-CSR | Discharged in constructed proof. |
| PO-6 | Public API signatures and return shapes remain unchanged. | E-007, E-011, compatibility audit | Public compatibility audit | Satisfied by source inspection. |
| PO-7 | The private scorer cannot emit feature-name warnings because it performs no feature-name validation. | E-005, E-008 | C-PRIVATE-SCORE-NO-VALIDATION-WARNING | Discharged in constructed proof. |

## Obligations intentionally outside this proof

- Full numerical correctness of IsolationForest tree scoring.
- Floating-point percentile implementation details.
- Termination and performance of fitting/scoring.
- Full sparse matrix implementation semantics beyond the CSC-to-CSR scoring
  representation obligation.
- External subclasses overriding `score_samples`; no in-repo overrides exist,
  and the public issue explicitly calls for an internal private scorer.
