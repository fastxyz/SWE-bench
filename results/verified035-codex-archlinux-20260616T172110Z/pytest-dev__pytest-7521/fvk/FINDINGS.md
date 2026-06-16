# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F-001: Resolved code bug, carriage returns normalized by text fd capture

Classification: code bug, resolved by V1.

Evidence: issue reproducer writes `print(..., end="\r")`; observed pytest 6 output was `"Greetings from DOS\n"`; expected output ends with `"\r"`.

Root cause: `FDCapture.snap()` reads through `EncodedFile.read()`. Without an explicit newline mode, `io.TextIOWrapper` defaults to `newline=None`, so universal-newline translation maps `"\r"` to `"\n"` on read.

Resolution: V1 constructs the fd capture `EncodedFile` with `newline=""`, so reads return line endings untranslated. This discharges PO-001, PO-002, PO-003, and PO-004.

## F-002: Binary capture frame condition remains satisfied

Classification: frame-condition check, no source change needed beyond V1.

Evidence: docs and public tests state `capfdbinary` returns bytes and preserves undecodable bytes.

Audit result: `FDCaptureBinary.snap()` reads from `self.tmpfile.buffer.read()`, so its returned bytes are not produced by text `read()` and are not subject to newline translation. The V1 `newline=""` argument does not weaken the byte-read postcondition. This discharges PO-005.

## F-003: No API compatibility issue found

Classification: public compatibility, no source change needed beyond V1.

Evidence: V1 adds an internal constructor argument to the internal `EncodedFile(...)` construction site. Fixture names, fixture return shapes, method signatures, and class signatures are unchanged.

Audit result: no public callsite or override needs an update. This discharges PO-006.

## F-004: Proof is constructed, not machine-checked

Classification: proof capability gap.

Evidence: this environment forbids running K tooling, tests, or Python. The proof artifacts include commands but those commands were not executed.

Expected machine-check result: `kprove fvk/capture-spec.k` should discharge the three claims if the mini semantics parse in a real K environment.

Recommended action: keep tests; do not remove any tests based on this proof until a real K run returns `#Top`.

## F-005: Public regression test gap

Classification: test gap, not edited due task constraints.

Evidence: the issue includes a reproducer for `capfd` preserving `"\r"`, but this task forbids modifying test files.

Recommended test after this benchmark task: add a focused test that writes `end="\r"` under `capfd` and asserts that `readouterr().out` ends with `"\r"`; optionally add a stderr variant matching the borgbackup symptom.
