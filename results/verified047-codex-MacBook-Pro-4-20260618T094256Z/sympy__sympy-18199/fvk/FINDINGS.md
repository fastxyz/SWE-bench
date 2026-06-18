# Findings

Status: constructed (escalation-bounded).

## F1: V1 Misses Negative Zero-Residue Inputs

Classification: code bug in V1; resolved by V2 source edit.

Evidence: `benchmark/PROBLEM.md` states the zero-root obligation as `a % p == 0`, and the `nthroot_mod` docstring says `a : integer`. V1 placed the zero-residue return after `is_nthpow_residue(a, n, p)`. That helper raises `ValueError` for `a < 0`, so V1 still fails the zero-residue family for negative multiples of `p`.

Concrete counterexample by symbolic reasoning: `a = -17`, `n = 5`, `p = 17`. Public intent says `-17 % 17 == 0`, so `0` is a root of `x**5 == -17 mod 17`. V1 calls `is_nthpow_residue(-17, 5, 17)` before the zero-residue check; the helper's `a < 0` guard raises instead of returning `0` or `[0]`.

Required edit: move the zero-residue handling ahead of `is_nthpow_residue`, but keep it after the `n == 2` delegation and guard it with `n > 0 and p > 0`.

Regression argument before edit:

- `n == 2` remains first, so `sqrt_mod` behavior is untouched.
- `n <= 0` and `p <= 0` do not enter the new branch, preserving invalid-domain behavior.
- Positive composite zero-residue inputs still raise `NotImplementedError`, matching V1 and public tests for composite unsupported cases.
- Nonzero residue and nonresidue inputs do not satisfy `a % p == 0`, so they follow the same old paths.

## F2: Prime-Zero Uniqueness Is a Proof Capability Boundary

Classification: proof capability gap / `[ESCALATION BOUNDARY]`, not a code bug.

The exact list claim `[0]` relies on the theorem that for prime `p` and positive `n`, `x**n == 0 mod p` implies `x == 0 mod p`. The theorem is standard, but the mini K semantics intentionally abstracts `isPrime` and `powMod`, so bundled `kprove` is not expected to prove this theorem without a richer number-theory theory. It is recorded in `nthroot-mod-obligations.k`.

Recommended next proof work: add a verified modular exponentiation and prime divisibility theory if machine-checking of uniqueness, rather than constructed proof plus math derivation, is required.

## F3: No Additional Source Findings

The audit did not find a concrete counterexample requiring changes to the nonzero nth-root algorithms, `sqrt_mod`, public callsites, or test files. Those behaviors are framed as compatibility obligations and should remain unchanged.

## Decision

V1 does not stand exactly as written because F1 is a concrete public-intent counterexample. The minimal V2 edit is required and regression-bounded by the claims and compatibility audit above.
