# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audited unit is `LogLocator.nonsingular` and its direct axis-limit call path:

`Axes.set_xlim` / `Axes.set_ylim` -> major locator `nonsingular` ->
`Axis.limit_range_for_scale` -> stored `viewLim.intervalx` / `viewLim.intervaly`.

The proof focuses on the observable that caused the bug: the order of the final
stored view-limit pair for finite positive unequal log limits.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations are:

- E1-E3: the issue requires `set_ylim(high, low)` to invert log axes just as it
  does linear axes.
- E4-E6: Matplotlib's axis API defines inversion by storing limits in reversed
  order.
- E7: the base locator already preserves reversed order when making intervals
  nonsingular.
- E8: the log scale range clamp is an identity for positive limits.
- E9: tick placement can sort locally without changing stored view limits.

## Contract

For all finite positive unequal limits:

- If `high > low > 0`, `LogLocator.nonsingular(high, low)` returns
  `(high, low)`.
- If `0 < low < high`, `LogLocator.nonsingular(low, high)` returns
  `(low, high)`.
- `LogScale.limit_range_for_scale` leaves both bounds unchanged.
- Therefore `set_ylim(high, low)` and `set_xlim(high, low)` on a log-scaled axis
  store `(high, low)`, making `Axis.get_inverted()` true.

Frame conditions:

- Nonpositive explicit axis limits remain governed by the existing warning and
  ignore logic in `set_xlim` / `set_ylim`.
- All-nonpositive data in `LogLocator.nonsingular` still falls back to `(1, 10)`.
- Equal positive limits still expand to avoid singular transforms.
- Tick generation remains free to sort reversed bounds internally for locating
  ticks.

## Implementation Mapping

V1 introduced `swapped = vmin > vmax`, sorts only for the existing log-domain
normalization checks, and returns `(vmax, vmin)` when `swapped` is true after
normalization. This mirrors `matplotlib.transforms.nonsingular(...,
increasing=False)` and preserves the explicit inversion order that the axis API
uses.

## K Artifacts

- `mini-python-log-limits.k` models the reduced order-preserving limit
  normalization fragment. Ordered integer scalars abstract finite positive
  Python numeric limits; the abstraction is property-complete for this bug
  because the observable is only pair order and positivity.
- `log-locator-spec.k` contains the K-style reachability claims corresponding
  to the contract above.

The artifacts are constructed but not machine-checked. The commands to check
them later are recorded in `PROOF.md`.

