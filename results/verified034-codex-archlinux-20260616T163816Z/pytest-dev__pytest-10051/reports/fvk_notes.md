# FVK Notes

## Decision: keep V1 source unchanged

Finding FVK-F1 identifies the real defect: `caplog.clear()` must clear the
current records list without replacing the object referenced by the current
phase stash. PO-1 and PO-2 are discharged by the V1 implementation:
`LogCaptureHandler.clear()` calls `self.records.clear()`, and
`LogCaptureFixture.clear()` calls `self.handler.clear()`. No additional source
edit is needed for the reported aliasing failure.

## Decision: keep `reset()` as list replacement

Finding FVK-F2 and PO-3 show why the broader alternative, changing
`LogCaptureHandler.reset()` to clear in place, is wrong. Phase transitions need
fresh records lists so `get_records("setup")`, `get_records("call")`, and
`get_records("teardown")` remain phase-specific. V1 correctly leaves
`reset()` unchanged.

## Decision: no extra stream-identity change

FVK-F4 and PO-4 trace the text requirement to INT-5: public intent requires the
formatted text content to be cleared. It does not require preserving the
identity of the private `StringIO` object, and existing phase `reset()` behavior
already replaces the stream. V1's fresh `StringIO` in
`LogCaptureHandler.clear()` satisfies the public text-content obligation.

## Decision: no test or tooling execution

FVK-F3 and PO-6 record the residual verification caveat. The artifacts include
the exact `kompile`, `kast`, and `kprove` commands, but they were not run
because the task forbids executing tests, Python, or K tooling. No test files
were modified.
