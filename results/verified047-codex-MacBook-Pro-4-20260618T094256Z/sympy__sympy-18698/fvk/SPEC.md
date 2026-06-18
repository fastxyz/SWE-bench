# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audit covers V1's new `_combine_factors()` helper and the `method == 'sqf'`
call site in `_generic_factor_list()` in `repo/sympy/polys/polytools.py`.

The mini K model abstracts a `Poly` as `atom(generator_key, id)` or a product
tree `pprod(left, right)`. This preserves the observable under audit:
generator tuple equality, multiplicity equality, factor-list order, and whether
polynomials are multiplied into a single factor-list entry. It does not model
SymPy coefficient arithmetic or expansion.

## Developer-Readable Contract

1. `_combine_factors(factors)` returns a factor list in first-key order.

2. For every input factor `(factor, exp)`, its key is `(factor.gens, exp)`.

3. If a key appears once, the output has that same factor and exponent.

4. If a key appears multiple times, the output has one entry for that key. The
   output factor is the product of the input factors for that key, in input
   encounter order. The exponent is unchanged.

5. Factors with different generator tuples are not combined by V1, even when
   they have the same exponent. This is a compatibility frame for the current
   mixed-generator public behavior and the public issue's ambiguity around
   multiple generators.

6. `_generic_factor_list(..., method='sqf')` applies this combination to both
   numerator and denominator factor lists after conversion to `Poly` and before
   the existing sort/output conversion.

7. `_generic_factor_list(..., method='factor')` does not call the helper, so
   ordinary irreducible `factor_list()` behavior is unchanged.

8. The fix does not alter coefficient handling, fraction rejection/return
   shape, sorting rules, `polys=True/False` conversion, or non-expression error
   behavior.

## Mirrored Evidence Ledger

- E1/E2: the reported univariate multiplicity-3 pair must become one product.
- E3: the repair should scan and post-process the generic factor list.
- E4: grouping applies to equal multiplicities generally.
- E5/E6: multiple-generator behavior is ambiguous and currently covered by a
  compatibility test; V1 should not broaden the change without a concrete proof
  finding.
- E7: `factor_list()` is a frame condition.
- E8: V1's minimal post-processing strategy is the candidate under audit.

## Formal Residual

`sqf-combine-obligations.k` records the full arbitrary-list grouping theorem as
an escalation-bounded obligation. The concrete claims in `sqf-combine-spec.k`
cover the reported counterexample shape, the equal-exponent family, mixed-gen
frame behavior, and method dispatch frame behavior.
