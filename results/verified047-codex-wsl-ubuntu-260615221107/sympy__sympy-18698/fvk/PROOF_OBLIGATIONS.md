# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: One Factor Per Multiplicity

For every univariate `sqf_list()` factor list normalized to `Poly` entries,
all entries with the same exponent must be replaced by exactly one entry whose
factor is the product of those entries' factors.

Evidence: E1, E2, E3, E4.

Discharged by: `_combine_factors()` and Claim SQF-COMBINE.

## PO-2: Group After `Poly` Normalization

Grouping must occur after `_generic_factor_list()` converts all returned factors
to `Poly` instances, so multiplication is polynomial multiplication rather than
ad hoc expression string manipulation.

Evidence: E3, E4.

Discharged by: the V1 placement of `_combine_factors(fp)` and
`_combine_factors(fq)` after the conversion loop and before `_sorted_factors()`.

## PO-3: Do Not Change `factor_list()`

The grouping operation must not run for ordinary factorization.

Evidence: E8.

Discharged by: `if method == 'sqf' and _sqf_list_should_combine(...)`.

## PO-4: Preserve Output Shape Flags

The `polys` flag must continue to decide whether factor entries are returned as
`Poly` objects or as expressions.

Evidence: existing `polytools.py` API behavior and public tests around
`sqf_list(..., polys=True)` and `sqf_list(..., polys=False)`.

Discharged by: grouping before the existing `if not opt.polys` conversion branch.

## PO-5: Preserve Fraction Shape

When `frac=True`, numerator and denominator factor lists must remain separate.

Evidence: existing `_generic_factor_list()` contract.

Discharged by: applying `_combine_factors()` independently to `fp` and `fq`.

## PO-6: Preserve Empty Factor Lists And Constants

Constant inputs that currently produce an empty factor list must remain empty
unless a future public-intent clarification says constants should error.

Evidence: existing public behavior and ambiguous issue discussion.

Discharged by: `_combine_factors([]) == []` and `_sqf_list_should_combine()`
returning false when no generator has been inferred.

## PO-7: Do Not Claim Ambiguous Multivariate Completeness

The proof must not use legacy no-generator multivariate behavior as an intended
postcondition, and it must not broaden the patch into a multivariate behavior
change without public intent.

Evidence: E5, E6, E7.

Discharged by: `_sqf_list_should_combine()` requiring a single generator and, if
the caller did not supply one, no multivariate ambiguity.

## PO-8: Keep Sorting Deterministic After Grouping

Grouping changes the set of entries but must still pass through the existing
square-free sorting policy.

Evidence: existing `_sorted_factors(..., method='sqf')` behavior.

Discharged by: V1 grouping before the existing `_sorted_factors()` calls.
