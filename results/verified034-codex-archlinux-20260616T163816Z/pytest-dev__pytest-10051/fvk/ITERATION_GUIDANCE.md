# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Keep

- Keep `LogCaptureHandler.clear()` clearing `self.records` in place.
- Keep `LogCaptureFixture.clear()` delegating to `self.handler.clear()`.
- Keep `LogCaptureHandler.reset()` replacing `self.records` with a new list.

## Do Not Change

- Do not change `reset()` to use `self.records.clear()`. Finding FVK-F2 and
  PO-3 show that doing so would erase earlier phase records when a later phase
  starts.
- Do not update the phase stash inside `caplog.clear()` instead of clearing the
  list in place. Finding FVK-F1 and PO-1/PO-2 require existing references to
  remain coupled.

## Suggested Future Tests

The task forbids editing tests here. Future public tests should cover:

- `caplog.clear()` during setup, call, and teardown leaves
  `caplog.get_records(when) == caplog.records` for the active phase.
- A record emitted after `caplog.clear()` is visible through both active-phase
  views.
- Records from a previous phase remain available after the next phase begins.

## Verification Follow-up

In an environment with K installed, run:

```sh
kompile fvk/mini-caplog.k --backend haskell
kast --backend haskell fvk/caplog-clear-spec.k
kprove fvk/caplog-clear-spec.k
```

Expected result: `kprove` returns `#Top`. Until that is run, the proof remains
constructed, not machine-checked.
