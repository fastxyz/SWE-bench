# FVK Notes

## Decision summary

No source changes were made after V1. The FVK audit confirms that V1 is the
minimal repair for the public issue: it changes the names passed to
`Dataset.set_coords` from only coordinate names that are also `window_dim` keys
to all original coordinate names.

## Traceability

- F1 and PO2 justify the original V1 edit. The pre-fix intersection
  `set(window_dim) & set(self.obj.coords)` drops `day` because `day` is not a
  coarsened dimension key. Passing `set(self.obj.coords)` directly is the
  needed repair.
- PO1 justifies that the broader set is safe: the reshape loop inserts every
  original variable key into `reshaped`, so every original coordinate name is
  available when `set_coords` asserts membership.
- F2 records that V1 satisfies the coordinate-preservation spec for all original
  coordinate names, not just the issue's example coordinate.
- F3 explains the decision not to add code that removes possible extra
  coordinate classifications. The public intent requires original coordinates
  to stay coordinates; it does not require exact equality of coordinate sets.
- F4 and PO3 explain why the shared DataArray path does not need a different
  branch: `set(self.obj.coords)` contains real DataArray coordinates and not
  `_THIS_ARRAY`.
- PO4 explains why no compatibility edit is required: the method signature,
  return branches, and dispatch shape are unchanged.
- PO5 explains why no tests or K tooling were run and why the proof remains
  labeled constructed, not machine-checked.

## Files added

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- Supporting FVK adequacy and formal artifacts under `fvk/`:
  `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
  `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`,
  `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-xarray.k`, and
  `coarsen-construct-spec.k`

No test files were modified.
