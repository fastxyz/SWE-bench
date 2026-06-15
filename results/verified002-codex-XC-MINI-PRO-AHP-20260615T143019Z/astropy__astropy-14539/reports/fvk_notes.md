# FVK Notes

## Decisions

V1 did not stand unchanged. `fvk/FINDINGS.md` F-002 showed that raw
`np.allclose` was too weak as the complete VLA row predicate: it did not encode
row shape as part of equality and did not follow FITSDiff's existing
floating-invalid-value policy. This maps to `fvk/PROOF_OBLIGATIONS.md` PO-003
and PO-004. I added `_vla_values_differ` to check shape first, use
`where_not_allclose` for floating rows, preserve `np.allclose` for
non-floating numeric rows, and use exact element equality for non-numeric rows
per PO-005 and PO-006.

V1's core `Q` fix was kept. F-001 identifies the original bug as `Q` VLA
columns missing the row-wise VLA comparison path, and PO-001 requires `Q` to
dispatch like `P`. The source still checks `col.format.format in ("P", "Q")`.

I kept the normalized format-code check instead of switching back to substring
matching. F-003 and PO-008 justify using `Column.format`'s parsed top-level FITS
format code, and PO-007 requires non-VLA dispatch to remain unchanged.

I did not change public APIs, constructor signatures, reporting code,
ignore-field behavior, or non-VLA comparison branches. That decision follows
PO-007 and the compatibility result in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## Verification Limits

The FVK proof is constructed, not machine-checked. The recorded commands are in
`fvk/PROOF.md`, but this task forbids running K tooling, tests, or Python. No
test files were modified.
