# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent match | Reason |
| --- | --- | --- |
| C1 | Pass | E1 and E2 require `ValidationError.params['value']`; E5 confirms params interpolation. |
| C2 | Pass | E1 says "provided value"; helper-derived values are implementation details, not the submitted value. |
| C3 | Pass | The issue asks for error context, not changed validity decisions. |

No formal clause preserves legacy behavior contradicted by the public issue.
No formal clause relies on hidden tests or evaluator output.
