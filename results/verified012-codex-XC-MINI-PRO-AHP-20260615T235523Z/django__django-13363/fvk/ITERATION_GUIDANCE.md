# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Rationale

The audit found the reported bug in two sibling methods:

- F1 / PO4: `TruncDate.as_sql()` must forward the explicit timezone to the date
  cast backend operation.
- F2 / PO5: `TruncTime.as_sql()` must forward the explicit timezone to the time
  cast backend operation.

V1 addresses both by replacing the hardcoded current-timezone lookup with
`self.get_tzname()`. That helper already discharges PO1, PO2, and PO3:
explicit timezone priority, current timezone fallback, and disabled timezone
support.

The compatibility audit discharges PO6. No backend signature, public method
signature, transform registration, validation branch, null handling path, or
params return shape changed.

## Future work outside this task

Add public regression tests for explicit `tzinfo` on both `TruncDate` and
`TruncTime`. The current task forbids editing tests, so this remains guidance
only.

Run the recorded K commands in `fvk/PROOF.md` in an environment with K installed
to upgrade the proof from constructed to machine-checked.

