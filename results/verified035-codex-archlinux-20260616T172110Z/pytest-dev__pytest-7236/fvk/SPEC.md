# FVK Specification

Status: constructed, not machine-checked.

## Scope

The target is the V1 change in
`repo/src/_pytest/unittest.py::TestCaseFunction.runtest`, plus the existing
handoff in `TestCaseFunction.teardown`.

The formal model verifies the state transition that matters for the issue:

- whether pytest is running with `--pdb`;
- whether unittest actually reaches its own `tearDown` phase;
- whether pytest stores a delayed `tearDown` method in `_explicit_tearDown`;
- whether pytest's later item teardown invokes a delayed `tearDown`.

This intentionally does not model full pytest, full CPython unittest, terminal
reporting, PDB interaction, traceback formatting, or process termination.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- E-1/E-2: skipped unittest methods must remain skipped under `--pdb`; pytest
  must not run `tearDown` for such methods.
- E-4/E-5: tests that reach unittest teardown under `--pdb` must still have
  their real `tearDown` called later, after postmortem debugging can inspect
  pre-teardown instance state.
- E-6: pytest's own teardown phase calls `TestCaseFunction.teardown`, so the
  delayed-call slot is the control point.

## State Abstraction

`fvk/mini-pytest-unittest.k` defines:

- `<explicit>`: `none` or `saved`, representing `_explicit_tearDown`.
- `<delayedCalls>`: an integer count of real `tearDown` calls performed by
  pytest's delayed mechanism.
- `runtest(usepdb, unittestCallsTearDown)`: the abstract unittest call. The
  second argument is false for decorator-skipped tests and true for tests that
  reach unittest teardown.

The abstraction is property-complete for this issue because the reported
observable difference is exactly whether pytest's delayed mechanism executes
`tearDown` when unittest did not call it.

## Formal Claims

The K claims are in `fvk/pytest-unittest-teardown-spec.k`.

`SKIPPED-UNDER-PDB`: after setup, `runtest(true, false)`, and pytest teardown,
the delayed-call count is unchanged and `_explicit_tearDown` is empty.

`REACHED-TEARDOWN-UNDER-PDB`: after setup, `runtest(true, true)`, and pytest
teardown, the delayed-call count increases by exactly one and
`_explicit_tearDown` is empty.

`NO-PDB-NO-DELAYED-CALL`: after setup, `runtest(false, U)`, and pytest teardown,
the delayed-call count is unchanged and `_explicit_tearDown` is empty.

## Adequacy

The adequacy audit passes in `fvk/SPEC_AUDIT.md`: every formal claim maps to a
public intent item, and no claim relies on preserving the buggy legacy behavior.
The model discriminates V1 from the pre-fix behavior: if `runtest(true, false)`
saved `tearDown` before unittest ran, `teardown` would increment
`<delayedCalls>`, violating `SKIPPED-UNDER-PDB`.
