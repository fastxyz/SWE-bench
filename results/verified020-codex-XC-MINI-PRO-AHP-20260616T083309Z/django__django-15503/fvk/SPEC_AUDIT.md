# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent link | Result | Notes |
|---|---|---|---|
| C-001 | I-001, I-002, E-001, E-002, E-003, E-004 | pass | This is the reported defect. |
| C-002 | I-003, E-005 | pass | Prevents a too-broad fix that would break nested list lookup behavior. |
| C-003 | I-001, E-001, E-003, E-004 | pass | The issue names all three lookup variants. |
| C-004 | I-004, E-006 | pass after V2 | V1 failed this audit; V2 adds `final_key=False` internal calls. |
| C-005 | I-005 | pass | The patch frames templates and logical operators. |
| C-006 | I-002, E-007 | pass | PostgreSQL code remains unchanged. |

No formal-English claim is broader than public intent. The only V1 mismatch was
C-004; it is recorded as Finding F-002 and repaired in V2.
