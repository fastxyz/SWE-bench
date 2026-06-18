# Intent Specification

Status: constructed, not machine-checked.

## Public Intent

Target: `repo/sympy/ntheory/residue_ntheory.py::nthroot_mod`.

The public issue says that for the congruence `x**n = a mod p`, when `a % p == 0`, `x = 0 mod p` is a root and `nthroot_mod` currently misses it. The function docstring says it finds solutions to `x**n = a mod p`, with `a` an integer, `n` a positive integer, `p` a positive integer, and `all_roots=False` returning one root while `all_roots=True` returns the list of roots.

## Obligations

1. For positive `n`, positive prime `p`, and integer `a` with `a % p == 0`, `nthroot_mod(a, n, p, False)` must return `0`.
2. For the same zero-residue inputs with `all_roots=True`, the returned list must contain the zero residue. Because `p` is prime, the root set of `x**n == 0 mod p` is exactly `{0}`, so the list obligation is `[0]`.
3. The example `nthroot_mod(17*17, 5, 17)` is an instance of obligation 1 and must return `0`.
4. The obligation is stated in terms of `a % p == 0`, not `a == 0` or `a >= 0`; negative integer multiples of positive prime `p` are in scope for this zero-residue obligation.
5. Existing public behavior outside the zero-residue case must be preserved unless directly contradicted by the zero-residue obligation:
   - `n == 2` remains delegated to `sqrt_mod`.
   - Composite moduli for `n > 2` remain not implemented.
   - Nonresidue cases still return `None`.
   - Nonzero prime-residue cases still use the pre-existing nth-root solver path.
6. No test files may be modified; any test recommendations are advisory only.

## Default-Domain Assumptions

- The audit is partial correctness only: if the function returns, the postcondition must hold. Termination of the pre-existing nonzero solver is not re-proved.
- Python integer modulo is the relevant interpretation of `a % p`, matching the issue wording and the implementation language.
- Prime modulus uniqueness for the zero root uses the standard number-theory fact: if prime `p` divides `x**n` and `n > 0`, then `p` divides `x`.
