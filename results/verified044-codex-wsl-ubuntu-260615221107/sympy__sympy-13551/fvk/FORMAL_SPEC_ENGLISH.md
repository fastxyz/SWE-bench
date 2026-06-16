# Formal Spec English

These are the English meanings of the constructed claims in
`product-add-spec.k`.

## C1: additive numeric-denominator fallback

For an additive term after `as_numer_denom`, if the denominator product is a
number, the additive branch returns `none`. This means the caller must leave
the original product unevaluated rather than adding products of the summands.

## C2: additive denominator-failure fallback

If the denominator product cannot be evaluated, the additive branch returns
`none`.

## C3: additive numerator-failure fallback

If denominator clearing gives a non-number denominator product but the
numerator product cannot be evaluated, the additive branch returns `none`.

## C4: rational additive success path

If denominator clearing gives a non-number denominator product and the numerator
product evaluates, the additive branch returns the quotient of those two product
results.

## C5: `Product.doit()` fallback

If `_eval_product` returns `none`, the modeled `Product.doit()` path returns an
unevaluated product outcome.

## C6: issue-term derivation

For `n + 2**(-k)`, denominator clearing first exposes a non-number denominator
product, but the numerator is still an unevaluable additive expression. C3 and
C5 therefore imply that the symbolic product remains unevaluated rather than
becoming the false sum `2**(n*(-n + 1)/2) + n**n`.

## C7: `k**(S(2)/3) + 1` derivation

For `k**(S(2)/3) + 1`, denominator clearing leaves denominator `1`, whose
product is numeric. C1 and C5 therefore imply that the symbolic product remains
unevaluated rather than becoming `1`.

