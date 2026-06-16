# Spec Audit

Constructed, not machine-checked.

| Formal English item | Intent item(s) | Verdict | Rationale |
|---|---|---|---|
| C-001 | I-003, I-004 | Pass | This is the issue's exact failing shape: an existing index-like replacement variable is promoted, and the original object's dims must not change. |
| C-002 | I-003, I-004 | Pass | Ordinary variables were not the reported aliasing path, but the same no-mutation frame condition applies to all input variables. |
| C-003 | I-002, I-004 | Pass | Non-promoted variables still need rewritten dimensions in the returned dataset without mutating the input variables. |
| C-004 | I-004 | Pass as bug witness | It formalizes the legacy defect so the proof is localized to the mechanism that produced the reported symptom. It is not used as expected behavior. |
| C-005 | I-005 | Pass | The issue asks for no mutation after successful construction, not a validation behavior change. |
| FRC-001 | I-004 | Pass | Directly follows from the issue expectation and the "returns a new object" docstring. |
| FRC-002 | I-001, I-002, I-003 | Pass | The returned dataset is expected to carry swapped dimension metadata. |
| FRC-003 | I-006 | Pass with limitation | The model is intentionally scoped to the changed behavior. It is adequate for the aliasing bug but not a full xarray proof. |

No formal claim is candidate-derived without independent public intent support. No ambiguity blocks keeping V1.
