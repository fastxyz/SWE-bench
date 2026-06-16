# FVK Proof

Status: constructed, not machine-checked. No K tooling was run.

## Claims Proved in the Constructed Model

The proof covers the dispatch prefix of `nthroot_mod` after integer coercion,
with `is_nthpow_residue(a, n, p)` and `isprime(p)` abstracted as Boolean inputs.
This is the code region changed by V1.

Claim `ZERO-SINGLE`: if `n > 0`, `n != 2`, `p` is prime, `a % p == 0`, and
`all_roots=False`, then the function returns scalar `0`.

Claim `ZERO-ALL`: under the same preconditions with `all_roots=True`, the
function returns `[0]`.

Claim `COMPOSITE-FRAME`: if `n > 0`, `n != 2`, and `p` is composite, the
function keeps the existing `NotImplementedError` branch.

## Symbolic Proof Sketch

For `ZERO-SINGLE`, symbolic execution begins at:

```k
<k> nthrootMod(A, N, P, false, true, true) </k>
```

with side conditions `N > 0`, `N =/= 2`, `P > 1`, and `A mod P == 0`. The first
three dispatch rules do not match: `N` is not `2`, the residue predicate is not
false, and the prime predicate is not false. The V1 zero-residue rule matches
and rewrites the state to:

```k
<k> Single(0) </k>
```

For `ZERO-ALL`, the same symbolic execution applies with `AllRoots=true`; the
matching V1 rule rewrites the state to:

```k
<k> ZeroList </k>
```

`ZeroList` represents the Python return value `[0]`.

The mathematical side condition needed for completeness of `[0]` is PO-7: for
prime `P` and positive `N`, `X ** N == 0 (mod P)` implies `X == 0 (mod P)`.
Thus no other roots are omitted by returning `[0]`.

For `COMPOSITE-FRAME`, symbolic execution begins with `IsPrime=false`. The
composite rule matches before any zero-residue rule, reaching
`NotImplemented`. This models V1's source order and preserves the existing
public compatibility boundary.

## Reproduce the Machine Check Later

These commands are emitted for later verification and were not executed:

```sh
kompile fvk/mini-nthroot.k --backend haskell
kast --backend haskell fvk/nthroot-mod-spec.k
kprove fvk/nthroot-mod-spec.k --definition fvk/mini-nthroot-kompiled
```

Expected result after a successful machine check: `#Top` for all claims.

## Residual Risk

This is a partial-correctness proof for the modeled dispatch prefix. It does
not prove termination, although the modeled prefix has no loop. It does not
re-prove the helper algorithms for nonzero residues. It relies on the adequacy
of the reduced K model and on the prime divisibility lemma in PO-7.

No test deletion is recommended. Future tests for
`nthroot_mod(17*17, 5, 17) == 0` and
`nthroot_mod(17*17, 5, 17, True) == [0]` would be subsumed by the proof only
after the K commands are actually run and return `#Top`.
