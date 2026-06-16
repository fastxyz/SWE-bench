# FVK Notes

## Decisions

Kept the V1 source fix unchanged. `fvk/FINDINGS.md` F-001 identifies the original bug as text fd capture normalizing `"\r"` to `"\n"`, and `fvk/PROOF_OBLIGATIONS.md` PO-001 through PO-004 trace why `newline=""` on the fd-capture `EncodedFile` discharges the stdout and stderr carriage-return obligations.

Made no additional binary-capture change. F-002 records the binary frame audit, and PO-005 explains that `FDCaptureBinary.snap()` reads `self.tmpfile.buffer.read()`, so byte output remains byte-exact.

Made no public API or compatibility change. F-003 records the compatibility audit, and PO-006 states that fixture names, signatures, return shape, and class signatures are unchanged.

Rejected manual byte decoding in `FDCapture.snap()`. PO-002 localizes the required behavior to `io.TextIOWrapper(newline="")`; keeping decoding in the wrapper avoids duplicating `encoding="utf-8"` and `errors="replace"` behavior.

Rejected a broader `EncodedFile` class-level change. PO-001 only requires the fd-capture construction path, and PO-006 supports keeping the public surface unchanged.

Did not edit tests. F-005 recommends a regression test, but the task forbids modifying test files.

## Artifacts

Wrote the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Also wrote the FVK formal core required by the method:

- `fvk/mini-capture.k`
- `fvk/capture-spec.k`

No tests, Python, or K framework commands were run. The proof is constructed, not machine-checked, matching F-004.
