# Formal Spec in English

Status: English paraphrase of the K-style claims in `log-locator-spec.k`.

## C1: Log Locator Preserves Reversed Positive Limits

For all ordered scalar values `HIGH`, `LOW`, and `MINPOS`, if
`HIGH > LOW > 0` and `MINPOS > 0`, then
`LogLocator.nonsingular(HIGH, LOW)` returns `(HIGH, LOW)`.

This says the locator may sort internally to perform log-domain checks, but it
must restore the original reversed orientation for finite positive unequal
limits.

## C2: Axis-Level Log Limits Stay Inverted

For all `HIGH > LOW > 0`, `set_ylim(HIGH, LOW)` or `set_xlim(HIGH, LOW)` on a
log-scaled axis stores the interval `(HIGH, LOW)` after locator normalization
and log-scale clamping. Because `Axis.get_inverted` is `high < low`, the stored
interval is inverted.

## C3: Normal Positive Limits Are Unchanged

For all `0 < LOW < HIGH`, `LogLocator.nonsingular(LOW, HIGH)` returns
`(LOW, HIGH)`. The fix does not invert normal ordered limits.

## C4: Positive Log Scale Clamp Is an Identity

For all positive finite limits, `LogScale.limit_range_for_scale` leaves each
bound unchanged. Therefore preserving order in the locator is sufficient for
the final axis view interval.

## C5: Nonpositive and Singular Branches Are Not Widened

All-nonpositive data still falls back to `(1, 10)`. Equal positive limits still
expand through `_decade_less` and `_decade_greater`. These branches are not used
by the issue's finite positive unequal limit pair.

## C6: Tick Calculation Frame Condition

`LogLocator.tick_values` may sort reversed positive bounds for tick placement,
but that sorting is local to the tick calculation and does not mutate the axis
view interval.

