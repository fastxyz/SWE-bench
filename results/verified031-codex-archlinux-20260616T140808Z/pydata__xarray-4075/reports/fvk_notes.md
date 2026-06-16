# FVK Notes

## Source Decision

No source files were changed during the FVK phase. V1 stands unchanged because
the audit found that it satisfies the public-intent obligations in
`fvk/PROOF_OBLIGATIONS.md`.

## Decisions Traced to FVK Artifacts

- Kept the pre-dot cast in `Weighted._reduce`: F-001 and PO-1/PO-2 show that the
  boolean count must be preserved before `dot` can collapse it to a boolean.
- Kept the fix in the shared reducer rather than moving it only to
  `_sum_of_weights`: F-002 and PO-1/PO-3 show that `_reduce` itself promises
  equivalence to `(da * weights).sum(...)`, including boolean data with boolean
  weights.
- Kept the cast guard narrow and conjunctive: F-003 and PO-5 show that mixed
  dtype and numeric paths are frame conditions and should not be altered.
- Kept public API shape unchanged: PO-6 and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show no signature or dispatch change is
  needed.
- Did not remove or edit tests: F-004 and PO-7 label the proof constructed, not
  machine-checked, and the benchmark forbids test edits.

## Artifacts Written

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-weighted.k`
- `fvk/weighted-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Verification Caveat

No tests, Python, or K tooling were run. The FVK proof is a constructed audit and
records the commands needed for a later machine check.
