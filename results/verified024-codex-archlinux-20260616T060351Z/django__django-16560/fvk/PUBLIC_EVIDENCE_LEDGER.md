# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | "Allow to customize the code attribute of ValidationError raised by BaseConstraint.validate" | Add a public custom error-code path for constraint validation errors. | Encoded by PO-1, PO-3, PO-4, PO-5. |
| E-2 | `benchmark/PROBLEM.md` | "It is currently possible to customize the violation_error_message ... but not the code." | New code behavior should mirror the existing custom-message surface. | Encoded by PO-1 through PO-6. |
| E-3 | `benchmark/PROBLEM.md` public hint | "Agreed, adding violation_error_code sounds like a good idea..." | Parameter name is `violation_error_code`. | Encoded by PO-1. |
| E-4 | `repo/docs/ref/models/constraints.txt` | `BaseConstraint(*, name, violation_error_message=None)` and message description. | Existing default message behavior must be preserved when no custom message/code is supplied. | Encoded by PO-2 and PO-7. |
| E-5 | `repo/docs/ref/models/constraints.txt` | "This message is not used for UniqueConstraints with fields and without a condition." | Field-only `UniqueConstraint` without condition remains the legacy `unique_error_message()` path. | Encoded by PO-5. |
| E-6 | `repo/django/core/validators.py` | validators have class-level `code` defaults and `__init__(..., code=None)` overrides. | `None` should mean "leave default code unchanged"; a provided value should be stored. | Encoded by PO-1 and PO-2. |
| E-7 | Source scan under `repo/django` | Built-in constraint classes are `CheckConstraint`, `UniqueConstraint`, and PostgreSQL `ExclusionConstraint`. | All concrete built-in constraint-message validation paths must be audited. | Encoded by PO-3, PO-4, PO-5. |

