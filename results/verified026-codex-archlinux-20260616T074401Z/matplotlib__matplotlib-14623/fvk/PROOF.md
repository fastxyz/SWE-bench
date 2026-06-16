# Proof

Status: constructed, not machine-checked.

## Claims Proved in the Constructed Model

The constructed K-style artifacts are:

- `mini-python-log-limits.k`
- `log-locator-spec.k`

They model ordered finite scalar limits, the `LogLocator.nonsingular` branch
structure relevant to this bug, the positive log-scale range clamp, and the
axis-level inversion predicate.

## Proof Sketch

### C1: `LogLocator.nonsingular(HIGH, LOW)` for `HIGH > LOW > 0`

1. The precondition makes the finite checks true.
2. The comparison `vmin > vmax` sets `swapped = True`.
3. The local sorted values become `(LOW, HIGH)`.
4. The all-nonpositive fallback is unreachable because `HIGH > 0`.
5. `minpos` is irrelevant because sorted `LOW > 0`.
6. The singular branch is unreachable because `HIGH != LOW`.
7. The final return checks `swapped` and returns `(HIGH, LOW)`.

This discharges PO1.

### C2: Axis-Level Inversion

1. `Axes.set_ylim` / `Axes.set_xlim` accept the finite positive explicit
   limits, so the nonpositive warning branches are unreachable.
2. The major locator call returns `(HIGH, LOW)` by C1.
3. `LogScale.limit_range_for_scale` is the identity on both positive bounds.
4. The axis stores `(HIGH, LOW)` in the view interval.
5. `Axis.get_inverted` returns `high < low`; here that is `LOW < HIGH`, true.

This discharges PO2 and PO3.

### C3: Normal Ordered Limits

When `0 < LOW < HIGH`, `swapped = False`, none of the invalid or singular
branches is reached, and the final return is `(LOW, HIGH)`. This discharges PO4.

### C4: Frame Conditions

All-nonpositive and nonfinite fallback behavior remains outside the positive
explicit limit contract. Equal positive limits still route through decade
expansion. Tick generation still sorts reversed bounds locally in `tick_values`.
These facts discharge PO5 and PO6 as frame conditions.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They
were not executed in this session.

```sh
kompile fvk/mini-python-log-limits.k --backend haskell
kast --backend haskell fvk/log-locator-spec.k
kprove fvk/log-locator-spec.k
```

Expected machine-check result after a successful proof: `#Top`.

## Test Guidance

After machine-checking, a focused unit test asserting that a log axis preserves
`set_ylim(high, low)` or `set_xlim(high, low)` for `high > low > 0` would be
subsumed by PO1-PO3. Rendering, integration, invalid-limit warning, and tick
placement tests are not subsumed by this narrow proof and should be kept.

