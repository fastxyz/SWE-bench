# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | V1 status |
| --- | --- | --- | --- |
| PO-1 | Public constructors accept optional `violation_error_code` and store it when provided. | I-1, I-2, E-3, E-6 | Discharged by `BaseConstraint.__init__` and super calls from concrete constraints. |
| PO-2 | Omitting `violation_error_code` preserves the old no-code default. | I-6, E-4, E-6 | Discharged by class default `violation_error_code = None` and assignment only when argument is not `None`. |
| PO-3 | Deconstruction and clone preserve a custom code and omit absent code. | I-3 | Discharged by `BaseConstraint.deconstruct()` adding the kwarg only when non-`None`; `clone()` reconstructs from deconstruction. |
| PO-4 | `CheckConstraint.validate()` attaches the stored code to constraint-message `ValidationError`s. | I-4, E-7 | Discharged by the updated `ValidationError(..., code=self.violation_error_code)` call. |
| PO-5 | `UniqueConstraint.validate()` attaches the stored code to expression and conditional constraint-message errors, while preserving the documented field-only legacy branch. | I-4, I-5, E-5, E-7 | Discharged by updated expression/condition raises and unchanged `unique_error_message()` branch. |
| PO-6 | PostgreSQL `ExclusionConstraint.validate()` attaches the stored code to both validation error branches. | I-4, E-7 | Discharged by both updated `ValidationError(..., code=self.violation_error_code)` calls. |
| PO-7 | Equality and representation account for custom codes consistently with custom messages. | I-3 | Discharged by adding `violation_error_code` to `__eq__()` and `__repr__()` in concrete constraints. |
| PO-8 | Existing no-code callers and in-repo public callsites remain compatible. | I-6, PUBLIC_COMPATIBILITY_AUDIT PC-1..PC-5 | Discharged by optional defaults and static callsite/subclass audit. |

## Branch coverage

The obligations cover every in-scope branch that raises a validation error using
`get_violation_error_message()`:

- `CheckConstraint.validate()`
- `UniqueConstraint.validate()` for expression constraints
- `UniqueConstraint.validate()` for conditional constraints
- `ExclusionConstraint.validate()` without `condition`
- `ExclusionConstraint.validate()` with `condition`

The field-only `UniqueConstraint` branch without `condition` is explicitly
covered as a legacy non-goal by PO-5.

