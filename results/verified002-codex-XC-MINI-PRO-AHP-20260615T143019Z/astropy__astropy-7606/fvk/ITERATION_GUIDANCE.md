# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Rationale

F-001 and F-002 identify the operative defect: known conversion failures in
`UnrecognizedUnit.__eq__` escaped instead of returning `False`. PO-005 is
discharged by the V1 `try`/`except (ValueError, UnitsError, TypeError)` guard.

F-003 confirms V1 preserves the existing name-based equality semantics for
unknown units, discharging PO-002 and PO-003.

F-005 confirms there is no compatibility regression: `__ne__`, direct
`Unit(None)`, public signatures, and invalid operator behavior are unchanged,
discharging PO-006 through PO-008.

F-004 records the only considered alternative: replacing the typed exception
tuple with a broad `except Exception`. That change is rejected because the
public issue and `UnitBase.__eq__` justify only known unit-conversion failure
classes, and a broad catch would hide unrelated implementation bugs.

## Next Steps

No additional source edit is recommended.

If tests could be changed in a normal development setting, add coverage for:

- `u.Unit('asdf', parse_strict='silent') == None` returns `False`;
- `u.Unit('asdf', parse_strict='silent') != None` returns `True`;
- same-name and different-name unknown-unit equality remain unchanged.

Run the emitted K commands and the project test suite in an environment where
execution is allowed. This benchmark phase did not run either.
