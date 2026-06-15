# Formal Spec English

Status: constructed, not machine-checked.

## CHECKBOX-CONTEXT-NO-MUTATE

Starting with caller attrs represented by `attrs(C)`, where `C` records whether the caller explicitly supplied `checked`, rendering one checkbox with boolean value `V` leaves the caller attrs as `attrs(C)`. The emitted subwidget has `checked` exactly when `C` was already true or `shouldCheck(V)` is true.

## SPLIT-ARRAY-CHECKED-INDEPENDENT

Starting with a list of boolean values `VS` and one attrs object represented by `attrs(C)`, rendering the split array leaves the attrs object represented by `attrs(C)` after every iteration. The output checked list is `expected(VS, C)`, meaning each position is checked exactly when `C` was originally true or that position's own value is true.

## REPRODUCTION-FALSE-TRUE-FALSE

For the reported failure shape with no explicit `checked` attr and values `[False, True, False]`, the rendered checked flags are `[False, True, False]`, not `[False, True, True]`.

## Frame Conditions

The K model abstracts all attrs except the presence of `checked`. The source-level frame condition is that copying attrs before adding generated `checked` preserves all other keys and values in the returned context while leaving the caller dictionary unchanged.
