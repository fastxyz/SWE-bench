# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 repair for `django__django-16560`: adding
customizable validation error codes to Django model constraints. The formal
model abstracts away SQL generation, database querying, `Q` expression
evaluation, and queryset internals. Those mechanics determine whether a
constraint is violated; the issue is about the observable after a violation is
detected: the `ValidationError.code` value.

## Intent ledger

The standalone evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The
obligations used by the spec are:

- `violation_error_code` is the public parameter name.
- A supplied code is stored on the constraint.
- A missing code preserves the old default of no validation error code.
- Deconstruction and cloning preserve a supplied code.
- Validation paths that use `get_violation_error_message()` pass the stored
  code to `ValidationError`.
- Field-only `UniqueConstraint` without `condition` remains the documented
  legacy `unique_error_message()` path.
- Optional new constructor parameters do not break existing callers.

## Abstract state

The formal core in `mini-constraint-validation.k` represents only:

- `Code`: `NoCode` or `Code(String)`;
- `Kind`: the concrete validation branch under audit;
- `Outcome`: no result, successful validation, a constraint validation error
  carrying a code, or the legacy unique-error branch;
- `kwargs`: the migration/deconstruction keyword map.

The discriminator is adequate for this issue: a passing implementation maps a
violated constraint-message branch with `Code("x")` to
`ValidationError(Code("x"))`; the pre-fix implementation maps the same branch to
`ValidationError(NoCode)`. The model distinguishes those outcomes.

## Source obligations

S-1. `BaseConstraint.__init__` stores `violation_error_code` when provided and
leaves the old `None` default when omitted.

S-2. `BaseConstraint.deconstruct()` serializes `violation_error_code` only when
it is not `None`; `clone()` therefore preserves custom codes through
deconstruction.

S-3. `CheckConstraint.validate()` raises
`ValidationError(self.get_violation_error_message(), code=self.violation_error_code)`
on constraint-message violations.

S-4. `UniqueConstraint.validate()` does the same for expression-based unique
constraints and conditional unique constraints.

S-5. `UniqueConstraint.validate()` keeps field-only, no-condition constraints on
`instance.unique_error_message()`, because the public docs state that
`violation_error_message` is not used for that branch.

S-6. `ExclusionConstraint.validate()` raises validation errors with
`code=self.violation_error_code` on both unconditional and conditional violation
paths.

S-7. Equality and `repr()` include `violation_error_code` where they already
include `violation_error_message`, so two constraints that differ only by code
are not treated as the same developer-visible object.

## Formal artifacts

- `fvk/mini-constraint-validation.k`
- `fvk/constraint-validation-spec.k`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

