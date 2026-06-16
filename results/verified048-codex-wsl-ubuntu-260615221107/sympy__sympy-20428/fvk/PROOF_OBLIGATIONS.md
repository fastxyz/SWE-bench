# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Common Denominator Preservation

For `dup_clear_denoms`, the returned `common` is initialized to `K1.one` and
updated by `K1.lcm(common, K0.denom(c))` for each coefficient `c`.

For `dmp_clear_denoms`, `_rec_clear_denoms` performs the same accumulation over
all ground coefficients recursively.

Required result: V1 must not alter the computation of `common`.

Disposition: discharged. V1 adds stripping only after the existing common
denominator computation.

## PO2: Algebraic Denotation Preservation

If `common` is not one, the dense representation is multiplied by `common` using
`dup_mul_ground` or `dmp_mul_ground`. If `common` is one, the representation is
not multiplied.

Required result: the returned dense polynomial denotes `common * f`.

Disposition: discharged modulo the standard dense-polynomial lemma that stripping
leading zero terms preserves polynomial denotation.

## PO3: Univariate Canonical Zero

If the univariate dense result begins with one or more coefficients recognized as
zero after denominator multiplication, `dup_clear_denoms` must remove those
leading zeros. In particular, `[EX(0)]` must become `[]`.

Disposition: discharged by the V1 call to `dup_strip(f)` before return or
conversion.

## PO4: Recursive Multivariate Canonical Zero

If denominator clearing makes an inner coefficient polynomial zero, the inner
polynomial must be stripped before the outer level decides whether that
coefficient is zero.

Disposition: discharged by the V1 call to `_rec_strip(f, u)`. This is stronger
than a top-level-only `dmp_strip(f, u)`, which would not transform `[[EX(0)]]`
into `[[]]`.

## PO5: Convert Path Preservation

When `convert=True`, the returned representation must preserve the same
polynomial value while changing the coefficient domain. When `K0 == K1`, the
conversion helper may return the original list unchanged, so canonicalization
must happen before conversion.

Disposition: discharged. V1 strips before calling `dup_convert`/`dmp_convert`.
If conversion is a no-op, the result is already canonical; if conversion is not a
no-op, the existing conversion helpers also strip their converted results.

## PO6: Wrapper Observable Behavior

`DMP.per()` constructs `DMP(rep, dom, lev, ring)` directly when the level is
known, so wrappers will not repair a non-canonical list returned by dense
helpers.

Required result: dense helpers must return canonical representations before
`DMP.per()` is called.

Disposition: discharged by PO3 and PO4.

## PO7: Public Compatibility

No public signatures, return arities, or call protocols may change.

Disposition: discharged. V1 changes only the returned representation from
non-canonical to canonical where leading zeros are present.

## Commands To Machine-Check Later

Not executed in this session:

```sh
kompile fvk/mini-dense-polys.k --backend haskell
kast --backend haskell fvk/clear-denoms-spec.k
kprove fvk/clear-denoms-spec.k
```
