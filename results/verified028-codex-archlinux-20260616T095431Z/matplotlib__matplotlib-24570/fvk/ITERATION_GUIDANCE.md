# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found that the V1 branch swap discharges the
public intent for `HPacker(align="bottom")` and `HPacker(align="top")`, while
preserving the expected `VPacker(align="left")` and `VPacker(align="right")`
behavior.

## No Additional Source Changes

Do not add a migration flag, temporary uppercase alignment values, or new packer
classes in this iteration. FINDINGS F-004 records why those alternatives were
rejected for this targeted issue.

Do not add a `VPacker` compatibility shim for `align="top"/"bottom"` in this
iteration. FINDINGS F-005 records the residual ambiguity and why it does not
override the helper's documented lower/far edge model.

## Tests to Add or Keep

Do not modify tests in this benchmark task.

A future public test should exercise an `HPacker` with two child boxes of
different heights:

- `align="bottom"` should produce equal child bottom edges.
- `align="top"` should produce equal child top edges.
- `VPacker(align="left")` and `VPacker(align="right")` should remain unchanged.

No tests should be removed based on this FVK pass because the proof is
constructed, not machine-checked.
