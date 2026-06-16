# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Reshape loop preserves variable names

Statement: after the `for key, var in obj.variables.items()` loop in
`Coarsen.construct`, every original variable name is present in `reshaped`.

Evidence: source line pattern in `repo/xarray/core/rolling.py`: the loop assigns
`reshaped[key] = ...` on both the reshaped and unchanged branches.

Why it matters: `Dataset.set_coords` asserts requested names exist in the
dataset. Coordinate preservation cannot be proved unless every original
coordinate name remains a variable name.

Status: discharged by `LOOP-PRESERVES-NAMES`.

## PO2 - Final coordinate set includes all original coordinates

Statement: for every `c in set(self.obj.coords)`, `c` is in the result's
coordinate-name set after `result = reshaped.set_coords(should_be_coords)`.

Evidence: V1 sets `should_be_coords = set(self.obj.coords)`, and
`Dataset.set_coords` updates `_coord_names` with all provided names.

Why it matters: this is the issue's explicit expected behavior.

Status: discharged by `COORD-PRESERVATION-V2`.

## PO3 - DataArray temporary variable is not accidentally promoted

Statement: on the DataArray path, the V1 fix preserves real DataArray
coordinates while not depending on `_THIS_ARRAY` being a coordinate.

Evidence: `DataArray._to_temp_dataset` creates `coord_names = set(self._coords)`
and stores the data variable as `_THIS_ARRAY`. `set(self.obj.coords)` therefore
contains only real DataArray coordinates.

Why it matters: `Coarsen.construct` is shared by Dataset and DataArray.

Status: discharged by `DATAARRAY-TEMP-PRESERVATION`.

## PO4 - Public API compatibility is preserved

Statement: V1 must not change `Coarsen.construct` arguments, return kind, or
public dispatch expectations.

Evidence: V1 edits only a local set expression and does not add parameters,
change return branches, or call virtual methods with new arguments.

Why it matters: the repair should be minimal and not regress callers.

Status: discharged by `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO5 - Honesty gate for verification status

Statement: proof and test-redundancy conclusions must be labeled constructed,
not machine-checked, because no K tooling or tests are run in this session.

Evidence: task constraints explicitly forbid tests, Python, `kompile`, and
`kprove`.

Why it matters: FVK permits constructed proofs but does not allow claiming
machine-checked success or deleting tests without running the emitted commands.

Status: discharged by labels in `SPEC.md`, `PROOF.md`, and `FINDINGS.md`.

