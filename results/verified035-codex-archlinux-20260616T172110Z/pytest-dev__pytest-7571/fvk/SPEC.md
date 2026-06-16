# FVK Spec: caplog level restoration

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change for `repo/src/_pytest/logging.py`, focused on
`LogCaptureFixture.set_level()`, `LogCaptureFixture._finalize()`, the
`caplog` fixture lifetime, and the shared `LoggingPlugin.caplog_handler`.

The observable under audit is the log level state changed by `caplog.set_level()`
and visible through logger objects and `caplog.handler.level` after the test
ends. Formatting, record storage, report sections, and live/file logging output
are outside this spec except as compatibility frame conditions.

## Intent Spec

I-1. A test may call `caplog.set_level(level, logger=None_or_name)` to change
the capture threshold for the current test.

I-2. All log levels changed by `caplog.set_level()` are restored automatically
at the end of that test.

I-3. The restored state includes the capture handler level because
`set_level()` explicitly mutates `caplog.handler` and the issue exposes the bug
through `caplog.handler.level`.

I-4. `caplog.at_level()` remains block-scoped: after the `with` block exits,
the target logger and capture handler levels are restored to their pre-block
values.

I-5. The fix must preserve configured global logging behavior: if pytest entered
the test phase with a configured capture level, that level is the original
handler level to restore after `caplog.set_level()`.

I-6. The fix must not change public `caplog` APIs, public fixture signatures, or
the shape of captured log records.

## Public Evidence Ledger

E-1, prompt/documentation, quote: "The log levels set are restored automatically
at the end of the test." Obligation: `caplog.set_level()` effects are scoped to
one test and undone by fixture finalization. Encoded by PO-2 and PO-3.

E-2, prompt/reproduction, quote: `caplog.set_level(42)` followed by a later test
printing `caplog.handler.level`; expected old behavior prints `0`, regressed
behavior prints `42`. Obligation: the capture handler level must be restored for
the next test. Encoded by PO-3 and PO-6.

E-3, docs, quote: "Inside tests it is possible to change the log level for the
captured log messages. This is supported by the caplog fixture." Obligation:
`set_level()` still changes capture level during the test. Encoded by PO-2.

E-4, docs, quote: "It is also possible to use a context manager to temporarily
change the log level inside a with block." Obligation: `at_level()` remains
temporary and its existing restoration behavior should be preserved. Encoded by
PO-5.

E-5, implementation fact, `LogCaptureFixture.set_level()` calls both
`logger_obj.setLevel(level)` and `self.handler.setLevel(level)`. Obligation:
both mutated state components must be considered by the proof. Encoded by PO-2
and PO-3.

E-6, implementation fact, `LoggingPlugin.__init__()` creates one
`self.caplog_handler`, and `_runtest_for()` reuses it for setup, call, teardown,
and later items. Obligation: fixture cleanup must restore shared handler state
because the next item can observe it. Encoded by PO-6.

E-7, implementation fact, `catching_logs(..., level=None)` does not set a
handler level when pytest has no configured `log_level`. Obligation: the default
case cannot rely on phase entry to repair a leaked handler level. Encoded by
PO-6.

E-8, public tests, `test_change_level_undo` verifies logger-level undo by
expecting an INFO message from test 1 not to appear for test 2. Obligation:
preserve existing logger-level restoration. Encoded by PO-3.

E-9, public tests, `test_caplog_can_override_global_log_level` verifies that
`caplog.set_level()` can override configured `log_level` inside the test.
Obligation: record and restore the previous handler level, not a hard-coded
default. Encoded by PO-2, PO-3, and PO-6.

## Formal Model

The formal core is in:

- `fvk/mini-caplog.k`
- `fvk/caplog-restore-spec.k`

The model abstracts the fixture state to the properties that can distinguish
the reported pass/fail behavior:

- `handlerLevel`: the shared `LogCaptureHandler.level`.
- `loggerLevel`: the level of an arbitrary logger changed by `set_level()`.
- `savedHandlerLevel`: absent before the first `set_level()` call, otherwise
  the handler level observed immediately before that first call.
- `savedLoggerLevel`: absent before the first `set_level()` for the modeled
  logger, otherwise that logger's original level.

The multi-logger implementation is a map-lift of the one-logger model:
`_initial_logger_levels.setdefault(logger, logger_obj.level)` records the first
original value per logger key, and `_finalize()` restores every saved entry.
The handler is intentionally single-valued because the implementation has one
shared `caplog_handler`.

## Formal Spec English

FE-1. Starting from handler level `H0` and logger level `G0`, the first
`set_level(L)` transitions to handler level `L`, logger level `L`, saved handler
level `H0`, and saved logger level `G0`.

FE-2. Any later `set_level(L2)` in the same fixture instance transitions the
current handler and modeled logger level to `L2` while preserving the first saved
handler level `H0` and first saved logger level `G0`.

FE-3. Finalizing after one or more `set_level()` calls restores the handler
level to `H0` and the modeled logger level to `G0`.

FE-4. Finalizing a fixture instance that never called `set_level()` leaves the
handler and logger levels unchanged.

FE-5. `at_level()` is frame-preserved by this patch: it still stores the
pre-block handler and logger levels and restores them in its `finally` block.

FE-6. With a reused shared handler, FE-3 implies the next test observes the
pre-test handler level, which is `0` in the issue's default reproduction and the
configured log level when pytest set one at phase entry.

## Spec Audit

SA-1, FE-1 vs I-1/I-2/E-5: pass. The formal transition includes both state
components that `set_level()` mutates.

SA-2, FE-2 vs I-2/E-8: pass. The "first saved value wins" behavior matches the
existing logger restoration contract and prevents later calls from changing the
restore target.

SA-3, FE-3 vs I-2/I-3/E-1/E-2: pass. This is the issue's required end-of-test
postcondition.

SA-4, FE-4 vs I-6: pass. Tests that only inspect `caplog` or collect records do
not gain a new handler-level write.

SA-5, FE-5 vs I-4/E-4: pass. V1 does not alter `at_level()` semantics.

SA-6, FE-6 vs I-5/E-9: pass. Restoring the observed original handler level
preserves both the default `0` case and configured logging cases.

## Public Compatibility Audit

C-1. Changed public symbols: none. `LogCaptureFixture.__init__`,
`LogCaptureFixture.set_level`, `LogCaptureFixture._finalize`, and the
`caplog` fixture signature are unchanged.

C-2. Changed storage shape visible to public API: none. The new
`_initial_handler_level` attribute is private fixture state.

C-3. Public call sites of `caplog.set_level()` and `caplog.at_level()` require no
argument or return-value changes.

C-4. Test files were not modified. Existing public tests that assert logger
restoration and configured log-level override remain within the intended
contract.

Compatibility verdict: pass.
