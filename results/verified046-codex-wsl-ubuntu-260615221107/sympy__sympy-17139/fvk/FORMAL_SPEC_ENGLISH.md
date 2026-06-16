# Formal Spec English

The K model in `mini-sympy-fu.k` abstracts one `_TR56` visit to a target power
by classifying its exponent as non-integer, symbolic integer, or concrete
integer.

## Claim `NONINTEGER-UNCHANGED`

For every `max` and `pow` mode, a non-integer exponent returns `unchanged`.
This means no ordered comparison or perfect-power operation is performed for
complex exponents such as `I`.

## Claim `SYMBOLIC-POW-UNCHANGED`

For every `max`, a symbolic integer exponent in `pow=True` mode returns
`unchanged`. This models the V2 guard that avoids passing non-concrete integer
expressions to `perfect_power`.

## Claim `NEGATIVE-UNCHANGED`

A concrete negative integer exponent returns `unchanged`.

## Claim `MAX-UNCHANGED`

A concrete integer exponent greater than `max` returns `unchanged`.

## Claim `EXP2-REWRITE`

Concrete exponent `2` returns the base rewrite decision.

## Claim `EXP4-REWRITE`

Concrete exponent `4` returns the half-exponent rewrite decision with exponent
`2`.

## Claim `POW-FALSE-EVEN`

With `pow=False`, concrete even exponent `6` within `max` rewrites with
half-exponent `3`.

## Claim `POW-FALSE-ODD`

With `pow=False`, concrete odd exponent `3` returns `unchanged`.

## Claim `POW-TRUE-SIX`

With `pow=True`, concrete exponent `6` returns `unchanged`.

## Claim `POW-TRUE-EIGHT`

With `pow=True`, concrete exponent `8` rewrites with half-exponent `4`.

## Claim `POW-TRUE-NINE`

With `pow=True`, concrete exponent `9` returns `unchanged`.
