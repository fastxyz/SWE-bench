# Formal Spec in English

This is a paraphrase of the K claims in `bulk-update-spec.k`.

1. For any field reference name `NAME`, if the value seen by `bulk_update()` is expression-like and represents `F(NAME)`, then the modeled update path reaches `Column(NAME)`. In Django terms, the value is kept as an expression and later resolved to the referenced column.
2. For any literal string value `V` with no `resolve_expression` method, the modeled update path reaches `Param(V)`. In Django terms, the value is wrapped in `Value(V, output_field=field)` and compiled as a bound parameter.
3. For any other expression-like node `ExprNode(SQL)`, the modeled update path preserves it as an expression-like node rather than wrapping it as a literal.

Loop/frame paraphrase for the source loops in `bulk_update()`:

- The batch loop partitions `objs` and preserves the pointwise obligation for every object in every batch.
- The field loop builds one `Case` expression per requested field and preserves the pointwise obligation for every requested field.
- The object loop builds one `When(pk=obj.pk, then=normalized_attr)` per object and preserves object order, PK filtering, and field association.

All proof statements are partial-correctness statements: if the modeled update-construction path reaches a result, that result satisfies the postcondition. Termination and database execution effects are not machine-checked by this FVK run.
