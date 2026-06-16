# SPEC_AUDIT

Status: constructed, not machine-checked.

| Formal claim | Intent item | Result | Notes |
| --- | --- | --- | --- |
| POINT-VALIDATEEVAL-PASS | 1, 2, 5 | pass | Covers real numeric coordinates under evaluated probe semantics, including residual zero cases. |
| POINT-VALIDATEEVAL-ERROR | 3, 5 | pass | Preserves rejection of numeric coordinates with evaluated nonzero imaginary part. |
| POINT-VALIDATE-PASS | 1, 2, 5 | pass | Covers the public top-level validation path under old ambient `evaluate(False)`. |
| POINT-VALIDATE-ERROR | 3, 5 | pass | Covers top-level error path and flag restoration. |
| POINT-SYMBOLIC-FRAME | 4 | pass | Preserves the `a.is_number` boundary for symbolic coordinates. |

No formal-English claim is legacy-derived without public intent support. The V1
behavior identified in F-001 is recorded as a finding, not accepted as the spec.
