# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO1: Domain and helper-contract preconditions

For the audited branch, `u > 0` and `K.is_Algebraic` hold. Existing helper
contracts for dense-polynomial arithmetic and algebraic factorization are in
scope. Unsupported domains are outside this function's algebraic-extension
branch.

Source: `dmp_ext_factor` docstring and call path through `dmp_factor_list`.

## PO2: Ground normalization

Lines 1143-1144 compute `lc = dmp_ground_LC(A, u, K)` and
`F = dmp_ground_monic(A, u, K)`. Obligation:

`A = lc * F`.

The constant branch at lines 1146-1147 returns `lc, []`, which satisfies the
empty product case.

## PO3: Primitive split preserves product

Line 1150 computes `G, P = dmp_primitive(F, u, K)`. Obligation:

`F = lift(G) * P`, where `G` is a polynomial at level `u - 1`, and `P` has no
non-unit lower-variable content.

This is the proof point that prevents `dmp_sqf_part` from seeing and discarding
lower-variable content.

## PO4: Recursive content factorization is complete

Line 1152 computes `coeff, content_factors = dmp_factor_list(G, u - 1, K)`.
Obligation:

`G = coeff * product(g_i**k_i for (g_i, k_i) in content_factors)`.

Line 1154 lifts each `g_i` to `[g_i]`. Obligation:

`lift(product(g_i**k_i)) = product(lift(g_i)**k_i)`.

## PO5: Coefficient preservation

Line 1153 updates `lc *= coeff`. Obligation:

If `A = lc0 * F` and `G = coeff * content_product`, then the final coefficient
`lc0 * coeff` accounts for the content factorization coefficient exactly once.

## PO6: Primitive square-free norm path is applied only to primitive `P`

Lines 1156-1171 run the existing square-free norm reconstruction only when
`degree(P, leading_variable) > 0`. Obligation:

Since `P` is primitive with respect to the leading variable, applying
`dmp_sqf_part(P, u, K)` cannot drop a lower-variable content factor.

The existing norm path must reconstruct a candidate list `H` whose product is
the square-free primitive part of `P`, up to unit/order.

## PO7: Primitive multiplicities are recovered against original monic `F`

Line 1173 calls `dmp_trial_division(F, H, u, K)`. Obligation:

For each candidate primitive factor `h` in `H`, trial division returns the
largest exponent `m` such that `h**m` divides `F`. This preserves repeated
leading-variable factors even though the norm path uses a square-free part.

## PO8: Final recombination

Line 1175 returns `_sort_factors(content_factors + primitive_factors)`.
Obligation:

`final_coeff * product(final_factors) = A`.

Derivation:

`A = lc0 * F`

`F = lift(G) * P`

`G = coeff * content_product`

`P = primitive_product`

Therefore:

`A = (lc0 * coeff) * lift(content_product) * primitive_product`.

Sorting does not change the product.

## PO9: Reported example

For `A = (x - 1)*(y - 1)` with leading variable `x`:

`G = y - 1`

`P = x - 1`

Recursive content factorization gives `[y - 1]` with multiplicity `1`; the
primitive path gives `x - 1` with multiplicity `1`; the final product preserves
both factors.

This directly discharges the public issue example.

## PO10: Termination and recursion boundary

The new recursive call factors `G` at level `u - 1`, so the content recursion
strictly decreases the variable level. Termination of the existing
square-free-norm and factor-list helpers is not reproved in this FVK pass.

Classification: partial correctness proof with helper termination left to
existing SymPy assumptions.

## PO11: Compatibility

No public signature, return shape, or dispatch protocol changed. Existing
callers still receive `(coefficient, factors)`.

