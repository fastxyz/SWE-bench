# Baseline Notes

## Root Cause

`_pytest.capture.EncodedFile` wraps a binary stream and accepts text writes by
encoding them before forwarding to the underlying buffer. It rejects `bytes` on
Python 3, so externally it behaves as a text stream.

Because `EncodedFile` did not define `mode`, attribute lookup fell through to
`__getattr__`, exposing the wrapped binary stream's mode such as `rb+` or
`wb+`. Libraries that inspect `out.mode` can then incorrectly decide that
`sys.stdout` accepts `bytes`, leading to `TypeError` from `EncodedFile.write`.

## Changed Files

`repo/src/_pytest/capture.py`

Added an `EncodedFile.mode` property that returns the wrapped buffer's mode with
`b` removed. This keeps `EncodedFile` advertising text behavior while preserving
the real binary mode on `EncodedFile.buffer.mode`.

## Assumptions and Alternatives

I assumed the issue only concerns the fd-capture `EncodedFile` wrapper, because
that is the object shown in the failure and it is the object that delegates
`mode` to a binary buffer.

I considered changing `write()` to accept `bytes`, but rejected it because the
wrapper's public behavior is text-oriented and accepting bytes would broaden the
API beyond the reported mismatch.

I considered adding `mode` to `CaptureIO`, but rejected it because the reported
failure is from `EncodedFile`; `CaptureIO` does not currently expose a delegated
binary mode that would mislead callers in the same way.
