# Formal Spec English

The constructed K artifacts are `mini-sqf.k` and `sqf-list-spec.k`. They model
the patch at the level needed to distinguish the reported failing behavior from
the intended behavior: lists of `(factor, exponent)` pairs, polynomial
multiplication as an abstract associative operation, and the univariate
combination gate.

## Claim SQF-COMBINE

For any list of polynomial factors already normalized to a common univariate
`Poly` representation, `combine` returns a list containing at most one entry for
each exponent. The factor in that entry is the product of all input factors that
had that exponent.

## Claim SQF-GATED-COMBINE

When the method is `sqf` and the input has exactly one generator with no
multivariate ambiguity, `_generic_factor_list()` applies `combine` to the
numerator and denominator factor lists before sorting and expression conversion.

## Claim FACTOR-LIST-FRAME

When the method is not `sqf`, the generic factor-list path does not call
`combine`; ordinary factorization output remains a list of irreducible factors.

## Claim SHAPE-PRESERVATION

Grouping changes only the factor values inside the factor list. The coefficient,
exponents, `polys` output shape, and fraction split between numerator and
denominator are preserved.

## Claim AMBIGUOUS-MULTIVARIATE-FRAME

The constructed proof does not claim a complete behavior for no-generator
multivariate inputs. The gate leaves that legacy path ungrouped unless a single
generator is explicit or the expression is unambiguously univariate.
