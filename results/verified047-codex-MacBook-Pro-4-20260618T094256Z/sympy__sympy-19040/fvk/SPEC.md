# Developer Spec

Status: constructed, not machine-checked. General proof obligations are
constructed (escalation-bounded).

## Target

`repo/sympy/polys/factortools.py:dmp_ext_factor(f, u, K)` for `u > 0` and
algebraic field `K`.

## Required behavior

Given a normalized multivariate polynomial whose full factorization can be
viewed as:

```text
LC * CC * product(CONT factors) * product(PRIM factors)
```

where `CONT` is the content with respect to the main variable and `PRIM` is the
main-variable primitive part, `dmp_ext_factor` must return:

```text
LC * CC, [(each CONT factor, multiplicity), (each PRIM factor, multiplicity)]
```

up to SymPy's existing factor ordering.

## V1 algorithm under audit

V1 preserves the original monic polynomial `F`, then:

1. Splits `F` into `cont, f = dmp_primitive(F, u, K)`.
2. Recursively factors `cont` in the lower-level ring with
   `dmp_factor_list(cont, u - 1, K)`.
3. Multiplies the returned content coefficient into `lc`.
4. Lifts lower-level content factors with `dmp_include(factor, [0], u - 1, K)`.
5. If the primitive part is constant, returns `dmp_trial_division(F, factors)`.
6. Otherwise applies the existing `dmp_sqf_part` / `dmp_sqf_norm` /
   `dmp_factor_list_include` / gcd-compose path to the primitive part and
   appends those candidates.
7. Calls `dmp_trial_division(F, factors, u, K)` once over the preserved original
   monic polynomial.

## Formal abstraction

The mini K model abstracts a polynomial as:

```text
poly(LC, CC, CONT, PRIM)
```

`CONT` and `PRIM` are factor bags with multiplicity. This abstraction preserves
the audited property: it distinguishes the failing legacy behavior
`{XMINUS1}` from the corrected behavior `{YMINUS1, XMINUS1}`.

## Claims

- `dmp-ext-factor-spec.k` issue claim: V1 factors
  `poly(1, 1, {YMINUS1}, {XMINUS1})` to both factors.
- `dmp-ext-factor-spec.k` legacy diagnostic: pre-V1 factors the same abstract
  polynomial to only `{XMINUS1}`.
- `dmp-ext-factor-spec.k` no-content frame: when `CONT` is empty and `CC = 1`,
  V1 returns the primitive factors with the original coefficient.
- `dmp-ext-factor-spec.k` content-only frame: when `PRIM` is empty, V1 returns
  the content factors and combines `LC * CC`.
- `dmp-ext-factor-spec.k` coefficient claim: V1 combines `LC` and the content
  factorization coefficient.
- `dmp-ext-factor-spec.k` general claim: for well-formed splits, V1 returns the
  union of content and primitive factors with coefficient `LC * CC`.

## Public evidence mirror

The public evidence ledger is `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries are
mirrored as `SPEC-PROVENANCE` comments above the K claims.
