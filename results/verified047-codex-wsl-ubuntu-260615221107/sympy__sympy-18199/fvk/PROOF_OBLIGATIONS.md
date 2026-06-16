# FVK Proof Obligations

Status values: `discharged by inspection`, `discharged by constructed K claim`,
`discharged by math lemma`, `framed`, or `open until machine-check`.

## PO-1: Existing coercion and validation still precede the zero guard

Statement: `as_int` conversion and `is_nthpow_residue(a, n, p)` still execute
before the new `a % p == 0` branch for `n != 2`.

Reason: invalid modulus, negative exponent, and negative `a` behavior is part
of the existing validation surface.

Status: discharged by inspection of `nthroot_mod`.

Findings: F-3.

## PO-2: `n == 2` remains delegated to `sqrt_mod`

Statement: if `n == 2`, V1 returns `sqrt_mod(a, p, all_roots)` before the new
zero-residue guard.

Status: discharged by inspection.

Findings: F-3.

## PO-3: Non-residue calls still return `None`

Statement: if `is_nthpow_residue(a, n, p)` is false, V1 returns `None` before
checking `a % p == 0`.

Status: discharged by inspection.

Findings: F-3.

## PO-4: Composite `n > 2` calls still raise `NotImplementedError`

Statement: if `n != 2` and `isprime(p)` is false, V1 raises
`NotImplementedError("Not implemented for composite p")` before the new zero
guard.

Status: discharged by constructed K claim `COMPOSITE-FRAME` and source
inspection.

Findings: F-3 and F-4.

## PO-5: Prime zero-residue scalar result is `0`

Statement: for `n > 0`, `n != 2`, prime `p`, and `a % p == 0`,
`nthroot_mod(a, n, p, all_roots=False)` returns `0`.

Status: discharged by constructed K claim `ZERO-SINGLE` in
`fvk/nthroot-mod-spec.k`.

Findings: F-1.

## PO-6: Prime zero-residue all-roots result is `[0]`

Statement: for `n > 0`, `n != 2`, prime `p`, and `a % p == 0`,
`nthroot_mod(a, n, p, all_roots=True)` returns `[0]`.

Status: discharged by constructed K claim `ZERO-ALL` in
`fvk/nthroot-mod-spec.k`, plus PO-7.

Findings: F-2.

## PO-7: Zero is the unique nth root of zero modulo prime `p`

Statement: if `p` is prime, `n > 0`, and `x**n == 0 (mod p)`, then
`x == 0 (mod p)`.

Proof sketch: `p | x**n`; since `p` is prime, Euclid's lemma gives `p | x`.
Therefore `x` is congruent to zero modulo `p`.

Status: discharged by math lemma.

Findings: F-1 and F-2.

## PO-8: Nonzero-residue algorithms are unchanged

Statement: if `a % p != 0` after validation and prime checking, V1 reaches the
same `_nthroot_mod1`, `_nthroot_mod2`, `sqrt_mod`, or Euclidean reduction paths
as the baseline code.

Status: framed by diff/source inspection; not re-proved.

Findings: F-5.

## PO-9: Public API and callsite compatibility are preserved

Statement: the function signature is unchanged, scalar/list return shapes match
the documented `all_roots` contract, and the public `solveset.py` callsite can
consume `[0]`.

Status: discharged by public compatibility audit in `fvk/SPEC.md`.

Findings: F-2 and F-3.

## PO-10: K proof must be machine-checked before claiming formal verification

Statement: the proof is constructed only. The exact K commands must be run and
return `#Top` before calling it machine-verified or removing tests.

Status: open until machine-check.

Findings: F-5.
