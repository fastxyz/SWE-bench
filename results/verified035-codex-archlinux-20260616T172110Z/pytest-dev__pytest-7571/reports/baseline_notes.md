# Baseline Notes

## Root cause

`caplog.set_level()` changes both the requested logger level and the shared
`LogCaptureHandler` level. The fixture finalizer only saved and restored logger
levels, so the handler level set by one test could remain on the reused capture
handler for the next test. With the default logging configuration,
`catching_logs()` does not reset the handler level at the start of each phase, so
the leaked handler level is visible as `caplog.handler.level` in later tests.

## Files changed

`repo/src/_pytest/logging.py`

The `LogCaptureFixture` now records the capture handler's level before the first
`set_level()` call made through a fixture instance. During fixture finalization it
restores that saved handler level in addition to restoring logger levels. This
keeps `caplog.set_level()` scoped to the test while preserving the existing
behavior for repeated calls within the same test.

## Assumptions and alternatives considered

I assumed the documented guarantee that levels changed by `caplog.set_level()`
are restored includes the capture handler level, because `set_level()` explicitly
sets that handler and the reported regression observes `caplog.handler.level`.

I considered changing `catching_logs()` to restore handler levels when leaving
its context, but rejected that because the leak is caused by the fixture API
mutating the shared caplog handler. Restoring in the fixture finalizer is more
targeted and avoids changing the behavior of live logging, file logging, or
configured global logging levels.

I also considered storing the handler level when the fixture object is created,
but rejected that because the level should be captured immediately before the
first `set_level()` call, matching how logger levels are saved and avoiding any
extra handler lookup for tests that only inspect logs.
