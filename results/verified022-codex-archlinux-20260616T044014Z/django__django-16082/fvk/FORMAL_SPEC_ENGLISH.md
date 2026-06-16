# Formal Spec in English

Status: constructed, not machine-checked.

The formal model in `mini-combined-expression.k` abstracts Django's resolver to
the part relevant to this issue: a connector, two field-family inputs, and a
result of either `some(FieldType)` or `noType`.

The claims in `combined-expression-spec.k` state:

1. Resolving `mod` with `decimal` on the left and `integer` on the right reaches
   `some(decimal)`.

2. Resolving `mod` with `integer` on the left and `decimal` on the right reaches
   `some(decimal)`.

3. Resolving `mod` with `decimal` and an `integerSub` reaches `some(decimal)`,
   modeling Django's `issubclass()` behavior for integer-field subclasses.

4. Resolving `mod` for `integer`/`float` and `float`/`integer` reaches
   `some(float)`, because V1 applies MOD to the existing mixed numeric table
   rather than hand-coding only the Decimal/Integer row.

5. Resolving mixed Decimal/Integer `pow` reaches `noType`; mixed numeric power is
   outside the public issue and remains absent from the mixed numeric connector
   family.

There are no loop circularities in this target. The resolver scan is modeled as
the finite table relation induced by `_connector_combinations` and
`issubclass()`.
