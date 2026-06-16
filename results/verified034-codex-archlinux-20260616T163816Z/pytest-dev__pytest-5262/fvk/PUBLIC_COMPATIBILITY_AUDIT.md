# PUBLIC_COMPATIBILITY_AUDIT.md

Status: constructed, not machine-checked.

Changed public surface: `_pytest.capture.EncodedFile.mode`.

Compatibility result:

- No method signature changed.
- No call protocol changed.
- `EncodedFile.buffer` remains public and unchanged.
- `EncodedFile.buffer.mode` remains the underlying stream mode.
- `__getattr__` still delegates non-mode attributes to the wrapped buffer.
- The only changed behavior is `EncodedFile.mode` no longer exposing `b` when
  the underlying mode contains `b`; this is the reported defect, not a
  compatibility regression.
