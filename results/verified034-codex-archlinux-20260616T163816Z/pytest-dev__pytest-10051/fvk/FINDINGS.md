# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations only.

## FVK-F1: Resolved code bug, active phase records decoupled by replacement

Input/state: active `call` phase, `item.stash[caplog_records_key]["call"]` and
`caplog.records` initially refer to the same list containing record `A`; then
`caplog.clear()` runs and record `B` is emitted.

Observed before V1: `caplog.clear()` called `reset()`, replacing
`handler.records` with a new list. The stash still referenced the old list, so
`get_records("call")` observed `[A]` and did not observe later `B`, while
`caplog.records` observed the replacement list.

Expected: both views observe `[]` immediately after clear and `[B]` after the
later emit.

Evidence: INT-1, INT-2, INT-3. Proof obligations: PO-1 and PO-2.

Status: resolved by V1. `LogCaptureHandler.clear()` clears the records list in
place and `LogCaptureFixture.clear()` calls it.

## FVK-F2: Rejected alternative, changing `reset()` to in-place clear breaks phase records

Input/state: setup phase has stored setup records under list object `RS`, then
pytest begins the call phase.

Observed under the rejected alternative: if `LogCaptureHandler.reset()` used
`records.clear()` instead of replacing `records`, setup's stash entry would
still point at the same list object and its contents would be erased when call
phase capture starts.

Expected: setup records remain available through `get_records("setup")` while
call records are captured in a fresh list.

Evidence: INT-4 and CODE-1. Proof obligation: PO-3.

Status: rejected. V1 intentionally leaves `reset()` as list replacement.

## FVK-F3: Residual verification caveat

Input/state: any state satisfying the formal claims.

Observed: no Python tests, project code, `kompile`, `kast`, or `kprove` were run
in this environment.

Expected for machine verification: run the commands recorded in `fvk/SPEC.md`
and `fvk/PROOF.md`; `kprove` should return `#Top`.

Evidence: task constraints and FVK honesty gate. Proof obligation: PO-6.

Status: residual caveat only. It does not indicate a source-code bug.

## FVK-F4: Rejected speculative change, private stream identity is not public intent

Input/state: `caplog.clear()` is called while the handler has formatted text in
its private `StringIO` stream.

Observed in V1: `LogCaptureHandler.clear()` replaces the stream with a fresh
`StringIO`, matching existing `reset()` style.

Expected by public intent: `caplog.text` observes empty formatted text after
clear. No public evidence requires preserving object identity of the private
stream.

Evidence: INT-5. Proof obligation: PO-4.

Status: no source change. The FVK audit does not justify adding a stream
identity preservation requirement.
