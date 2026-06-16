# FVK Notes

V1 stands unchanged.

The audit kept the existing source edit because `fvk/FINDINGS.md` F-1 and F-2
are discharged by `fvk/PROOF_OBLIGATIONS.md` PO-5, PO-6, and PO-7: for a
supported prime-modulus call with `a % p == 0`, the correct scalar result is
`0`, and the complete `all_roots=True` result is `[0]`.

I did not move the zero-residue guard earlier. F-3 ties that placement to PO-1,
PO-2, PO-3, and PO-4: existing coercion, validation, `sqrt_mod` delegation,
non-residue `None`, and composite `NotImplementedError` behavior all remain in
front of the new branch.

I did not broaden the fix to composite moduli. F-4 and PO-4 identify composite
`n > 2` nth roots as an existing compatibility boundary, not a safe partial
extension. In particular, returning `[0]` for `all_roots=True` would be
incomplete for composite moduli with additional nilpotent roots.

I added the FVK artifacts under `fvk/`, including the reduced K model and spec
claims. Per F-5 and PO-10, these are constructed artifacts only; I did not run
tests, Python, `kompile`, `kast`, or `kprove`.
