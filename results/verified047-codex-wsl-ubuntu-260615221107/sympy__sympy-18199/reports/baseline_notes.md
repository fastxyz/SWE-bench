# Baseline Notes

## Root cause

`nthroot_mod` checks `is_nthpow_residue(a, n, p)`, which correctly accepts
values with `a % p == 0`, but then continues into algorithms that work in the
nonzero multiplicative group modulo prime `p`. Those helper paths construct
nonzero roots using primitive roots, discrete logarithms, or a reduction based
on `x**(p - 1) - 1`, so they can miss the valid zero root for equations such as
`x**5 = 17*17 mod 17`.

## Changed files

- `repo/sympy/ntheory/residue_ntheory.py`: added a prime-modulus zero-residue
  case in `nthroot_mod` after the existing unsupported-composite check. For
  prime `p`, `x**n == 0 (mod p)` has the single solution `x == 0 (mod p)`, so
  the function now returns `0` or `[0]` depending on `all_roots`.

## Assumptions and alternatives

- I assumed the issue targets the implemented prime-modulus branch of
  `nthroot_mod`. The existing `NotImplementedError` for composite moduli with
  `n > 2` is preserved, because composite zero residues can have more than one
  root and would require broader support.
- I left the `n == 2` path delegated to `sqrt_mod`, since that implementation
  already handles zero residues.
- I considered changing `_nthroot_mod1`, but rejected that because the missing
  case is not part of its stated domain: it operates on roots in the
  multiplicative group modulo prime `p`, while `0` is outside that group.
- I did not run tests or project code, in accordance with the task instructions.
