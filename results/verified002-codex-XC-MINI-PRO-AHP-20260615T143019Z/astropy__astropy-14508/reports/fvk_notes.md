# FVK Notes

## Decision

V1 stands unchanged after the FVK audit. The audit found no open source-code
defect beyond the V1 patch in `repo/astropy/io/fits/card.py`.

## Trace to findings and proof obligations

- The reported bug is captured as `fvk/FINDINGS.md` F1. It is discharged by
  `fvk/PROOF_OBLIGATIONS.md` PO1 and PO4: when `str(value)` fits in 20
  characters, `_format_float()` selects it, and the concrete reported HIERARCH
  card keeps the full comment.
- The lowercase-exponent risk introduced by preferring `str(value)` is captured
  as F2. It is discharged by PO2 because V1 normalizes lower-case `e` to
  uppercase `E` before the existing exponent cleanup and verifier-facing output.
- The risk of changing overlong scientific-notation formatting too broadly is
  captured as F3. It is discharged by PO3 because V1 falls back to the previous
  `.16G` path when the normalized `str(value)` token is longer than 20
  characters.
- Preservation of parsed, unmodified FITS value strings is captured as F4 and
  discharged by PO5. The changed helper is not called on that existing
  `_valuestring` branch in `Card._format_value()`.
- The constructed-proof caveat is captured as F5. It does not justify a code
  edit; it only means tests should not be removed and the emitted K commands
  should be run later in an environment with K installed.

## Artifacts written

The required FVK files are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK method also requires the adequacy and formal core, so this audit added:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-fits-card-format.k`
- `fvk/fits-card-format-spec.k`

No test files were modified and no tests, Python code, or K tooling were run.
