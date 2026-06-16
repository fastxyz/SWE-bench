# FVK Spec: clear_denoms Dense Canonicalization

Status: constructed, not machine-checked.

## Scope

This audit covers the V1 change in `repo/sympy/polys/densetools.py`:

- `dup_clear_denoms(f, K0, K1=None, convert=False)`
- `dmp_clear_denoms(f, u, K0, K1=None, convert=False)`

It also covers the observable wrapper path:

`Poly.clear_denoms()` -> `DMP.clear_denoms()` -> `dmp_clear_denoms()` / `dup_clear_denoms()` -> `DMP.per()`.

## Intent-Only Contract

For every valid dense polynomial representation over a domain supporting
`denom`, `lcm`, and multiplication:

1. `clear_denoms` returns a denominator multiplier `common` equal to the least
   common multiple of all ground-coefficient denominators.
2. The returned dense representation denotes `common * f`, with optional domain
   conversion when `convert=True`.
3. The returned dense representation is canonical with respect to leading zero
   terms. In the univariate case, zero is `[]`. In the recursive multivariate
   case, zero is `dmp_zero(u)`, and zero coefficient polynomials are recursively
   stripped before outer leading-zero stripping.
4. If denominator clearing simplifies an expression-domain leading coefficient
   to exact zero, the returned polynomial must behave as zero through the dense
   representation, not merely print as zero through expression conversion.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| I1 | prompt/issue | "Result from clear_denoms() prints like zero poly but behaves wierdly (due to unstripped DMP)" | The bug is representation-level non-canonical zero after `clear_denoms`. | Encoded in O3/O4. |
| I2 | prompt/issue | `bad_poly.is_zero` is `False` while `bad_poly.as_expr().is_zero` is `True` | A result denoting zero must have the canonical zero dense representation used by `is_zero`. | Encoded in O3/O6. |
| I3 | prompt/issue | `bad_poly.terms_gcd()` raises `IndexError`; `Poly(0, x).terms_gcd()` succeeds | Downstream dense-polynomial methods may assume canonical zero; `clear_denoms` must not produce a non-canonical zero. | Encoded in O3/O6. |
| I4 | prompt/issue | `bad_poly.rep` is `DMP([EX(0)], EX, None)` but should be `DMP([], EX, None)` | For a univariate zero result, `[EX(0)]` must be stripped to `[]`. | Encoded in O3. |
| I5 | source/docstring | `dup_clear_denoms` and `dmp_clear_denoms` docstrings: "Clear denominators, i.e. transform K_0 to K_1." | Preserve denominator-clearing algebraic meaning and optional conversion. | Encoded in O1/O2/O5. |
| I6 | source/invariant | `DMP.per()` wraps a list directly when level is known; `dmp_validate()` is not called on that path. | Dense helpers must return canonical dense lists before wrapper construction. | Encoded in O6. |

Quoted pre-fix displays in the issue showing `bad_poly.is_zero == False`,
`bad_poly.rep == DMP([EX(0)], EX, None)`, and the traceback are SUSPECT legacy
behavior. They identify the defect and are not preserved as expected behavior.

## Formal Obligations

| Obligation | Statement | Provenance |
|---|---|---|
| O1 | `common` is the recursive `lcm` of all ground-coefficient denominators. | I5 |
| O2 | Before optional conversion, the returned polynomial denotes `common * f`. | I5 |
| O3 | `dup_clear_denoms` returns `dup_strip(common * f)`, so a leading coefficient simplified to zero is removed. | I1-I4 |
| O4 | `dmp_clear_denoms` returns `_rec_strip(common * f, u)`, so inner zero coefficient polynomials are stripped before outer leading-zero stripping. | I1-I4 generalized to recursive dense polynomials |
| O5 | `convert=True` preserves the algebraic result and changes only the coefficient domain; canonicalization happens before conversion and conversion retains or performs stripping. | I5 |
| O6 | `Poly.clear_denoms()` receives a canonical `DMP` representation from the dense helper and therefore zero results are observable as `Poly.is_zero == True`. | I2/I4/I6 |
| O7 | No public signature, return tuple shape, or call protocol changes. | Compatibility audit |

## Mini-K Artifacts

The constructed, not machine-checked formal core is in:

- `fvk/mini-dense-polys.k`
- `fvk/clear-denoms-spec.k`

Exact commands recorded for later machine checking:

```sh
kompile fvk/mini-dense-polys.k --backend haskell
kast --backend haskell fvk/clear-denoms-spec.k
kprove fvk/clear-denoms-spec.k
```

These commands were not run in this benchmark session.
