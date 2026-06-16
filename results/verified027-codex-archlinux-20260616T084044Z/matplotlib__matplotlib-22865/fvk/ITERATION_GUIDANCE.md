# Iteration Guidance

Status: constructed for FVK audit; not machine-checked.

## Decision

V1 stands unchanged.  The formalized obligations in
`fvk/PROOF_OBLIGATIONS.md` and the findings in `fvk/FINDINGS.md` support the
current source change:

- F1 confirms V1 fixes the reported `extend='both'` extremity omission.
- F2 confirms V1 also covers the one-sided `extend='min'` and `extend='max'`
  family implied by the public API.
- F3 rejects switching to visual lower/upper helpers for divider-row selection.
- PO8 confirms the fix preserves public compatibility and unrelated rendering
  state.

## Recommended tests when test edits are allowed

- Add a unit-level assertion on `cbar.dividers.get_segments()` or equivalent
  public-observable divider geometry for `drawedges=True` with `extend='both'`.
- Include one-sided `extend='min'` and `extend='max'` cases to guard the family
  obligation.
- Keep image-comparison coverage for final rendering, because the FVK proof
  intentionally abstracts backend pixels.

## Residual risks

- The proof is constructed, not machine-checked.
- The mini-K model proves boundary-row selection, not renderer output.
- The audit did not attempt to prove total correctness or performance because
  the modeled selector has no loop and the source change does not affect
  termination-sensitive behavior.
