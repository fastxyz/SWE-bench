# FVK Notes

## Decision: keep V1 unchanged

F-1 identifies the real bug: `caplog.set_level()` changed the shared handler
level but the pre-V1 finalizer restored only logger levels. V1 directly
addresses that bug by recording `_initial_handler_level` before the first
`set_level()` call and restoring it in `_finalize()`.

This decision is justified by PO-2, PO-3, and PO-6. PO-2 proves the first call
saves the original handler level. PO-3 proves repeated calls keep that original
restore target and finalization restores it. PO-6 connects that local fixture
property to the cross-test shared-handler symptom from the issue.

## Decision: no additional source edit

The FVK audit did not produce a new code bug. F-2 confirms existing logger-level
restoration remains intact, covered by PO-3. F-3 confirms `caplog.at_level()`
already restores handler and logger levels with a `finally` block, covered by
PO-5. C-1 through C-4 in `fvk/SPEC.md` found no public compatibility problem.

I therefore left `repo/src/_pytest/logging.py` as V1.

## Decision: reject a catching_logs change

F-4 records the alternative of restoring handler levels from
`catching_logs.__exit__()`. I rejected that because PO-6 localizes the issue to
fixture-scoped `caplog.set_level()` state leaking through the reused caplog
handler. A broader context-manager change would affect live logging, file
logging, and report logging behavior without public intent evidence for this
issue.

## Decision: no tests run or modified

F-5 and PO-8 record the execution constraint. The K proof is constructed, not
machine-checked, and pytest was not run. No test files were modified. Future
test removal is not recommended unless the emitted K commands and the normal
pytest suite run successfully in an execution-enabled environment.
