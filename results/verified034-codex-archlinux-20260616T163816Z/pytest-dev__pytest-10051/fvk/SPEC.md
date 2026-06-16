# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is the caplog records/text state managed by
`LogCaptureHandler`, `LogCaptureFixture.clear()`, and
`LoggingPlugin._runtest_for` in `repo/src/_pytest/logging.py`.

The verified model is a small aliasing state machine:

- `handlerRef`: the list object currently held by `handler.records`.
- `stash`: phase name to records-list object reference.
- `heap`: records-list object reference to list contents.
- `stream`: formatted log text content, abstracted as a list of emitted record
  IDs.
- `beginPhase(P)`: the `_runtest_for` reset/store sequence.
- `caplogClear`: the user-facing `caplog.clear()` path.
- `emit(B)`: appending a captured log record.

The model keeps object identity for records lists because that is the property
reported in the issue. It abstracts away concrete `logging.LogRecord` fields and
formatter details because the issue is about records list aliasing and text
clearing, not record formatting.

## Intent Ledger

See `fvk/INTENT_SPEC.md` and `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

Critical entries:

- INT-1: `caplog.clear()` must not decouple `caplog.get_records(when)` from
  `caplog.records`.
- INT-2: immediately after clear, the current `get_records(when)` and
  `caplog.records` views are both empty.
- INT-3: records emitted after clear are visible through both current views.
- INT-4: phase transition reset preserves earlier phase records.
- INT-5: clear also clears formatted text content.

## Formal Artifacts

- `fvk/mini-caplog.k`: mini state-machine semantics for records-list identity,
  phase stash entries, clear, emit, and phase reset.
- `fvk/caplog-clear-spec.k`: K reachability claims:
  `CLEAR-CURRENT`, `CLEAR-THEN-EMIT`, and
  `BEGIN-PHASE-PRESERVES-PREVIOUS`.

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-caplog.k --backend haskell
kast --backend haskell fvk/caplog-clear-spec.k
kprove fvk/caplog-clear-spec.k
```

Expected result after a real machine check: `kprove` returns `#Top` for all
claims.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `fvk/SPEC_AUDIT.md`
compares those paraphrases to the intent ledger; all required entries pass.
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no changed public signature, return
shape, virtual dispatch contract, or public override obligation.

## Result

V1 satisfies the spec: `LogCaptureHandler.clear()` clears the current records
list in place, so the active phase stash reference remains coupled to
`caplog.records`; `LogCaptureFixture.clear()` calls that operation; and
`LogCaptureHandler.reset()` still replaces the list for phase transitions, so
older phase records are preserved.
