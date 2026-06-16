# Proof Obligations

Status: constructed, not machine-checked.

## PO1: `sharex()` copies unit state for a fresh receiving x-axis

Evidence: E3/E4; Finding F2.

Precondition:

- `self.xaxis.have_units()` is false.
- `other.xaxis.converter = C`.
- `other.xaxis.units = U`.

Obligation:

- After `sharex(self, other)`, `self.xaxis.converter = C` and
  `self.xaxis.units = U`.

Discharge:

- V1 assigns `self.xaxis.converter = other.xaxis.converter` and
  `self.xaxis.units = other.xaxis.units` under `if not self.xaxis.have_units()`.

## PO2: `ax2.plot()` does not call `update_units()` for shared x data after PO1

Evidence: E3; Findings F1/F2.

Precondition:

- PO1 has run for `ax2.sharex(ax1)`.
- `ax2.xaxis.have_units()` is true because either converter or units is set.
- `ax2.plot()` reaches `_process_unit_info()` with string x data.

Obligation:

- `_process_unit_info()` skips `axis.update_units(data)` for the x dataset.

Discharge:

- Source condition is `if axis is not None and data is not None and not
  axis.have_units(): axis.update_units(data)`. With `have_units()` true, the
  body is not executed.

## PO3: No replacement categorical unit is broadcast to `ax1`

Evidence: E1-E3; Findings F1/F2.

Precondition:

- PO2 holds.
- No explicit `xunits` keyword supplies a different unit.

Obligation:

- `Axis.set_units()` is not called for `ax2.xaxis` during the x-unit processing
  of the reported `ax2.plot()` path.

Discharge:

- Without `update_units()` and without an explicit `xunits` change, the only
  remaining x conversion is `axis.convert_units(data)`, which converts through
  the existing shared categorical unit object and may update that mapping but
  does not call `set_units()`.

## PO4: `ax1.dataLim` is framed across `ax2.plot()`

Evidence: E1/E2; Findings F1/F2.

Precondition:

- PO3 holds.
- `ax1.dataLim` is valid before `ax2.plot()`.

Obligation:

- `ax1._unit_change_handler("x")` is not invoked by the reported path, so
  `ax1.relim()` is not called by that path, so `ax1.dataLim` remains valid.

Discharge:

- `axis.callbacks.process("units")` occurs in `Axis.set_units()`. PO3 excludes
  that call on the shared x-axis path. The later line addition is to `ax2`, not
  to `ax1`, so it updates `ax2.dataLim` only.

## PO5: Existing receiving-axis units are preserved

Evidence: E4; Finding F3.

Precondition:

- `self.xaxis.have_units()` is true before `sharex()` or
  `self.yaxis.have_units()` is true before `sharey()`.

Obligation:

- V1 does not overwrite that receiving axis' existing converter or units.

Discharge:

- The V1 assignments are guarded by `if not ...have_units()`.

## PO6: `sharey()` mirrors `sharex()` for the analogous y-axis case

Evidence: E4; Finding F4.

Precondition:

- `self.yaxis.have_units()` is false.
- `other.yaxis.converter = C`.
- `other.yaxis.units = U`.

Obligation:

- After `sharey(self, other)`, `self.yaxis.converter = C` and
  `self.yaxis.units = U`.

Discharge:

- V1 assigns `self.yaxis.converter = other.yaxis.converter` and
  `self.yaxis.units = other.yaxis.units` under `if not self.yaxis.have_units()`.

## PO7: Public compatibility

Evidence: E4/E5; Findings F3/F5.

Obligation:

- The repair must not alter public method signatures, return values, or
  documented `relim()` collection support.

Discharge:

- V1 adds no parameters and changes no return shape. It only initializes
  missing unit state on the receiving shared axis. It does not change
  `Axes.relim()`.
