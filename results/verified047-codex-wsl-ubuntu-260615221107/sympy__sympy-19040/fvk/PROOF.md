# FVK Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims Proved, Conditional on Helper Contracts

Claim C1: For every in-domain nonconstant multivariate polynomial `A` over an
algebraic field `K`, V1 `dmp_ext_factor(A, u, K)` returns a coefficient and
factor list whose product equals `A`.

Claim C2: If `A` has a factor depending only on lower variables, V1 preserves
that factor by splitting and recursively factoring leading-variable content
before square-free norming the primitive part.

Claim C3: V1 does not change the public API or return shape.

## Symbolic Proof Sketch

1. Branch `u == 0`: the function delegates to `dup_ext_factor`, unchanged by
   V1. This branch is outside the reported multivariate defect.

2. Branch `u > 0`, constant after normalization: lines 1143-1147 return
   `(lc, [])`. By PO2, the empty product equals the normalized constant case.

3. Branch `u > 0`, nonconstant:

   - By PO2, after lines 1143-1144, `A = lc0 * F`.
   - By PO3, line 1150 splits `F = lift(G) * P`, where `G` is lower-variable
     content and `P` is primitive with respect to the leading variable.
   - By PO4, line 1152 recursively factors `G` as
     `coeff * product(g_i**k_i)`.
   - By PO5, line 1153 updates the outer coefficient to `lc0 * coeff`.
   - By PO4, line 1154 lifts each lower-level `g_i` to `[g_i]`, preserving its
     value as a polynomial independent of the leading variable.

4. If `degree(P, leading_variable) == 0`, then all nonconstant factors of `F`
   were in the content `G`. The final coefficient and lifted content factors
   multiply to `A` by PO2-PO5 and PO8.

5. If `degree(P, leading_variable) > 0`, lines 1157-1171 run the existing
   algebraic square-free norm reconstruction on `P`. Because `P` is primitive,
   PO6 rules out the old defect: there is no lower-variable content left for
   `dmp_sqf_part` to discard.

6. Line 1173 recovers primitive-factor multiplicities by trial division against
   `F`, not only against the square-free part. By PO7, repeated primitive
   factors are preserved.

7. Line 1175 sorts the combined factor list. By PO8, sorting is product-neutral:

   `final_coeff * product(final_factors)`

   `= (lc0 * coeff) * lift(content_product) * primitive_product`

   `= lc0 * F`

   `= A`.

## Reported Example Derivation

Input: `A = (x - 1)*(y - 1)` over `QQ(I)` with leading variable `x`.

V1 split:

- `G = y - 1`
- `P = x - 1`

Recursive lower-level factorization returns `(1, [(y - 1, 1)])`; lifting gives
`([y - 1], 1)`. The primitive norm path returns `x - 1` with multiplicity `1`.
The final product is `(x - 1)*(y - 1)`, so the dropped-factor symptom is removed.

## K Artifacts

The K files encode the proof at the abstract factorization level:

- `fvk/mini-sympy-factor.k`
- `fvk/dmp-ext-factor-spec.k`

Exact commands for a future environment, not executed here:

```sh
kompile fvk/mini-sympy-factor.k --backend haskell
kast --backend haskell fvk/dmp-ext-factor-spec.k
kprove fvk/dmp-ext-factor-spec.k
```

Expected result after supplying/proving the helper algebra lemmas: `#Top`.

## Residual Risk

This proof is not a full machine-checked proof of SymPy's dense-polynomial
library. It assumes the standard contracts of helper functions documented and
used throughout `factortools.py`, including `dmp_primitive`,
`dmp_factor_list`, `dmp_sqf_norm`, `dmp_inner_gcd`, `dmp_compose`, and
`dmp_trial_division`. Full verification would require a larger K model of dense
recursive polynomial representations and algebraic-number-field arithmetic.

## Test Guidance

No tests were run or edited. If tests could be added, the reported example and
the repeated-content cases listed in `FINDINGS.md` would be the high-value
regressions. No test-removal recommendation is made because the proof is not
machine-checked and the hidden/public test suite is fixed for this task.

