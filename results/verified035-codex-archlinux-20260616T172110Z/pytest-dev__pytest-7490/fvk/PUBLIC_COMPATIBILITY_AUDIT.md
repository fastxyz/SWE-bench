# Public Compatibility Audit

Status: pass.

## Changed Symbols

`repo/src/_pytest/skipping.py`

- Added private store key `xfail_marks_key`.
- Added private helpers `_xfail_mark_count`, `_xfail_marks_changed`, and
  `_evaluate_xfail_marks_with_store`.
- Changed internal bodies of `pytest_runtest_setup`, `pytest_runtest_call`, and
  `pytest_runtest_makereport`.

## Public API Compatibility

No public function or method signatures changed.

`Node.add_marker` remains unchanged.

`FixtureRequest.applymarker` remains unchanged and still delegates to
`self.node.add_marker(marker)`.

Pytest hook signatures remain unchanged:

- `pytest_runtest_setup(item)`
- `pytest_runtest_call(item)`
- `pytest_runtest_makereport(item, call)`

Report shape remains unchanged. V1 only sets the existing `rep.outcome` and
`rep.wasxfail` fields through existing xfail report logic.

## Override/Callsite Compatibility

The new helpers are not public dispatch points and are not called by external
plugins. No subclass or hook override needs to accept a new argument or return a
new shape.
