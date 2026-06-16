# Constructed Proof

Status: constructed, not machine-checked. No K commands were run.

## Claims Proved

Claim C1: In the reported `twinx()` path, if `ax1` has categorical x units and
a valid stackplot `dataLim`, and the fresh twin `ax2` shares x with `ax1`, then
V1 makes `ax2.xaxis.have_units()` true before `ax2.plot(string_x, numeric_y)`.

Claim C2: Under C1 and with no explicit `xunits` override, `ax2.plot()` does
not call `update_units()` or `set_units()` for the shared x-axis group.

Claim C3: Under C2, `ax1._unit_change_handler("x")` is not invoked, so
`ax1.relim()` does not reset `ax1.dataLim`; therefore `ax1.dataLim` remains
valid.

Claim C4: The same unit-copy claim holds for `sharey()` with x/y swapped.

## Symbolic Execution Sketch

Initial abstract state after `ax1.stackplot(string_x, y1)`:

- `ax1.xaxis.have_units() = true`
- `ax1.xaxis.converter = category`
- `ax1.xaxis.units = U1`
- `ax1.dataLim = valid`
- `ax2` does not exist yet

Twin creation creates a fresh receiving x-axis:

- `ax2.xaxis.have_units() = false`
- `ax2.dataLim = null`

Entering `sharex(ax2, ax1)`:

1. The axes are joined in the shared x-axis group.
2. Ticker state is shared as before V1.
3. The V1 guard `not ax2.xaxis.have_units()` is true.
4. V1 assigns `ax2.xaxis.converter := ax1.xaxis.converter` and
   `ax2.xaxis.units := ax1.xaxis.units`.
5. Consequence: `ax2.xaxis.have_units() = true`.

Entering `ax2.plot(string_x, y2)`:

1. `_process_unit_info()` examines the x dataset.
2. Its unit-update guard is `not axis.have_units()`.
3. Since `ax2.xaxis.have_units() = true`, the x-axis call to
   `axis.update_units(data)` is skipped.
4. Because `update_units()` is skipped and no `xunits` override exists, no new
   categorical `UnitData` is created for the shared x-axis group.
5. Therefore `Axis.set_units()` is not called for shared x units on this path.
6. Therefore `axis.callbacks.process("units")` is not run for `ax1.xaxis`.
7. Therefore `ax1._unit_change_handler("x")` is not invoked.
8. Therefore `ax1.relim()` is not invoked by the reported path.

Frame step:

- The subsequent line addition is on `ax2`, so it updates `ax2.dataLim`.
- No modeled operation mutates `ax1.dataLim`.
- Hence `ax1.dataLim = valid` after `ax2.plot(...)`.

This proves PO1-PO4 for the issue path.

## Legacy Counterexample

If the V1 unit-copy assignment is removed:

1. `ax2.xaxis.have_units()` remains false after `sharex`.
2. `_process_unit_info()` on `ax2.plot(string_x, y2)` calls
   `ax2.xaxis.update_units(string_x)`.
3. The categorical converter creates a fresh `UnitData` and calls
   `set_units()` on the shared x-axis group.
4. `set_units()` processes the units callback for `ax1.xaxis`.
5. `ax1._unit_change_handler("x")` calls `ax1.relim()`.
6. `relim()` resets `ax1.dataLim` to null and skips the stackplot
   `PolyCollection`.

The resulting `ax1.dataLim = null` corresponds to the issue's `[inf, -inf]`
output. This counterexample localizes the defect to the missing shared-axis
unit inheritance rather than to autoscale or drawing.

## Adequacy Check

The proof's postcondition is exactly the public intent: `ax1.dataLim` remains
valid after plotting on `ax2`. The proof does not claim that `relim()` supports
collections, does not claim termination or rendering correctness, and does not
delete or weaken any public API.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They
were not executed here.

```sh
kompile fvk/mini-mpl-units.k --backend haskell
kast --backend haskell fvk/share-units-spec.k
kprove fvk/share-units-spec.k
```

Expected result if the abstract model is accepted by K: `#Top` for the claims
in `share-units-spec.k`.

## Test Recommendation

No test files were modified. A future public regression test should exercise
the issue path and assert that `ax1.dataLim.intervaly` remains equal to the
stackplot interval after `ax2.plot(...)`. No test removal is recommended unless
the constructed proof is later machine-checked.
