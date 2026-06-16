# Baseline Notes

## Root cause

`capfd` uses `FDCapture` to redirect stdout/stderr file descriptors to a temporary file, then reads captured text back from an `EncodedFile`, which subclasses `io.TextIOWrapper`.

The `EncodedFile` wrapper was constructed without a `newline` argument, so `TextIOWrapper` used its default `newline=None`. In that mode, Python performs universal-newline translation while reading text: carriage returns are returned as `\n`. As a result, output such as `end="\r"` was captured as `"\n"` by `capfd.readouterr()`.

This was inconsistent with `CaptureIO`, used by sys-level capture, which already uses `newline=""` to keep newline characters untranslated.

## Files changed

`repo/src/_pytest/capture.py`

Set `newline=""` when constructing the `EncodedFile` used by fd capture. This keeps universal-newline recognition disabled for translation purposes, so captured text preserves `\r`, `\n`, and `\r\n` sequences instead of normalizing them to `\n`.

`reports/baseline_notes.md`

Added this required report describing the cause, the source change, assumptions, and alternatives considered.

## Assumptions

The desired behavior is the pytest 5 behavior described in the issue: text `capfd.readouterr()` should preserve carriage returns rather than normalize them.

The issue is specific to text fd capture. Binary fd capture already reads from the underlying buffer as bytes, so it should not be changed.

No tests or project code were run, as requested by the task instructions.

## Alternatives considered and rejected

Decoding from `self.tmpfile.buffer.read()` inside `FDCapture.snap()` would also bypass text newline translation, but it would duplicate the wrapper's decoding responsibility and risk diverging from the configured `encoding` and `errors` behavior.

Changing `EncodedFile` globally to default to `newline=""` would make every external or test construction of the class inherit the behavior, but the regression is caused by the fd capture construction site. Passing the argument there is the narrower fix.

Post-processing the captured string to convert trailing `\n` back to `\r` was rejected because it cannot distinguish original newlines from translated carriage returns and would corrupt legitimate output.
