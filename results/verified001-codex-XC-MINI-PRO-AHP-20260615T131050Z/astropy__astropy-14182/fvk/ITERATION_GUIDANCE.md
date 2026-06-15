# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged. The FVK audit found no open finding that requires another
source edit for the public issue contract.

## Why V1 Stands

- F-001 is discharged by O1: the constructor accepts and forwards
  `header_rows`.
- F-002 is discharged by O3 and O4: separator placement is derived from the
  configured header-row count, while default output remains unchanged.
- F-003 is discharged by O5: readback line indexing is adjusted for additional
  header rows.
- O6 found no public compatibility issue with the optional constructor keyword.

## What Not To Change in This Iteration

- Do not add bespoke RST header-row formatting. O2 shows the intended behavior
  is already supplied by the fixed-width base class, which the issue uses as the
  comparison point.
- Do not modify tests. The benchmark forbids test edits, and FVK test-removal
  recommendations are conditional on machine-checking.
- Do not expand the patch to no-header RST output or empty-table behavior in this
  task. F-004 and F-005 record those as outside the public issue and proof
  domain, not as justified repairs.

## Future Work If Product Scope Expands

- Clarify whether `ascii.rst` should support `header_rows=[]` as a no-header
  simple table.
- Clarify whether fixed-width/RST writers should support empty tables with
  header rows.
- Materialize the K-style claims into standalone `.k` files and run the commands
  recorded in `fvk/PROOF.md` in an environment with K installed.

