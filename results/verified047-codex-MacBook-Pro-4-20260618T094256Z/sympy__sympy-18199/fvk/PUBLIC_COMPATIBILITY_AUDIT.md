# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`sympy.ntheory.residue_ntheory.nthroot_mod(a, n, p, all_roots=False)`

- Signature: unchanged.
- Return shape: unchanged. Scalar mode returns an integer or `None`; `all_roots=True` returns a list or `None`.
- New behavior: prime-modulus zero-residue inputs return `0` or `[0]` before entering nonzero nth-root algorithms.

## Callers

`repo/sympy/solvers/solveset.py::_invert_modular` calls `nthroot_mod(rhs, expo, m, all_roots=True)`, treats `None` as no solution, and iterates the returned list. Returning `[0]` for zero-residue prime inputs is compatible with that protocol and supplies the missing residue class.

## Existing Paths Touched By the Edit

- `n == 2`: preserved by leaving the `sqrt_mod` return before the new zero-residue branch.
- `n <= 0` or `p <= 0`: preserved by guarding the new branch with `n > 0 and p > 0`; invalid-domain handling still comes from the existing downstream checks.
- Composite `p`, positive `n != 2`, zero residue: still raises `NotImplementedError`; the branch now reaches that outcome without relying on `is_nthpow_residue`.
- Positive nonzero residues and nonresidues: unchanged because the new branch requires `a % p == 0`.
- Negative nonzero `a`: unchanged because the new branch requires `a % p == 0`; existing `is_nthpow_residue` validation still controls that case.

## Tests

No test files were edited. Existing public tests around composite `NotImplementedError`, nonresidue `None`, and nonzero root correctness remain compatibility evidence but are not removed or changed.
