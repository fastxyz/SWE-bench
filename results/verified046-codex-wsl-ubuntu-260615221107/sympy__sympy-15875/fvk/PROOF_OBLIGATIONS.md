# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## PO1: Intent adequacy

The formal contract must encode the public intent that `is_zero` may return
`None` when undecidable but must not return an incorrect boolean.

Discharge: `SPEC.md` maps this intent to the tri-valued result set
`True`/`False`/`None`, with `None` used for undecidable cancellation. The
reported class is encoded as `U`, not legacy `F`.

Findings: F1.

## PO2: Reported expression path

For `-2*I + (1 + I)**2`, the handler's local facts are:

- commutative Add;
- no known nonzero real part;
- two definitely imaginary addends;
- no imaginary-or-zero addend;
- no local same-sign certificate;
- the quick coefficient-zero subquery need not prove zero.

Obligation: the handler must not return `False`; it should return `None` unless
another sound local fact proves `True`.

Discharge: V2 reaches the `im and not im_or_z` block, does not take
`im_zero`, does not take `len(im) == 1`, does not take same-sign certificates,
and falls through to `None`.

K claim: `addZero(true, false, T, false, 2, U, NoSS) => U`.

Findings: F1.

## PO3: V1 recursive-False path removed

V1 obligation: prove it is sound to return `False` whenever
`self.func(*im).is_zero is False` for a multi-term imaginary coefficient sum.

FVK result: this obligation is stronger than needed and depends on a recursive
subquery's negative result rather than a local non-cancellation certificate.

V2 discharge: the code no longer returns `False` merely because `im_zero is
False`. It uses `im_zero` only when truthy, to prove exact cancellation and
return `True`.

Findings: F2.

## PO4: All V2 `False` returns are locally sound

Every `False` return introduced or preserved by the patched block must imply
the Add is nonzero:

- `b.is_zero is False`: the known-real part is nonzero and cannot be canceled
  by purely imaginary-or-zero terms.
- `len(im) == 1`: one definitely imaginary term is nonzero because zero is not
  imaginary.
- all coefficients nonnegative and one positive: coefficient sum is positive.
- all coefficients nonpositive and one negative: coefficient sum is negative.

Discharge: all branches have independent public or arithmetic justification.

K claims: real-part nonzero, singleton, `SSPos`, and `SSNeg` claims.

Findings: F1, F2, F3.

## PO5: `True` returns remain sound

Every `True` return in the audited region must imply exact zero:

- all args known zero;
- known-real part zero with no imaginary or imaginary-or-zero terms;
- known-real part zero and imaginary coefficient sum known zero.

Discharge: V2 adds no new `True` path except the coefficient-sum-known-zero
path, which is mathematically equivalent to cancellation of the definitely
imaginary terms under the trusted subquery.

K claim: coefficient-zero claim.

Findings: F5.

## PO6: Preserve `zero + I` behavior

Obligation: `(a + I).is_zero is False` for `a` known zero must still hold.

Discharge: with zero real part and one definitely imaginary addend, V2 returns
`False` at `len(im) == 1`.

K claim: singleton imaginary claim.

Findings: F3.

## PO7: Preserve `zero + r*I` unknown behavior

Obligation: `(a + r*I).is_zero is None` for `a` known zero and `r` unknown
real must still hold.

Discharge: `r*I` is not definitely imaginary when `r` may be zero; it is routed
through `im_or_z`. With zero real part and `im_or_z=True`, V2 returns `None`.

Findings: F4.

## PO8: Trusted base is explicit

Obligation: identify assumptions not proved by this local FVK pass.

Discharge: `SPEC.md` and `FINDINGS.md` identify lower-level assumption
soundness and mini-model adequacy as the trusted base. The proof does not
claim to verify all SymPy assumptions.

Findings: F5.

## Machine-check Commands

These commands are part of the constructed proof package but were not run:

```sh
kompile fvk/mini-add-is-zero.k --backend haskell
kast --backend haskell fvk/add-is-zero-spec.k
kprove fvk/add-is-zero-spec.k
```
