# Baseline Notes

## Root cause

`Axes.set_xlim` and `Axes.set_ylim` pass explicit user limits through the
major locator's `nonsingular` method before storing them in `viewLim`.
For log-scaled axes, `LogLocator.nonsingular` sorted reversed limits with:

```python
if vmin > vmax:
    vmin, vmax = vmax, vmin
```

That removed the ordering information that Matplotlib uses to represent an
inverted axis. As a result, calling `set_ylim(high, low)` on a log axis was
normalized back to increasing order, while the same operation on a linear axis
preserved the reversed order.

## Files changed

`repo/lib/matplotlib/ticker.py`

Changed `LogLocator.nonsingular` to remember whether the incoming limits were
reversed, continue applying the existing log-domain and singular-range
normalization on sorted values, and then restore the original orientation in
the returned limits. The all-nonpositive fallback remains unchanged because
that path produces a default valid log interval rather than normalizing an
otherwise valid explicit limit pair.

## Assumptions and alternatives considered

I assumed that reversed explicit limits are a public API for axis inversion and
that locator validation should not discard that semantic information.

I considered changing `Axes.set_xlim` and `Axes.set_ylim` to preserve order
around the locator call, but rejected that because the regression is specific
to the log locator's normalization and the base `Locator.nonsingular` already
preserves reversed input with `increasing=False`.

I considered changing log scale range limiting in `scale.py`, but rejected that
because `LogScale.limit_range_for_scale` only clamps nonpositive values and
does not reorder positive limits.

No tests or runtime checks were run, following the benchmark instruction not to
run code or tests in this session.
