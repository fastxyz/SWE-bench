# Formal Spec English

Status: constructed, not machine-checked.

## LOOKUP-POW

Looking up the function string `pow` in the arithmetic operation table returns the operation `POW`.

## POW-PAIR

Applying operation `POW` to two non-null double values returns Java `Math.pow(lhs, rhs)`.

## POW-FOLD-TWO

Computing a `pow` arithmetic post-aggregator over two non-null numeric field results `[A, B]` returns `Math.pow(A, B)`.

## POW-FOLD-THREE

Computing a `pow` arithmetic post-aggregator over three non-null numeric field results `[A, B, C]` returns `Math.pow(Math.pow(A, B), C)`, matching left-to-right arithmetic post-aggregator evaluation.

## POW-NULL

If a `pow` arithmetic post-aggregator sees a null field result, it returns null before applying `Math.pow`.

## POW-CACHE-ORDER

The cache-key mode for `POW` preserves field order.
