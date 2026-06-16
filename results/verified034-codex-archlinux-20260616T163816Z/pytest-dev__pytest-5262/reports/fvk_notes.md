# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the current source change
discharges the intent-derived obligations for this issue.

## Source Decisions

`repo/src/_pytest/capture.py` was not edited in this pass. Finding F-001 is
already resolved by V1: `EncodedFile.mode` returns
`self.buffer.mode.replace("b", "")`, which discharges PO-1, PO-2, and PO-3.

I did not change `EncodedFile.write` to accept `bytes`. Finding F-002 and PO-4
show that widening `write()` is the wrong repair target: the issue is that
`.mode` advertised binary capability even though the wrapper is text-oriented.

I did not add a fallback mode for buffers without a `mode` attribute. Finding
F-003 and PO-6 keep that behavior outside the reported stdio-backed domain and
preserve the prior effective `AttributeError` behavior.

I did not change `CaptureIO`. Finding F-005 and PO-6 localize the defect to
`EncodedFile.mode`, the object shown in the traceback and the object whose
attributes were delegated to a binary buffer.

## Artifact Decisions

I added the required FVK files under `fvk/` and also included the formal core
and adequacy audit files required by the FVK docs:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-capture.k`
- `fvk/encodedfile-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

Finding F-004 and PO-7 record the honesty gate: the proof is constructed, not
machine-checked, and the commands in `fvk/PROOF.md` were not run.
