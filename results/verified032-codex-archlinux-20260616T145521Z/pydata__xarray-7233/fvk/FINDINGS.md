# FVK Findings

Status: constructed, not machine-checked.

## F1 - Pre-fix coordinate demotion bug

Classification: code bug, fixed by V1.

Input: a dataset with variables `{T, day}`, coordinate set `{day}`, and
`window_dim` keys `{time}`.

Observed pre-fix mechanism: `should_be_coords = set(window_dim) &
set(self.obj.coords)` computes `{time} intersect {day} = {}`. The reshape loop
keeps `day` as a variable, but `set_coords` is not asked to classify it as a
coordinate, so `day` is exposed as a data variable.

Expected: per E1/E2/E3, `day` must remain a coordinate after construct.

Proof trace: `PREFIX-COUNTEREXAMPLE`; obligations PO1 and PO2 explain the
needed repair.

## F2 - V1 satisfies the coordinate-preservation obligation

Classification: V1 confirmed; no further source edit required.

Input class: any successful `Coarsen.construct` call where original coordinate
names are present in the original variable-name set.

Observed V1 mechanism: `should_be_coords = set(self.obj.coords)` passes every
original coordinate name to `Dataset.set_coords`.

Expected: every original coordinate remains a coordinate.

Proof trace: `COORD-PRESERVATION-V2`, `LOOP-PRESERVES-NAMES`, PO1, and PO2.

## F3 - Exact result-coordinate equality is not required by public intent

Classification: scope/adequacy note, not a source bug.

Input: a successful construct call where xarray's existing dimension-coordinate
rules may already classify some result variable as a coordinate before the final
`set_coords` call.

Observed V1 mechanism: V1 guarantees that original coordinates are included in
the result coordinate set; it does not attempt to remove any coordinate
classification established by existing xarray rules.

Expected: E2 requires original coordinates to stay coordinates. It does not
require the result coordinate set to equal exactly the original coordinate set.

Proof trace: I5 and SPEC_AUDIT "Exact equality of result coordinates".

## F4 - DataArray shared path remains compatible

Classification: compatibility confirmed.

Input: a DataArray with coordinate names `C` converted to a temporary dataset
with variables `C union {_THIS_ARRAY}`.

Observed V1 mechanism: `set(self.obj.coords)` is `C`, not `C union
{_THIS_ARRAY}`. The temporary data variable is not newly selected as a
coordinate by the V1 line.

Expected: DataArray coordinates are preserved and the method still returns
through `_from_temp_dataset`.

Proof trace: `DATAARRAY-TEMP-PRESERVATION` and PO3.

## F5 - Proof/tooling not executed

Classification: proof caveat.

The FVK proof is constructed but not machine-checked. Per the task constraints,
no tests, Python, `kompile`, or `kprove` commands were run. Test deletion is not
recommended from this unexecuted proof.

Proof trace: PO5 and PROOF "Machine-check commands".

