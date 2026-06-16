# Intent Spec

Status: constructed, not machine-checked.

## Required Behaviors

1. `CombinedExpression` must infer an `output_field` for numeric expressions using
   the MOD connector when the operands are mixed numeric types covered by
   Django's arithmetic type-resolution table.

2. For Decimal/Integer modulo in either operand order, the inferred result type
   must be `DecimalField`.

3. The fix must preserve existing behavior for same-type numeric modulo,
   numeric-with-NULL modulo, and intentionally unsupported connector/type
   combinations that are absent from the registry.

4. The public API shape must remain unchanged: no signature change to
   `register_combinable_fields()`, `_resolve_combined_type()`, or
   `CombinedExpression._resolve_output_field()`.

## Domain

The verified domain is type inference for `CombinedExpression` over registered
numeric field classes and subclasses, with focus on the MOD connector. Database
SQL execution semantics and backend-specific numeric runtime values are outside
this proof; the issue concerns `output_field` resolution before query execution.

## Default-Domain Assumptions

- Django field subclasses satisfy Python `issubclass()` in the usual way.
- `IntegerField` in the issue means the integer field family, including Django
  subclasses such as `AutoField`, `BigIntegerField`, and related integer fields.
- The existing mixed numeric table is the intended source of truth for result
  type promotion among Integer/Decimal and Integer/Float pairs.
