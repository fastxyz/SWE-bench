# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a justified additional
production-code edit.

## Trace to Findings and Proof Obligations

The original bug is captured by `fvk/FINDINGS.md` F-1: the legacy
`thresholds[0] + 1` rule fabricated finite thresholds above 1 for probability
scores. `fvk/PROOF_OBLIGATIONS.md` PO-3 requires the first threshold to select
no finite score, and PO-4 requires no fabricated finite probability threshold
above 1. V1's `np.inf` sentinel discharges both obligations, so the core code
change remains correct.

The issue text suggested clipping as a possible workaround, but
`fvk/FINDINGS.md` F-3 and `fvk/PROOF_OBLIGATIONS.md` PO-5 show why it should
not be applied: if any observed probability score is exactly 1, a clipped
threshold of 1 would select that sample under the documented
`score >= threshold` rule and would not represent the initial no-prediction
ROC point.

The audit identified existing public exact-threshold expectations beginning
with `2.0` as legacy evidence in `fvk/FINDINGS.md` F-2. `fvk/PROOF_OBLIGATIONS.md`
PO-6 requires public compatibility, but those exact expectations encode the
bug reported in the issue and do not justify restoring `max + 1`. Test files
were not modified, per the task constraint.

The proof scope limitation is recorded in `fvk/FINDINGS.md` F-4 and
`fvk/PROOF_OBLIGATIONS.md` PO-7. The constructed proof covers the sentinel
prepend contract, not a full Python/NumPy formalization of `roc_curve`.
Because V1 only changed that sentinel line and associated documentation, this
limitation does not justify another source edit; it only requires keeping the
honesty caveat and not deleting tests.

`fvk/FINDINGS.md` F-5 is the confirmation finding: the V1 source and
documentation changes satisfy PO-1 through PO-6. Therefore no V2 source-code
change was made.

## Files Changed in the FVK Pass

No files under `repo/` were changed during the FVK pass.

Added FVK artifacts under `fvk/`, including the requested reports, adequacy
files, and compact K core:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-roc.k`
- `fvk/roc-curve-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

No tests, Python, or K tooling were run.
