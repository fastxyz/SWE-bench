# Intent Spec

Status: constructed, not machine-checked.

1. `sqrtdenest` must return an expression unchanged when it cannot denest it;
   it must not raise `IndexError` for the reported complex additive base.
2. `_sqrt_match` must reject flat non-surd additive bases such as `4 + I` rather
   than passing them into `split_surds`.
3. `split_surds` must be safe when no ordinary square-root surd terms are
   present.
4. `rad_rationalize` removes square roots; if no square-root component exists
   in an additive denominator, it must return unchanged instead of raising or
   recursing.
5. Valid square-root rationalization, including `sqrt(2) + I`, must keep
   working.
6. The repair must address the source condition and must not use bare exception
   handling.
