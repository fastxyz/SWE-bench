# Baseline Notes

## Root cause

`LogCaptureFixture.get_records(when)` returns the per-phase list stored in
`item.stash[caplog_records_key]`. During a phase, that stored list is the same
object as `caplog.records` / `LogCaptureHandler.records`.

`caplog.clear()` previously called `LogCaptureHandler.reset()`, which replaces
`handler.records` with a new list. The stash entry for the current phase still
pointed at the old list, so `get_records("call")` became detached from
`caplog.records`: it kept old records and did not receive records emitted after
`caplog.clear()`.

## Files changed

`repo/src/_pytest/logging.py`

- Added `LogCaptureHandler.clear()`, which clears the existing records list in
  place and resets the captured text stream.
- Changed `LogCaptureFixture.clear()` to call `handler.clear()` instead of
  `handler.reset()`, preserving the current phase records list identity that
  `get_records()` depends on.

## Assumptions and alternatives considered

- I kept `LogCaptureHandler.reset()` replacing the records list. Phase
  transitions use `reset()` before setup/call/teardown capture and then store
  the new list in the phase stash. If `reset()` cleared the list in place,
  entering a later phase would erase records saved for earlier phases.
- I considered updating the stash entry after `caplog.clear()`, but that would
  leave any existing references returned by `get_records()` detached in the
  same way. Clearing the list in place keeps all references consistent.
- I did not modify tests, and I did not run tests or project code, per the task
  constraints.
