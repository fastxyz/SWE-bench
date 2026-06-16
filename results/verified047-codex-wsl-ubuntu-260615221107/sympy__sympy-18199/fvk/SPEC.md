# FVK Specification for `nthroot_mod`

Status: constructed for audit; not machine-checked.

## Scope

This FVK pass audits the changed public function
`sympy.ntheory.residue_ntheory.nthroot_mod` for the reported zero-residue bug.
The formal core models the dispatch prefix that V1 changed: `n == 2`
delegation, residue rejection, composite-modulus rejection, and the new
prime-modulus zero-residue return. The full discrete-log and Euclidean helper
algorithms for nonzero residues are framed as unchanged behavior, not re-proved.

Machine-checkable core:

- `fvk/mini-nthroot.k`
- `fvk/nthroot-mod-spec.k`

## Intent-Only Specification

I1. Source: `benchmark/PROBLEM.md`

Quote: "when a % p == 0. Then x = 0 mod p is also a root"

Obligation: for supported calls to `nthroot_mod(a, n, p)`, a zero residue must
not be routed only through nonzero-residue algorithms; root `0 mod p` must be
returned when it is the requested root.

I2. Source: `benchmark/PROBLEM.md`

Quote: "`nthroot_mod(17*17, 5 , 17)` has a root `0 mod 17`"

Obligation: the concrete prime-modulus example belongs to the intended domain.
Since `p = 17` is prime and `n = 5 > 0`, the default result must be `0`.

I3. Source: `nthroot_mod` docstring

Quote: "Find the solutions to `x**n = a mod p`"; "`n : positive integer`";
"`all_roots : if False returns the smallest root, else the list of roots`"

Obligation: for `all_roots=False`, return a single smallest root. For
`all_roots=True`, return the list of roots. In the prime zero-residue case,
that list is exactly `[0]`.

I4. Source: public tests in `repo/sympy/ntheory/tests/test_residue.py`

Quote: composite-modulus `nthroot_mod(..., p=36)` examples raise
`NotImplementedError`.

Obligation: for `n > 2`, composite-modulus support is an existing public
compatibility boundary. The zero-residue fix must not silently claim full
all-roots support for composite moduli.

I5. Source: `sqrt_mod` docstring and `nthroot_mod` implementation

Quote: `if n == 2: return sqrt_mod(a, p, all_roots)`

Obligation: square-root behavior remains delegated to `sqrt_mod`, including
zero-residue behavior already handled there.

## Formal Contract

For integer-coerced inputs in the supported non-square branch:

- Precondition for the zero-residue proof slice:
  `n > 0`, `n != 2`, `p` prime, `p > 1`, `is_nthpow_residue(a, n, p)` is true,
  and `a % p == 0`.
- Postcondition:
  `nthroot_mod(a, n, p, all_roots=False)` returns `0`.
- Postcondition:
  `nthroot_mod(a, n, p, all_roots=True)` returns `[0]`.

Frame conditions:

- If `n == 2`, the function delegates to `sqrt_mod` exactly as before V1.
- If `is_nthpow_residue(a, n, p)` is false, the function returns `None` exactly
  as before V1.
- If `n != 2` and `p` is composite, the function raises `NotImplementedError`
  exactly as before V1.
- If `a % p != 0`, V1 delegates to the pre-existing nonzero-residue algorithms
  exactly as before V1.

## K Claim English

Claim `ZERO-SINGLE`, represented by the first claim in
`fvk/nthroot-mod-spec.k`: from a state modeling a supported prime, nonsquare,
zero-residue call with `all_roots=False`, symbolic execution reaches
`Single(0)`.

Claim `ZERO-ALL`, represented by the second claim: from the same state with
`all_roots=True`, symbolic execution reaches `ZeroList`, the model's value for
Python list `[0]`.

Claim `COMPOSITE-FRAME`, represented by the third claim: from a nonsquare call
whose composite-modulus predicate is false for `isprime`, symbolic execution
reaches `NotImplemented`.

## Adequacy Audit

- I1/I2 versus `ZERO-SINGLE`: pass. The claim is exactly the concrete and
  family obligation for prime zero residues.
- I3 versus `ZERO-ALL`: pass. For prime `p`, if `x**n == 0 (mod p)` and
  `n > 0`, then `p` divides `x`; therefore `[0]` is complete.
- I4 versus `COMPOSITE-FRAME`: pass. Composite all-roots support is not inferred
  from the prime example; the public boundary remains intact.
- I5 versus the `n == 2` frame condition: pass. V1 does not alter that path.

No formal claim depends only on the current V1 output as its expected behavior;
the zero-root postcondition is derived from the problem statement and the prime
divisibility lemma.

## Public Compatibility Audit

- Public API signature: unchanged.
- Return shape: unchanged except for the formerly missing prime zero-residue
  root. `all_roots=False` still returns a scalar root; `all_roots=True` returns a
  list.
- Public callsites: `solveset.py` calls `nthroot_mod(..., all_roots=True)` and
  iterates the returned list if it is not `None`; `[0]` is compatible with that
  consumer.
- Public tests: no test file was modified. Existing composite `NotImplemented`
  expectations remain compatible because the V1 guard is after the composite
  rejection.
