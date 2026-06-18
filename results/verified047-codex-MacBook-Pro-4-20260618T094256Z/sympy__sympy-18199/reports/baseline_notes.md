# Baseline Notes

## Root Cause

`nthroot_mod` accepted `a` values congruent to zero modulo prime `p`, but then continued into algorithms that are written for nonzero elements of the multiplicative group modulo `p`. The residue predicate already treats `a % p == 0` as soluble, but `nthroot_mod` did not have the corresponding root-construction case. For a prime modulus and positive exponent, the only residue class satisfying `x**n == 0 mod p` is `x == 0 mod p`.

## Files Changed

- `repo/sympy/ntheory/residue_ntheory.py`: added an early return in `nthroot_mod` after the existing composite-modulus rejection. When `a % p == 0` and `p` is prime, the function now returns `0` by default and `[0]` when `all_roots=True`.

## Assumptions and Alternatives

- I preserved the existing `n == 2` path through `sqrt_mod`, because square roots modulo composite numbers are already supported there and may include more than just `0`.
- I placed the zero-residue check after `isprime(p)` so that existing `NotImplementedError` behavior for composite moduli with `n > 2` is unchanged.
- I rejected changing the lower-level `_nthroot_mod1` helper, because the zero case is a top-level modular equation case and handling it in `nthroot_mod` avoids sending zero into routines intended for nonzero multiplicative residues.
- I did not modify tests, as required by the benchmark instructions.
