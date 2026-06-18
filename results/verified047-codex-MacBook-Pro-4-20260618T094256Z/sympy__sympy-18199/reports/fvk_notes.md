# FVK Notes

## Outcome

V1 was audited with FVK artifacts under `fvk/`. The audit produced one concrete counterexample against V1, so V1 was minimally corrected.

## Source Change

Changed `repo/sympy/ntheory/residue_ntheory.py::nthroot_mod`.

The zero-residue branch now runs before `is_nthpow_residue`, but still after the `n == 2` `sqrt_mod` delegation. It is guarded by `n > 0 and p > 0` before computing `a % p`, then preserves the existing composite-modulus `NotImplementedError` behavior and returns `0` or `[0]` for prime moduli.

Trace: `fvk/FINDINGS.md` finding F1 shows V1 failed inputs such as `nthroot_mod(-17, 5, 17)` because the issue obligation is stated as `a % p == 0` and `nthroot_mod` documents `a` as an integer, while V1 still called `is_nthpow_residue` first and hit that helper's `a < 0` guard.

## Regression Discipline

The edit is limited to the zero-residue branch named in F1.

- `n == 2` remains delegated to `sqrt_mod`, matching `fvk/nthroot-mod-spec.k` square-root frame claim.
- `n <= 0` and `p <= 0` do not enter the new branch, preserving the prior invalid-domain path.
- Composite zero-residue inputs still raise `NotImplementedError`, matching the composite frame claim.
- Nonzero residues and nonresidues do not satisfy `a % p == 0`, so they remain on the old paths represented by `nonzeroResult` and `None`.

## No Further Edits

`fvk/FINDINGS.md` F2 records prime-zero uniqueness as a proof capability boundary for the mini K model, not a source bug. `fvk/FINDINGS.md` F3 records that no concrete counterexample was found in `sqrt_mod`, the nonzero nth-root solver, public callsites, or tests. Therefore no other source files were changed.

## Verification Status

Artifacts are constructed but not machine-checked. Per the task constraint, I did not run tests, Python, `kompile`, `kast`, `krun`, or `kprove`; `fvk/PROOF.md` contains the commands for a later machine check.
