# Formal Spec English

Status: constructed, not machine-checked.

The K claims in `constraint-validation-spec.k` model only the observable state
needed for this issue: stored violation code, deconstruction kwargs, and the
kind of validation outcome. Database lookup mechanics, expression evaluation,
and SQL generation are abstracted to boolean "violates" inputs because the issue
is about the error object raised after a violation has been detected.

## Claim paraphrases

C-INIT-CUSTOM: Constructing a constraint with `violation_error_code = C` stores
`C` as the constraint violation code.

C-INIT-DEFAULT: Constructing a constraint without a custom code leaves the stored
violation code as `NoCode`, matching the old default.

C-DECONSTRUCT-CODE: Deconstructing a constraint with stored code `C` includes
`violation_error_code = C` in serialized kwargs.

C-DECONSTRUCT-NOCODE: Deconstructing a constraint with no stored code omits
`violation_error_code` from serialized kwargs.

C-VALIDATE-CHECK: A violated `CheckConstraint` raises a validation error whose
code is the stored violation code.

C-VALIDATE-UNIQUE-EXPR: A violated expression-based `UniqueConstraint` raises a
validation error whose code is the stored violation code.

C-VALIDATE-UNIQUE-COND: A violated conditional `UniqueConstraint` raises a
validation error whose code is the stored violation code.

C-VALIDATE-UNIQUE-FIELDS-LEGACY: A violated field-only `UniqueConstraint`
without condition follows the legacy unique-error branch rather than the
constraint violation-message branch.

C-VALIDATE-EXCLUSION: A violated PostgreSQL `ExclusionConstraint` raises a
validation error whose code is the stored violation code.

C-NO-VIOLATION: If the abstract violation predicate is false, validation returns
without raising a validation error.

