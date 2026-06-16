# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| PO-001 | I-001, I-002 | pass | Directly encodes the issue's requested fixed-vocabulary behavior and the existing feature-index ordering contract. |
| PO-002 | I-002 | pass | Preserves the already-fitted/materialized path and feature-index ordering. |
| PO-003 | I-003 | pass | Keeps unfitted/no-vocabulary behavior as `NotFittedError`; no public side-effect frame is asserted. |
| PO-004 | I-004 | pass | Keeps existing invalid-vocabulary errors instead of weakening validation. |
| PO-005 | I-005 | pass | The V1 source change adds no parameters and does not alter virtual dispatch shape. |

No formal item is marked fail or ambiguous. The result remains constructed, not machine-checked, because K tooling was not run.

