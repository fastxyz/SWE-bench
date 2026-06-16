# FVK Notes

## Decision

V1 stands unchanged.  The audit found that the current source edit satisfies
the divider-selection contract in `fvk/SPEC.md` and discharges the proof
obligations relevant to the bug.

## Trace to findings and proof obligations

- Kept the V1 endpoint inclusion logic in `repo/lib/matplotlib/colorbar.py`.
  - Finding: F1 shows the pre-fix code selected `range(1, N - 1)` even for
    `extend='both'`, while the expected selection is `range(0, N)`.
  - Proof obligations: PO4 and PO5 require including the first and last mesh
    rows when both data-end extensions exist; PO7 maps V1's `start=0` and
    `stop=None` to that range.

- Kept the V1 one-sided behavior for `extend='min'` and `extend='max'`.
  - Finding: F2 treats one-sided extensions as part of the public `extend`
    family rather than a separate optional enhancement.
  - Proof obligations: PO3, PO4, PO5, and PO7 require `range(0, N - 1)` for
    `extend='min'` and `range(1, N)` for `extend='max'`.

- Kept V1's direct `self.extend` checks instead of changing to
  `_extend_lower()` / `_extend_upper()`.
  - Finding: F3 identifies the lower/upper helpers as visual-placement helpers,
    which is not the same as selecting the data-minimum or data-maximum mesh
    row.
  - Proof obligation: PO6 frames orientation as a coordinate swap that preserves
    boundary-row identity.

- Made no public API or callsite changes.
  - Finding: F4 limits the residual risk to rendering/backend integration
    behavior rather than a source-level selector bug.
  - Proof obligation: PO8 requires preserving public signatures, accepted
    values, body mesh generation, extension patch generation, and divider
    styling.

## Artifact choices

- The K model abstracts divider geometry to boundary-row index ranges.
  - This follows PO1 and is adequate because the pre-fix and V1 behaviors are
    distinguishable: `range(1, N - 1)` versus the required extension-aware
    ranges.

- The proof is labeled constructed, not machine-checked.
  - This follows PO9 and the task constraint forbidding K tooling execution.

## No code changes after FVK

No source edits were made after the FVK audit.  The audit confirmed the V1
change as the minimal repair for the issue: it changes only the divider
segments selected when `drawedges=True`, and only at extension sides whose join
line is otherwise missing.
