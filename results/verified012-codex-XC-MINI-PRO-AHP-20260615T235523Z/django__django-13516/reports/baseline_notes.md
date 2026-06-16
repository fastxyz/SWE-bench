# Baseline Notes

## Root cause

Management command output streams are wrapped in `django.core.management.base.OutputWrapper`.
That wrapper subclasses `io.TextIOBase` and delegates unknown attributes to the underlying
stream with `__getattr__()`. However, `TextIOBase` already provides a `flush()` method, so
`OutputWrapper.__getattr__()` is never reached for `flush`. Calls such as
`self.stdout.flush()` in the `migrate` command therefore use the inherited `TextIOBase`
implementation instead of flushing the wrapped stdout/stderr stream.

This is visible when `migrate` writes a partial progress line such as
`Applying app.0001...` with `ending=""` and then calls `self.stdout.flush()`: the partial
line can remain buffered until later output writes a newline or the command finishes.

## Files changed

* `repo/django/core/management/base.py`: Added `OutputWrapper.flush()` so explicit flushes
  are forwarded to the wrapped stream when it supports `flush`. This fixes the shared
  stdout/stderr management command wrapper rather than changing individual commands.

## Assumptions and rejected alternatives

* I assumed the intended behavior is for `self.stdout.flush()` and `self.stderr.flush()` to
  behave like the wrapped stream's `flush()` method for all management commands.
* I kept the implementation guarded with `hasattr()` because Django management commands can
  receive custom stream-like objects; a stream with `write()` but no `flush()` should not
  fail only because the wrapper exposes `flush()`.
* I rejected changing `migrate` to write a newline before long-running work because the
  issue specifically concerns explicit flush calls and the existing progress format depends
  on appending `OK`, `FAKED`, or `DONE` to the same line.
* I rejected broad changes to `OutputWrapper.__getattr__()` or its inheritance because the
  failure is narrowly caused by `flush()` being supplied by `TextIOBase`.
