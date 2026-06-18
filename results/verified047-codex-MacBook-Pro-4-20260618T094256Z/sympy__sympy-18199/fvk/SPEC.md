# Developer Spec

Status: constructed, not machine-checked.

## Scope

This FVK package audits the V1 change to `nthroot_mod` and the minimal V2 correction derived from the audit. The source behavior under audit is the dispatch in `nthroot_mod` around the new zero-residue branch. The pre-existing nonzero nth-root algorithms are represented as an abstract `nonzeroResult(...)` frame because this task does not alter their code; the proof obligation is that the zero-residue fix does not redirect nonzero inputs away from that old path.

## Contract

For integer `a`, positive integer `n`, positive prime `p`, and `a % p == 0`:

- `nthroot_mod(a, n, p, False)` returns `0`.
- `nthroot_mod(a, n, p, True)` returns `[0]`.

For `n == 2`, `nthroot_mod` delegates to `sqrt_mod(a, p, all_roots)` as before.

For `n > 0`, `n != 2`, positive `p`, and `a % p == 0` with composite `p`, `nthroot_mod` raises the same composite-modulus `NotImplementedError` sentinel represented in the model as `NotImplemented`.

For `n != 2` nonresidues, `nthroot_mod` returns `None` as before. For nonzero prime residues, it reaches the pre-existing nonzero solver path unchanged.

## Ledger Mirror

- E1/E2/E3 require zero to be returned/included when `a % p == 0`.
- E4/E6 require returned values to be modular roots and require scalar/list return shapes.
- E5 puts negative multiples of `p` in scope for the zero-residue obligation because `nthroot_mod` documents `a` as an integer and the issue uses the modulo condition.
- E7/E8/E10 are frame conditions for paths the V1/V2 fix must not regress.
- E9 confirms the list return shape remains compatible with the public `solveset` caller.

## Revision Decision

The audit found that V1 placed the zero-residue check after `is_nthpow_residue`. That helper rejects `a < 0`, so V1 fails the public zero-residue obligation for inputs such as `a = -p`, `n = 5`, positive prime `p = 17`. The required source change is to handle the zero-residue branch before calling `is_nthpow_residue`, while guarding it with `n > 0` and `p > 0` so the existing invalid-domain behavior for `n <= 0` and `p <= 0` is preserved.
