# Public Compatibility Audit

Status: source-level compatibility audit; no tests or code execution performed.

## Changed Symbol

`matplotlib.ticker.LogLocator.nonsingular(self, vmin, vmax)`

- Signature: unchanged.
- Return type/shape: unchanged two-value limit tuple.
- New observable behavior: finite positive reversed inputs now return in the
  original reversed order rather than sorted order.
- Public-intent status: intentional, required by the issue and by axis
  inversion semantics.

## Callers and Consumers

`Axes.set_xlim` and `Axes.set_ylim`

- Both call the major locator's `nonsingular` before storing `viewLim`.
- For positive log limits, `LogScale.limit_range_for_scale` is an identity.
- Compatibility status: fixed behavior; reversed explicit log limits now match
  the documented axis API.

Autoscale path in `Axes._base.handle_single_axis`

- Autoscale derives increasing data intervals from data limits, then uses
  `set_xbound` / `set_ybound` to honor existing inversion.
- Compatibility status: no signature or protocol change; no source edit needed.

`LogLocator.view_limits`

- Calls `nonsingular` before optional decade rounding.
- Reversed direct inputs now preserve orientation. This is compatible with the
  same order-preservation requirement and does not affect the ordinary autoscale
  data path, which supplies increasing data intervals.

`LogLocator.tick_values`

- Explicitly sorts `vmax < vmin` internally for tick computation.
- Compatibility status: no break; tick calculation remains able to consume an
  inverted view interval.

Subclass/override audit

- No method signature changed.
- No new keyword argument or virtual-dispatch shape was introduced.
- No subclass override requires an update.

