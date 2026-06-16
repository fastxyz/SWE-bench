# FVK Specification: `dmp_ext_factor`

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target function: `repo/sympy/polys/factortools.py::dmp_ext_factor`.

The audited behavior is multivariate factorization over algebraic number fields
for `u > 0`. The univariate delegation `u == 0` and the existing square-free
norm reconstruction are treated as existing helper behavior; this FVK pass
focuses on whether the V1 edit preserves factors that depend only on lower
variables.

## Intent Specification

For every nonzero multivariate dense polynomial `A` over an algebraic field `K`
with level `u > 0`, `dmp_ext_factor(A, u, K)` must return `(c, factors)` such
that:

1. `c * product(factor**multiplicity for factor, multiplicity in factors) == A`
   in `K[X]`.
2. A factor may depend only on lower variables. Such a factor is still in scope
   and must not be discarded because it is content with respect to the leading
   variable.
3. Multiplicities are preserved.
4. Factor representation levels are preserved: a factor of the lower-variable
   content is lifted into the current level as a polynomial independent of the
   leading variable.
5. The public API and return shape remain unchanged.

The proof is partial correctness: if helper routines return according to their
documented contracts, the recombined result is a factorization of the input.
Termination and irreducibility of all helper algorithms are not reproved here.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Factor with extension=True drops a factor of y-1" | The reported missing lower-variable factor is in-domain and must be preserved. | Encoded in S1, PO3-PO8 |
| E2 | `benchmark/PROBLEM.md` | `(x-1)*(y-1)` factors normally as `(x - 1)*(y - 1)` but with `extension=[I]` returned `x - 1` | Algebraic-extension factorization must preserve the same complete product, not only the leading-variable primitive part. | Encoded in S1 and example derivation |
| E3 | `factortools.py` docstring | "Factor multivariate polynomials over algebraic number fields." | Domain is all multivariate polynomial factors over algebraic fields, not only factors involving the leading variable. | Encoded in S1 |
| E4 | `sqfreetools.py::dmp_sqf_part` | The implementation takes `gcd(f, diff(f, leading_variable))` | Lower-variable content can be removed by square-free preprocessing if not split first. | Finding F1 |
| E5 | `euclidtools.py::dmp_primitive` | "Returns multivariate content and a primitive polynomial." | Splitting content before square-free norming is an existing helper contract and matches SymPy representation conventions. | Encoded in S2 |
| E6 | `factortools.py::dmp_trial_division` | "Determine multiplicities of factors for a multivariate polynomial using trial division." | Multiplicity recovery should be performed against the original monic polynomial. | Encoded in S4 |

## Formal Claims in English

S1. Completeness: for `u > 0`, nonconstant `A`, and algebraic `K`, the returned
coefficient and factor list multiply back to `A`.

S2. Content preservation: if the monic polynomial `F` is split as
`F = G * P`, where `G` is the leading-variable content and `P` is primitive,
then every recursively returned factor of `G` appears in the final factor list
lifted by one level.

S3. Primitive preservation: if `P` has positive leading-variable degree, the
existing square-free norm path is applied to `P`, not to `F`, so lower-variable
content cannot be removed by `dmp_sqf_part`.

S4. Multiplicity preservation: primitive factors reconstructed from the norm
are passed to `dmp_trial_division(F, H, u, K)`, where `F` is the original monic
polynomial, so multiplicities in the original polynomial are recovered.

S5. Coefficient preservation: if recursive factorization of `G` returns
`coeff`, the outer coefficient is updated from `lc` to `lc * coeff`.

S6. Sorting/frame condition: `_sort_factors` changes only order, not the
coefficient, factors, or multiplicities.

## Adequacy Audit

| Claim | Intent match | Rationale |
| --- | --- | --- |
| S1 | Pass | It directly states the product-preservation requirement implied by the issue. |
| S2 | Pass | It is the exact lower-variable factor obligation from E1-E2. |
| S3 | Pass | It prevents the root cause identified from E4 while preserving the intended norm path. |
| S4 | Pass | It preserves multiplicities, a general factorization requirement from E3 and E6. |
| S5 | Pass | It is required for product equality after recursive content factorization. |
| S6 | Pass | It is a frame condition over output order only; no public evidence requires a specific order. |

No claim relies on the pre-fix buggy output `x - 1`. That output is SUSPECT
legacy behavior under the FVK intent-evidence rule.

## Public Compatibility Audit

Changed public symbol: none.

Changed source function body: `dmp_ext_factor(f, u, K)` only.

Signature change: none.

Return shape change: none; still `(coefficient, [(factor, multiplicity), ...])`.

Public callsites: existing callers invoke `dmp_ext_factor` through
`dmp_factor_list`, ring compatibility wrappers, and direct ring methods. The
V1 edit does not add parameters or change dispatch. Compatibility status: pass.

## Formal Artifacts

Supporting K artifacts:

- `fvk/mini-sympy-factor.k`
- `fvk/dmp-ext-factor-spec.k`

Exact commands to machine-check later, not executed in this session:

```sh
kompile fvk/mini-sympy-factor.k --backend haskell
kast --backend haskell fvk/dmp-ext-factor-spec.k
kprove fvk/dmp-ext-factor-spec.k
```

