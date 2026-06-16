# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent coverage | Verdict |
| --- | --- | --- |
| C-INIT-CUSTOM | Matches I-1, I-2, and I-3. | Pass |
| C-INIT-DEFAULT | Matches I-6 and validator-style default behavior from E-6. | Pass |
| C-DECONSTRUCT-CODE | Matches I-3 because migrations/clones reconstruct from deconstruction kwargs. | Pass |
| C-DECONSTRUCT-NOCODE | Matches I-6 by preserving old serialized output when code is omitted. | Pass |
| C-VALIDATE-CHECK | Matches I-4 for `CheckConstraint.validate()`. | Pass |
| C-VALIDATE-UNIQUE-EXPR | Matches I-4 for expression-based `UniqueConstraint.validate()`. | Pass |
| C-VALIDATE-UNIQUE-COND | Matches I-4 for conditional `UniqueConstraint.validate()`. | Pass |
| C-VALIDATE-UNIQUE-FIELDS-LEGACY | Matches I-5; it is a documented exception inherited from message behavior, not candidate-derived. | Pass |
| C-VALIDATE-EXCLUSION | Matches I-4 and E-7 for PostgreSQL `ExclusionConstraint.validate()`. | Pass |
| C-NO-VIOLATION | Matches I-6; adding a code parameter must not make non-violations raise. | Pass |

No claim is supported only by candidate behavior. The only excluded validation
branch, field-only `UniqueConstraint` without condition, is excluded because of
the public documentation entry E-5.

