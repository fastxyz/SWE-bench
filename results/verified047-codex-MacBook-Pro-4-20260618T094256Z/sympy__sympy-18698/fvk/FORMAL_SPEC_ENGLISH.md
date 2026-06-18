# Formal Spec English

Status: constructed, not machine-checked.

## Claim 1: Reported Multiplicity-3 Shape

Given four factors with the same generator key, where the final two factors have
multiplicity `3`, `combineFactors` leaves the multiplicity-1 and multiplicity-2
entries alone and replaces the two multiplicity-3 entries with one product entry
at multiplicity `3`.

## Claim 2: Equal Multiplicity Is a Family Property

Given two same-generator factors at multiplicity `1`, `combineFactors` returns
one product entry at multiplicity `1`. This states that grouping is by equal
multiplicity generally, not only by the specific exponent from the issue.

## Claim 3: Mixed-Generator Compatibility Frame

Given two factors with the same multiplicity but different generator keys,
`combineFactors` leaves them as separate entries. This captures V1's
same-generator restriction and preserves the existing mixed-generator public
example.

## Claim 4: Ordinary Factorization Frame

For `method == factor`, `normalizeFactors` returns the input factor list without
calling `combineFactors`. This means ordinary `factor_list()` output shape is
not changed by the V1 fix.

## Claim 5: Square-Free Dispatch

For `method == sqf`, `normalizeFactors` applies `combineFactors`, so same-key
same-exponent square-free entries are merged before later sorting/output
conversion.

## Claim 6: Loop/Recursion Progress Model

The Python `for factor, exp in factors` loop is modeled as `combineAcc`. Each
step consumes one head factor and recursively continues with the updated
accumulator. This gives the circularity/progress point for the list traversal.

## Open Obligation: Arbitrary Lists

For every finite factor list, the output should contain exactly one entry per
input key in first-occurrence order, with the product of all factors for that key.
This is stated in `sqf-combine-obligations.k` as an escalation boundary because
it needs list induction plus an abstract polynomial-product theory.
