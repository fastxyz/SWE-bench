# Public Compatibility Audit

## Changed public symbols

`LogCaptureFixture.clear()` keeps the same signature and return behavior:
`clear(self) -> None`.

## Added symbols

`LogCaptureHandler.clear()` is a new helper on pytest's internal logging
handler. No public callsite is required to pass new arguments, consume a new
return type, or override it.

## Callsite and override scan

The changed fixture method still calls through `self.handler` and does not
change fixture construction, `caplog.records`, `caplog.get_records(when)`,
`caplog.text`, or phase hook signatures. The audit found no public subclass or
override compatibility obligation created by V1.

Verdict: compatible.
