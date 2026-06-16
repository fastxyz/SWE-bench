# FVK Notes

## Decision

V1 stands unchanged. The audit found no production-source change justified by
the public intent beyond the existing edit in
`repo/sklearn/utils/_set_output.py`.

## Trace to Findings and Proof Obligations

- No further index-handling edit was made because `fvk/FINDINGS.md` F1 shows the
  V1 branch for existing `DataFrame` output discharges `fvk/PROOF_OBLIGATIONS.md`
  PO-1 and PO-2: it preserves the output DataFrame index and still permits
  column updates.
- No compatibility edit was made because PO-4, PO-5, and PO-6 preserve the
  non-DataFrame constructor path, sparse rejection, and default/disabled wrapping
  frame conditions. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no signature or
  dispatch break.
- I did not restore the old DataFrame index overwrite behavior. F2 classifies
  the existing helper test for index overriding as suspect legacy evidence
  because it conflicts with the issue text and public hint.
- I did not add direct `Series` handling. F3 records that path as ambiguous and
  outside the helper docstring's `{ndarray, dataframe}` domain; the reported
  FeatureUnion path reaches the final wrapper as a `DataFrame` after
  concatenation. Since F3 is not tied to an in-domain public obligation, it does
  not justify broadening the source change here.
- I did not claim machine-checked proof. F4 records the proof capability boundary:
  the K artifacts are constructed only, and the task forbids running K tooling.

## Artifacts

The requested artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK-required adequacy and formal core artifacts are also present:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-pandas-output.k`
- `fvk/set-output-spec.k`

No tests, Python code, or K commands were run.
