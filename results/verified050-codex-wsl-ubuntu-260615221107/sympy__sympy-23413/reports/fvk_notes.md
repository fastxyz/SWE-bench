# FVK Notes

## Decision

V1 does not stand unchanged. The FVK audit found that V1 fixed the reported
full-column-rank example but kept an implementation-derived fallback for tall
rank-deficient matrices.

## Source change

Changed `repo/sympy/polys/matrices/normalforms.py`.

The V1 snapshot variables and fallback restore were removed. The outer HNF row
loop now scans from the bottom row to the top row, stopping early only when
`k == 0`, meaning all input columns have become pivots.

Trace:

- `fvk/FINDINGS.md` F1: V1 preserved a legacy rank-deficient tall-matrix bug.
- `fvk/FINDINGS.md` F2: the original issue was caused by stopping after the
  bottom `min(m, n)` rows.
- `fvk/PROOF_OBLIGATIONS.md` PO5: after a full scan, dropped prefix columns are
  zero.
- `fvk/PROOF_OBLIGATIONS.md` PO6: the returned column count equals rank.
- `fvk/PROOF_OBLIGATIONS.md` PO8: rank-deficient tall matrices still need their
  available rank-many pivots.

## Rejected V1 rationale

V1 kept the old rank-deficient result to avoid changing an existing public test
case. The FVK intent audit classifies that test as suspect legacy evidence
because it expects a rank-positive matrix to return a zero-column HNF.

Trace:

- `fvk/FINDINGS.md` F3.
- `fvk/SPEC_AUDIT.md`, row `HNF-RANK-DEFICIENT-TALL`.
- `fvk/PUBLIC_EVIDENCE_LEDGER.md` E7.

## Kept behavior

The public wrappers, non-`ZZ` error behavior, return types, and modular `D`
dispatch were left unchanged.

Trace:

- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- `fvk/PROOF_OBLIGATIONS.md` PO1 and PO9.

## Verification status

No tests, Python code, or K tools were run. The FVK proof is constructed over
the mini-HNF artifacts in `fvk/mini-hnf.k` and `fvk/hnf-spec.k`, with exact
commands recorded in `fvk/PROOF.md`.

Trace:

- `fvk/FINDINGS.md` F4.
- `fvk/PROOF.md`, K artifacts and residual risk sections.
