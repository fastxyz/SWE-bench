# Formal Spec In English

Status: constructed, not machine-checked.

## Claim OUTERREF-SHIFT

For an original user value equivalent to `OuterRef('pk')`, after `split_exclude()` inserts its generated nested subquery and the query is resolved through the generated query, the immediate parent query, and the enclosing query, the reference binds to the enclosing query level. In the public issue shape, this is the `Number` query, not the `Item` query.

## Claim PLAIN-F-PRESERVED

For an original user value equivalent to a plain `F('local_field')`, after the same generated-subquery lifecycle, the reference binds to the immediate parent query level. This preserves the existing compensation for local `F()` expressions in `split_exclude()`.

## Claim NON-EXPRESSION-PRESERVED

For a value that is neither `OuterRef` nor `F`, the `split_exclude()` scope transformation leaves the value unchanged.

## Claim V0-COUNTEREXAMPLE

Under the pre-V1 behavior where an `OuterRef('pk')` was effectively re-created as another single-level `OuterRef('pk')`, the generated-subquery lifecycle binds the reference to the immediate parent query level. In the public issue shape, this is the wrong `Item` level identified by the hint.

