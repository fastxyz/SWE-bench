# FVK Findings

Status: constructed, not machine-checked. No tests or project code were run.

## Findings

F-1, code bug, resolved by V1.

Input/evidence: two-test sequence from the public issue:

```python
def test_foo(caplog):
    caplog.set_level(42)

def test_bar(caplog):
    print(caplog.handler.level)
```

Observed in the reported regression: `42` in the second test. Expected by the
documentation and pre-regression behavior: the previous handler level, `0` in
the default configuration.

Root cause: `set_level()` mutates both the target logger and
`caplog.handler.level`, while the pre-V1 finalizer restored only logger levels.
Because pytest reuses one `caplog_handler`, the handler mutation survived into
the next test when no configured `log_level` reset it.

Resolution: V1 records `_initial_handler_level` before the first
`set_level()` call and restores it in `_finalize()`. Covered by PO-2, PO-3, and
PO-6.

F-2, preservation check, confirmed.

Input/evidence: public `test_change_level_undo` expects logger-level changes
from one test not to affect a later test. V1 leaves
`_initial_logger_levels.setdefault(...)` and the existing logger restoration loop
intact.

Expected: logger levels changed through `caplog.set_level()` restore to their
first saved value. V1 satisfies this through the existing code path. Covered by
PO-3.

F-3, preservation check, confirmed.

Input/evidence: docs describe `caplog.at_level()` as temporary within a `with`
block, and existing code stores `handler_orig_level` and restores it in a
`finally` block.

Expected: V1 must not weaken block-scoped restoration. V1 does not edit
`at_level()`, and the added fixture-finalizer restoration is consistent with the
same handler-level invariant. Covered by PO-5.

F-4, alternative rejected, no V2 edit.

Alternative considered: restore handler levels in `catching_logs.__exit__()`.

Reason rejected: the intent violation is caused by `caplog.set_level()` mutating
the caplog fixture's shared handler. Restoring at fixture finalization directly
matches the documented "end of the test" lifetime and avoids changing file
logging, live logging, or report handler behavior. Covered by PO-6 and C-1.

F-5, residual proof and test gap.

The proof is constructed only. K commands and pytest tests were not run by
instruction. Existing and hidden tests should be kept; any test-redundancy
recommendation is conditioned on machine-checking the K artifacts and running
the normal pytest suite in an environment that permits execution. Covered by
PO-8.

## Proof-derived findings from verify

No new code bug was found beyond F-1. The constructed proof obligations close
over the intended state machine for `set_level()` and `_finalize()`: first save,
mutate during test, restore at fixture finalization. The adequacy audit did not
identify an unhandled public callsite, signature compatibility issue, or
implementation-derived side condition needed to justify keeping V1.
