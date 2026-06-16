# FVK Findings

Status: constructed for FVK audit; not machine-checked.

## F1: Legacy endpoint slicing omitted extension/body boundaries

- Classification: code bug fixed by V1.
- Evidence: ledger E1, E2, E7, E9; obligations PO4 and PO5.
- Input: `drawedges=True`, `extend='both'`, `N=10`.
- Pre-fix observed selection: `range(1, 9)`, omitting boundary indices `0` and
  `9`.
- Expected selection: `range(0, 10)`, because both extension/body joins are
  color boundaries.
- V1 behavior: `start=0`, `stop=None`, selecting `range(0, 10)`.
- Decision: V1 fixes this finding.

## F2: One-sided extensions require asymmetric endpoint inclusion

- Classification: corner case covered by V1.
- Evidence: ledger E4 and E5; obligations PO3, PO4, PO5.
- Input: `drawedges=True`, `extend='min'`, `N=10`.
- Pre-fix observed selection: `range(1, 9)`.
- Expected selection: `range(0, 9)`.
- V1 behavior: `start=0`, `stop=-1`, selecting `range(0, 9)`.
- Input: `drawedges=True`, `extend='max'`, `N=10`.
- Pre-fix observed selection: `range(1, 9)`.
- Expected selection: `range(1, 10)`.
- V1 behavior: `start=1`, `stop=None`, selecting `range(1, 10)`.
- Decision: V1 covers the broader extension family implied by the public
  `extend` API, not only the reported `'both'` case.

## F3: Visual lower/upper helpers would be the wrong selector for segment rows

- Classification: rejected alternative.
- Evidence: ledger E5 and E8; obligation PO6.
- Input: inverted long axis with `extend='min'`.
- Risky alternative: using `_extend_lower()` / `_extend_upper()` to decide row
  inclusion would classify extension placement visually and could select the
  last mesh row for a data-minimum extension.
- Expected: a data-minimum extension requires the first mesh boundary row,
  regardless of whether an inverted axis displays it at the visual top.
- V1 behavior: uses `self.extend in ('both', 'min')` for the first row and
  `self.extend in ('both', 'max')` for the last row.
- Decision: keep V1's data-side selection.

## F4: Rendering backend pixels are outside this proof slice

- Classification: proof capability gap / integration test gap, not a source
  bug in V1.
- Evidence: `SPEC.md` adequacy note; obligation PO8.
- Input: any backend-specific drawing of the selected `LineCollection`.
- Constructed proof covers: the boundary-row range passed to
  `self.dividers.set_segments`.
- Not proved: antialiasing, clipping, z-order, or final image pixels.
- Recommendation: keep image-comparison coverage and add a focused regression
  test for `drawedges=True` with `extend='both'` when test edits are allowed.

## Proof-derived findings from `/verify`

- No additional code bug was found in V1.
- The adequacy gate passes for the divider-selection property: the K claims
  distinguish the legacy failing range from the required range.
- The proof remains constructed, not machine-checked; run the commands recorded
  in `fvk/PROOF.md` before treating the proof as machine-verified.
