# FVK Spec

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Scope

The target is the V1 change in `repo/sympy/polys/polytools.py`:

- `_combine_factors()`
- `_sqf_list_should_combine()`
- the `method == 'sqf'` grouping branch in `_generic_factor_list()`

The verified intent is expression-level `sqf_list()` behavior for univariate
polynomial input, including the common case where the input is already factored
and the public helper receives a generic factor list with repeated exponents.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations are:

1. For univariate `sqf_list()`, there must be one returned factor per
   multiplicity.
2. All factors sharing a multiplicity must be multiplied into that returned
   factor.
3. This must match the `Poly(...).sqf_list()` convention for univariate input.
4. The repair should scan/post-process the generic factor list.
5. Ordinary `factor_list()` must not be changed.
6. Multiple-generator or no-generator multivariate behavior is ambiguous and is
   not used as proof that V1 is complete beyond the univariate contract.

## Contract

Let `F = [(p_1, e_1), ..., (p_n, e_n)]` be the list of polynomial factors
produced by `_symbolic_factor_list()` and normalized by `_generic_factor_list()`
to `Poly` objects in a common univariate generator.

For each exponent `e`, define:

`P_e = product(p_i for i in 1..n if e_i == e)`.

For `sqf_list()` in the verified domain, the returned factor list must contain
exactly one pair `(P_e, e)` for each exponent appearing in `F`. Sorting may
determine display order, but it must not split a multiplicity group.

For `factor_list()`, this contract does not apply.

## Frame Conditions

- The numeric coefficient `cp/cq` is unchanged.
- Numerator and denominator factor lists remain separate when `frac=True`.
- The `polys` flag still controls whether returned factors are `Poly` objects or
  expressions.
- Empty factor lists remain empty.
- No-generator multivariate inputs remain outside the proven contract unless the
  expression is unambiguously univariate.

## Formal Artifacts

- `mini-sqf.k` defines the abstract list-combination semantics used for the
  constructed proof.
- `sqf-list-spec.k` states the K claims corresponding to the contract above.

Commands that would machine-check the constructed artifacts in an environment
with K installed:

```sh
kompile fvk/mini-sqf.k --backend haskell
kast --backend haskell fvk/sqf-list-spec.k
kprove fvk/sqf-list-spec.k
```

These commands are recorded only; they were not run.
