# Baseline Notes

## Root cause

`TestCaseFunction.runtest` delayed `unittest.TestCase.tearDown` whenever `--pdb`
was active by saving the bound `tearDown` method in `_explicit_tearDown` before
letting `unittest` run the test case. Pytest then called `_explicit_tearDown`
during its teardown phase.

That worked for preserving instance state until postmortem debugging, but it
also meant pytest could no longer tell whether `unittest` would have called
`tearDown` at all. For a method skipped with `@unittest.skip`, `unittest` reports
the skip without running `setUp`, the test method, or `tearDown`; however,
pytest had already saved `tearDown`, so the later pytest teardown phase executed
it anyway.

## Changed files

`repo/src/_pytest/unittest.py`

Changed the `--pdb` teardown deferral to save the original bound `tearDown`
method in a local closure, then install a replacement `tearDown` method that
only records `_explicit_tearDown` when `unittest` actually reaches the teardown
phase. Pytest's existing `TestCaseFunction.teardown` logic still performs the
delayed call, but skipped tests leave `_explicit_tearDown` unset and therefore
do not run `tearDown`.

## Assumptions and alternatives

I assumed the correct behavior is to preserve normal `unittest` semantics:
`tearDown` should be delayed under `--pdb` only if `unittest` itself would have
called it. This covers decorator-skipped tests and setup failures, where
`tearDown` should not run, while keeping the delayed teardown behavior for
tests that reach teardown after passing, failing, or erroring.

I considered clearing `_explicit_tearDown` later when a skip report is produced,
but rejected that because it would infer behavior from the final outcome rather
than from whether `unittest` called `tearDown`. A skip raised from inside a test
method after successful setup may still be followed by `tearDown`, so the more
accurate signal is the intercepted `tearDown` call itself.

I also considered special-casing `unittest.skip` attributes before installing
the `--pdb` hook, but rejected that as too narrow: it would fix decorator skips
only and would not address other paths where `unittest` chooses not to run
`tearDown`, such as setup failures.
