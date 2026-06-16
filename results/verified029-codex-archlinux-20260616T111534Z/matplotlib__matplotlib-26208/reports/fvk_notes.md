# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the V1 `sharex()` edit discharges
the reported `twinx()` / categorical stackplot path, and the symmetric
`sharey()` edit is justified by the same shared-axis unit contract.

## Trace to Findings and Proof Obligations

- Finding F1 localizes the pre-V1 bug to a late shared-axis categorical unit
  broadcast. PO1-PO4 show V1 blocks that broadcast by copying the existing
  x-axis converter and units into the fresh twin before `ax2.plot()` processes
  string x data.
- Finding F2 confirms the V1 preservation path: after PO1, `_process_unit_info`
  sees `ax2.xaxis.have_units()` as true, so PO2 skips `update_units()`, PO3
  avoids `set_units()`, and PO4 frames `ax1.dataLim`.
- Finding F3 supports keeping the `have_units()` guard. PO5 shows V1 does not
  overwrite a receiving axis that already has unit state, which is the safer
  public-compatibility behavior for direct `sharex()` / `sharey()` calls.
- Finding F4 supports retaining the symmetric `sharey()` change. PO6 is the
  x/y-swapped version of PO1 and prevents the analogous shared-y late unit
  broadcast.
- Finding F5 rejects a broader `Axes.relim()` collection change. PO7 records
  that V1 changes no public signatures and leaves documented `relim()`
  collection behavior unchanged.

## Changes Made During FVK

No production source files were changed during this FVK pass. I added the FVK
artifacts under `fvk/`, including the requested five Markdown files and the
constructed mini-K core. I did not run tests, Python, `kompile`, `kast`, or
`kprove`.
