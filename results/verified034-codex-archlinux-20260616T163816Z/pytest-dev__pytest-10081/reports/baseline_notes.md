# Baseline Notes

## Root Cause

`TestCaseFunction.runtest` delays `unittest.TestCase.tearDown` when `--pdb` is active by replacing the instance `tearDown` with a no-op and saving the original method for pytest's item teardown phase. This preserves instance state for post-mortem debugging on failing unittest tests.

The skip guard for that delayed teardown only checked `_is_skipped(self.obj)`, which catches method-level `@unittest.skip` because the collected test method carries `__unittest_skip__`. A class-level `@unittest.skip` marks the `TestCase` class instead. In that case, unittest reports the test as skipped without running `setUp`, the test method, or `tearDown`, but pytest had already saved the original `tearDown` and then invoked it later from `TestCaseFunction.teardown`. That made `tearDown` run for class-skipped tests only when `--pdb` was enabled.

## Changed Files

`repo/src/_pytest/unittest.py`

Updated the `--pdb` delayed-teardown condition in `TestCaseFunction.runtest` to check both the test method and the `TestCase` instance for unittest skip metadata. Checking the instance mirrors existing xunit fixture handling in the same file, where `_is_skipped(self)` is used to detect class-level unittest skips through normal attribute lookup.

`reports/baseline_notes.md`

Added this report to document the root cause, the source change, assumptions, and alternatives considered.

## Assumptions

The intended behavior is that pytest should match unittest skip semantics: a class-level `@unittest.skip` means no per-test `setUp`, test method, or `tearDown` should execute, even when pytest is delaying teardown for `--pdb`.

The existing method-level skip behavior should remain unchanged, so the method-object skip check was kept and the class/instance skip check was added alongside it.

## Alternatives Considered

One alternative was to check `self.parent.obj` directly for skip metadata. I rejected that because the `TestCase` instance is already available, and `_is_skipped(self._testcase)` follows the existing pattern used by pytest's injected unittest setup/teardown fixture.

Another alternative was to make `TestCaseFunction.teardown` decide whether to call `_explicit_tearDown`. I rejected that because the problem is that `_explicit_tearDown` should never be installed for unittest-skipped tests. Keeping the guard in `runtest` limits the change to the existing delayed-teardown decision point.
