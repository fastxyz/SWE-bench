# Formal Spec English

Status: constructed, not machine-checked.

## Claim: Zero Scalar

For every integer `A`, positive integer `N` with `N != 2`, and positive prime `P`, if `A % P == 0`, then `nthroot_mod(A, N, P, False)` reaches return value `0`. The postcondition states that `0` is an nth root of `A` modulo `P`.

## Claim: Zero List

For every integer `A`, positive integer `N` with `N != 2`, and positive prime `P`, if `A % P == 0`, then `nthroot_mod(A, N, P, True)` reaches return value `[0]`. The postcondition states that this is the exact singleton zero-root list for the prime-modulus zero-residue case.

## Claim: Square-Root Frame

For `N == 2`, `nthroot_mod(A, 2, P, AR)` returns the abstract result of `sqrt_mod(A, P, AR)`. The zero-residue fix does not intercept or alter square-root behavior.

## Claim: Nonresidue Frame

For `N != 2`, if the abstract nth-power-residue predicate is false, `nthroot_mod` returns `None`. The zero-residue fix does not change nonresidue behavior.

## Claim: Composite Zero Frame

For positive `N != 2`, positive composite `P`, and `A % P == 0`, `nthroot_mod` reaches the existing composite-modulus not-implemented result. The zero-residue fix does not claim composite nth roots are implemented.

## Claim: Nonzero Solver Frame

For `N != 2`, prime `P`, and residue inputs outside the zero-residue class, `nthroot_mod` reaches the existing nonzero solver path, represented by `nonzeroResult(A, N, P, AR)`.

## Open Obligation: Prime-Zero-Unique

For prime `P` and positive `N`, the only residue class whose nth power is `0 mod P` is `0`. This follows from Euclid's lemma, but the mini K semantics abstracts primality and modular exponentiation, so the obligation is recorded separately as an escalation boundary for a richer number-theory theory.
