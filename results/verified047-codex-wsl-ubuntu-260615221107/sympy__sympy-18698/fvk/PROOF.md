# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims

The constructed K claims are in `sqf-list-spec.k` and are paraphrased in
`FORMAL_SPEC_ENGLISH.md`.

The central claim is:

For every univariate square-free factor list normalized to `Poly` entries,
combining by exponent returns one entry per exponent, where the entry's factor is
the product of all factors that originally had that exponent.

## Proof Sketch For `_combine_factors()`

Prove by induction over the input factor list.

Base case:

The empty list has no exponents. `_combine_factors([])` returns `[]`, which has
one entry per exponent vacuously and preserves the product for every exponent.

Inductive step:

Assume the recursive/processed prefix invariant holds for a combined list `C`.
Process one new pair `(f, k)`.

Case 1: `C` already contains an entry `(g, k)`.

The helper replaces that entry with `(g*f, k)`. By associativity and
commutativity of polynomial multiplication in this domain, `g*f` is exactly the
product of the previous exponent-`k` factors and the new factor `f`. No other
exponent group changes.

Case 2: `C` contains no entry with exponent `k`.

The helper appends `(f, k)`. This creates exactly one entry for exponent `k`,
with product `f`, and leaves all existing exponent groups unchanged.

Thus after every iteration, each exponent appears at most once and its factor is
the product of all processed factors with that exponent. At loop exit all input
factors have been processed, so PO-1 holds.

## Proof Sketch For `_generic_factor_list()`

The relevant source order is:

1. `_symbolic_factor_list()` builds raw numerator and denominator factor lists.
2. `_generic_factor_list()` converts non-`Poly` entries to `Poly` using `_opt`.
3. If `method == 'sqf'` and `_sqf_list_should_combine(...)`, V1 applies
   `_combine_factors()` to `fp` and `fq`.
4. The existing `_sorted_factors()` call orders the grouped entries.
5. The existing `polys` branch converts grouped `Poly` factors to expressions
   only when requested.

Step 2 discharges PO-2 because grouping operates on polynomial objects. Step 3
discharges PO-3 and PO-7 because grouping is limited to square-free output in
the verified univariate/single-generator domain. Step 4 discharges PO-8 because
V1 reuses the existing sort. Step 5 discharges PO-4 because V1 does not bypass or
replace the existing output-shape logic.

Applying the `_combine_factors()` induction separately to `fp` and `fq`
discharges PO-5. For empty factor lists, the base case discharges PO-6.

## Reported Example

For the issue input, the generic factor list contains the exponent-`3` entries
`(x - 3, 3)` and `(x - 2, 3)`. Both are converted to `Poly` entries before
grouping. `_combine_factors()` reaches Case 1 for the second exponent-`3` entry
and replaces the previous exponent-`3` product with:

`Poly(x - 3, x) * Poly(x - 2, x) = Poly(x**2 - 5*x + 6, x)`.

The final expression output is therefore `(x**2 - 5*x + 6, 3)` for multiplicity
`3`, as required by PO-1.

## Residual Risk

This is partial correctness for the modeled grouping behavior. It does not prove
termination separately, although `_combine_factors()` structurally iterates over
a finite Python list. It also does not model full SymPy polynomial domains or all
multivariate square-free behavior.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-sqf.k --backend haskell
kast --backend haskell fvk/sqf-list-spec.k
kprove fvk/sqf-list-spec.k
```

Expected outcome if the miniature semantics and claims are accepted by K:
`kprove` should discharge the stated grouping claims to `#Top`. This expectation
is constructed reasoning only, not an observed result.
