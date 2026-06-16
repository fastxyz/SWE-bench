# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: The fd text wrapper is configured for preservation

Statement: for fd targets `1` and `2`, `FDCaptureBinary.__init__` constructs `self.tmpfile` as `EncodedFile(..., newline="", write_through=True)`.

Evidence: `repo/src/_pytest/capture.py` lines 386-392.

Why it matters: this selects the `Preserve` branch in the formal model instead of the legacy `Translate` branch.

Status: discharged by source inspection.

## PO-002: `newline=""` preserves line endings on text read

Statement: when the temporary file contains decoded text with `"\r"`, reading through an `io.TextIOWrapper` configured with `newline=""` returns `"\r"` rather than normalizing it to `"\n"`.

Evidence: Python text I/O newline-mode semantics represented by `decodePreserve` in `fvk/mini-capture.k`; consistency with existing `CaptureIO(..., newline="")` in `repo/src/_pytest/capture.py` line 195.

Status: modeled as a trusted standard-library semantic assumption; constructed, not machine-checked.

## PO-003: stdout `capfd.readouterr()` reaches `FDCapture.snap()`

Statement: the `capfd` fixture uses `CaptureFixture(FDCapture, request)`, and `CaptureFixture.readouterr()` aggregates `MultiCapture.readouterr()`, which calls `FDCapture.snap()` for stdout.

Evidence: `repo/src/_pytest/capture.py` lines 789-799 and 858-868.

Status: discharged by source inspection.

## PO-004: stderr `capfd.readouterr()` reaches the same preservation path

Statement: stderr fd capture uses the same `FDCapture` class and the same `EncodedFile(..., newline="")` construction path as stdout.

Evidence: `CaptureFixture._start()` constructs `out=self.captureclass(1)` and `err=self.captureclass(2)`; `capfd` sets `captureclass` to `FDCapture`.

Status: discharged by source inspection.

## PO-005: binary fd capture remains byte-exact

Statement: `FDCaptureBinary.snap()` returns `self.tmpfile.buffer.read()`, so captured bytes are returned without text newline translation.

Evidence: `repo/src/_pytest/capture.py` lines 424-430; formal claim `CAPFDBINARY-PRESERVES-BYTES`.

Status: discharged by source inspection and formal frame claim.

## PO-006: public API and return shapes are unchanged

Statement: the fix does not change fixture names, method signatures, class signatures, or the `(out, err)` return shape.

Evidence: V1 changes only an internal keyword argument in `FDCaptureBinary.__init__`; public fixture definitions remain unchanged.

Status: discharged by compatibility audit in `fvk/SPEC.md`.

## PO-007: capture buffers are reset after a snapshot

Statement: after `snapText` or `snapBytes`, the modeled temporary buffer becomes empty, matching the implementation's `seek(0); read(); seek(0); truncate()` pattern.

Evidence: `repo/src/_pytest/capture.py` lines 424-430 and 479-485; `fvk/mini-capture.k` rules rewrite `<tmp> B => .Bytes </tmp>`.

Status: discharged in the constructed proof.
