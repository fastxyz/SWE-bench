# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the V1 guard in
`UnrecognizedUnit.__eq__` discharges the issue's intended behavior without
requiring additional source edits.

## Trace to Findings and Proof Obligations

- Kept the V1 `except (ValueError, UnitsError, TypeError): return False`
  change because F-001 identifies the reported `None` comparison as a
  `TypeError` conversion failure, and PO-005 requires known conversion
  failures to return `False` without escaping.
- Kept the exception tuple aligned with `UnitBase.__eq__` because F-002 shows
  the defect applies to the known unit-conversion failure family, and PO-001
  fixes the formal domain to recognized units, unrecognized units, and those
  known rejection exceptions.
- Did not add a broad `except Exception` because F-004 records that public
  evidence does not justify swallowing unrelated internal errors, and PO-008
  requires avoiding public compatibility regressions or broader API-policy
  changes.
- Did not change name-based unknown-unit comparison because F-003 confirms the
  existing same-name and different-name behavior is intended, with PO-002 and
  PO-003 discharging those cases.
- Did not change `__ne__`, direct `Unit(None)`, parsing, signatures, or invalid
  `UnrecognizedUnit` operators because F-005 found no compatibility issue, and
  PO-006 through PO-008 require those frame conditions to remain intact.

## Verification Status

The FVK proof is constructed, not machine-checked. I wrote the commands to run
later in `fvk/SPEC.md` and `fvk/PROOF.md`, but did not run K tooling, tests, or
Python code because this benchmark phase forbids execution.
