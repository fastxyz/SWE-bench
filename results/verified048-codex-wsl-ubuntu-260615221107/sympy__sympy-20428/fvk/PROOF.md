# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The formal claims are in `fvk/clear-denoms-spec.k`:

- `DUP-CLEAR-DENOMS-CANONICAL`: `dupClearDenoms(F)` returns the accumulated
  denominator and `dupStrip(dupMulGround(F, C))`.
- `DUP-CLEAR-DENOMS-ZERO`: a one-term polynomial that becomes zero under
  denominator clearing returns `.Poly`, modeling `[]`.
- `DMP-CLEAR-DENOMS-CANONICAL`: `dmpClearDenoms(F)` returns the recursive
  accumulated denominator and `recStrip(dmpMulGround(F, C))`.
- `DMP-CLEAR-DENOMS-INNER-ZERO`: a recursive one-coefficient polynomial whose
  inner leaf becomes zero returns `.DPoly`, modeling recursive canonical zero.

## Proof Sketch

Let `F` be a valid univariate dense representation and let `C` be the lcm of all
coefficient denominators. The original helper already computes `C`; V1 does not
modify that loop, so PO1 is preserved.

If `C` is not one, the original helper computes `dup_mul_ground(F, C, K0)`. If
`C` is one, the dense representation is left as `F`. In either case, call the
intermediate list `G`. `G` denotes `C * F` by the existing dense multiplication
contract. V1 returns `dup_strip(G)` before optional conversion. The standard
dense representation lemma for `dup_strip` says removing leading zero
coefficients preserves denotation and produces a representation whose first
coefficient is nonzero unless the list is empty. Therefore the returned
univariate dense representation denotes `C * F` and is canonical.

For the issue-shaped case, `F = [latentZero]` in the mini model. Its denominator
is `denLatentZero`, so `C = denLatentZero`. Multiplication gives `[zero]`.
`dup_strip([zero])` gives `[]`. This discharges the issue obligation
`DMP([EX(0)]) -> DMP([])` at polynomial level zero.

For recursive dense polynomials, `_rec_clear_denoms` computes the same lcm over
all ground coefficients. Let `G = dmp_mul_ground(F, C, u)` when `C` is not one,
or `G = F` otherwise. V1 returns `_rec_strip(G, u)`. The proof is by structural
induction on the dense level `u`:

Base `u = 0`: `_rec_strip(G, 0)` is `dup_strip(G)`, already proved above.

Step `u > 0`: `_rec_strip` recursively strips every coefficient polynomial at
level `u - 1`, then applies `dmp_strip` at level `u`. By the induction
hypothesis, each child coefficient preserves denotation and is canonical. After
that recursive normalization, `dmp_strip` can correctly identify leading zero
coefficient polynomials and remove them. Thus the multivariate result preserves
denotation and is canonical.

This recursive step is essential: a top-level-only `dmp_strip` on `[[0]]` would
see `[0]` as a non-empty univariate list rather than as canonical zero. Recursive
stripping first transforms `[0]` to `[]`, enabling the outer level to recognize
the zero coefficient polynomial.

Finally, optional conversion preserves the already-cleared polynomial value.
When conversion is a no-op because the domains are equal, V1 has already
canonicalized the list. When conversion is not a no-op, the existing conversion
helpers also strip converted dense results. Therefore both `convert=False` and
`convert=True` satisfy the canonicalization contract.

## Adequacy

The proof proves the representation property the issue requires, not merely
that `as_expr()` can simplify to zero. The observable distinction between
`[EX(0)]` and `[]` is retained in the formal model through `dupStrip`,
`recStrip`, `canonical`, and `dcanonical`.

No claim depends only on V1 behavior. The expected canonical form comes from the
issue text and from SymPy's existing dense zero conventions.

## Residual Risk

The K artifacts are constructed only. They were not parsed or proven in this
session. The proof is also partial correctness only; it does not separately
prove termination of finite Python list traversal.

No tests are recommended for removal. Useful tests to add in a normal
development environment would assert that denominator-cleared zero polynomials
have canonical dense representation and that multivariate inner zero
coefficients are recursively stripped.

## Commands

Not executed here:

```sh
kompile fvk/mini-dense-polys.k --backend haskell
kast --backend haskell fvk/clear-denoms-spec.k
kprove fvk/clear-denoms-spec.k
```
