# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found no additional source change justified by
the public issue intent. The required behavior is that `clear_denoms()` preserve
its denominator-clearing algebraic meaning while returning canonical dense
representations when denominator multiplication exposes a zero leading
coefficient.

## Trace to Findings and Proof Obligations

`repo/sympy/polys/densetools.py`

- Kept the V1 `dup_strip(f)` in `dup_clear_denoms()`.
  - Finding trace: `fvk/FINDINGS.md` F1 identifies the reported univariate
    `[EX(0)]` result as the resolved bug.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO2 and PO3 require algebraic
    denotation preservation plus canonical univariate zero; PO6 explains why the
    dense helper must do this before `DMP.per()` wraps the list.

- Kept the V1 `_rec_strip(f, u)` in `dmp_clear_denoms()`.
  - Finding trace: `fvk/FINDINGS.md` F2 records the recursive dense-polynomial
    completeness gap that a top-level-only strip would leave open.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO4 requires recursive stripping so
    inner `[0]` coefficient polynomials become canonical before outer zero
    detection.

- Did not move the fix into `dup_mul_ground()` or `dmp_mul_ground()`.
  - Finding trace: `fvk/FINDINGS.md` F3 confirms the issue is repairable at the
    denominator-clearing boundary without broadening behavior in generic dense
    arithmetic.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO1, PO2, and PO7 keep denominator
    accumulation, algebraic meaning, and public compatibility scoped to
    `clear_denoms`.

- Made no public API/signature changes.
  - Finding trace: `fvk/FINDINGS.md` F4 confirms compatibility.
  - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO7 requires unchanged signatures and
    return tuple shapes.

## Artifacts

The audit artifacts are under `fvk/`, including the five task-required files:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core files were also written:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-dense-polys.k`
- `fvk/clear-denoms-spec.k`

No tests, Python code, or K tooling were executed. The proof remains
constructed, not machine-checked, as recorded in `fvk/FINDINGS.md` F5 and
`fvk/PROOF.md`.
