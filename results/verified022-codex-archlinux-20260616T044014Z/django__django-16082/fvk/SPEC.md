# SPEC

Status: constructed, not machine-checked.

## Target

The audited unit is Django's `CombinedExpression` output-field type inference in
`repo/django/db/models/expressions.py`, specifically:

- `_connector_combinations`, the declarative table of result field types.
- The registration loop that feeds `_connector_combinators`.
- `_resolve_combined_type(connector, lhs_type, rhs_type)`.
- `CombinedExpression._resolve_output_field()`.

The observable under verification is whether a numeric expression using the MOD
connector receives an inferred result field class or falls through to
`FieldError`.

## Intent-Only Contract

For mixed numeric MOD expressions involving `DecimalField` and `IntegerField` in
either operand order, Django must infer `DecimalField`, matching the mixed
numeric behavior already used by other arithmetic operators. The change must not
alter public function signatures or broaden unrelated unsupported combinations.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Key entries:

- E1: The problem title requires resolving `output_field` for numeric MOD
  expressions.
- E2: The problem description requires Decimal/Integer mixed MOD to resolve to
  Decimal.
- E3: The public hints distinguish this issue from same-type modulo and identify
  mixed numeric types as the target.
- E5: The existing mixed numeric table maps Integer/Decimal to Decimal and
  Integer/Float to Float for other arithmetic connectors.
- E6: The source comment says missing table items intentionally remain
  `FieldError`, so the repair must not add unrelated combinations.

## Formal Model

Supporting files:

- `fvk/mini-combined-expression.k`
- `fvk/combined-expression-spec.k`

The model abstracts the relevant Python table behavior to:

- `Connector`: `add`, `sub`, `mul`, `div`, `mod`, `pow`.
- `FieldType`: `integer`, `integerSub`, `decimal`, `float`, `other`.
- `resolve(connector, lhs, rhs)`: returns `some(field)` when a registered
  combination exists or `noType` when the modeled unsupported combination remains
  absent.

This abstraction keeps the property under test visible: a passing implementation
maps `resolve(mod, decimal, integer)` to `some(decimal)`, while the pre-fix table
maps it to `noType`/`None` and therefore raises `FieldError` in
`CombinedExpression._resolve_output_field()`.

## Formal Claims

The K claims state:

- `resolve(mod, decimal, integer) => some(decimal)`
- `resolve(mod, integer, decimal) => some(decimal)`
- `resolve(mod, decimal, integerSub) => some(decimal)`
- `resolve(mod, integer, float) => some(float)`
- `resolve(mod, float, integer) => some(float)`
- `resolve(pow, decimal, integer) => noType`
- `resolve(pow, integer, decimal) => noType`

There are no loop circularities for this target. The proof obligation is finite
table construction plus resolver lookup, not iterative numeric computation.

## Source-Level Spec

V1 satisfies the contract by adding `Combinable.MOD` to the existing mixed
numeric connector tuple:

```python
for connector in (
    Combinable.ADD,
    Combinable.SUB,
    Combinable.MUL,
    Combinable.DIV,
    Combinable.MOD,
)
```

The table rows remain:

- `IntegerField, DecimalField -> DecimalField`
- `DecimalField, IntegerField -> DecimalField`
- `IntegerField, FloatField -> FloatField`
- `FloatField, IntegerField -> FloatField`

Since `_resolve_combined_type()` uses `issubclass()`, those rows also cover
integer-field subclasses.

## Frame Conditions

- Same-type numeric MOD behavior remains registered by the pre-existing
  same-type numeric connector list.
- Numeric-with-NULL MOD behavior remains registered by the pre-existing NULL
  connector list.
- Mixed numeric POW remains unsupported because the issue and existing table do
  not require it.
- No public signature, callsite protocol, or test file is changed.
