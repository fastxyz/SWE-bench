# Proof

Status: constructed, not machine-checked.

No Python, tests, `kompile`, or `kprove` commands were executed in this session.
The commands below are recorded for reproduction only.

## Claims

The proof target is `repo/sympy/polys/polytools.py` V1:

- `_combine_factors(factors)` groups by `(factor.gens, exp)` and multiplies
  factors in each group.
- `_generic_factor_list()` invokes `_combine_factors()` only when
  `method == 'sqf'`.

The K model in `mini-sqf-combine.k` abstracts a factor as `fac(Poly, Int)`.
`gens(Poly)` is the generator tuple key, and `pmul(P1, P2)` records product
construction without expanding the product.

## Constructed Proof Sketch

Claim 1 symbolically evaluates `combineFactors` on the reported list shape.
`combineAcc` consumes the list left to right. The first two keys are new and are
appended to the accumulator. The third key `(1, 3)` is new and is appended. The
fourth key is also `(1, 3)`, so `appendOrMul` takes the same-key branch and
rewrites the existing entry to `fac(pprod(atom(1, 31), atom(1, 32)), 3)`.

Claim 2 follows by the same path with exponent `1`, showing the helper is not
specific to exponent `3`.

Claim 3 evaluates two factors with equal exponents but different generator keys.
`sameKey` is false, so `appendOrMul` traverses past the existing entry and
appends a second entry. This frames mixed-generator behavior.

Claim 4 evaluates `normalizeFactors(factor, FS)`. The `factor` rule returns `FS`
directly, proving ordinary `factor_list()` is not routed through combination.

Claim 5 evaluates `normalizeFactors(sqf, FS)`. The `sqf` rule rewrites to
`combineFactors(FS)`, and then the same combine proof applies.

Claim 6 is the guarded progress point for the Python loop model: one head factor
is consumed before the recursive continuation is reused.

## Residual Obligation

`sqf-combine-obligations.k` records `[ESCALATION BOUNDARY]`
`OBL-GENERAL-GROUPING` and `OBL-GENERAL-PRODUCT`: for every finite factor list,
the output has exactly one entry per key in first-occurrence order and the
corresponding product of all input factors for that key. This requires a richer
list-induction and algebraic product theory. It is not hidden with `[trusted]`.

The residual does not force a source edit because the bounded claims cover the
reported counterexample shape and the regression-sensitive frames, and the audit
did not produce a concrete failing input for V1.

## Exact Commands To Machine Check Later

```sh
kompile fvk/mini-sqf-combine.k \
  --backend haskell \
  --main-module MINI-SQF-COMBINE \
  --syntax-module MINI-SQF-COMBINE-SYNTAX \
  -o fvk/mini-sqf-combine-kompiled

kast fvk/sqf-combine-spec.k \
  --definition fvk/mini-sqf-combine-kompiled \
  --module SQF-COMBINE-SPEC \
  --sort Claim

kprove fvk/sqf-combine-spec.k \
  --definition fvk/mini-sqf-combine-kompiled \
  --spec-module SQF-COMBINE-SPEC
```

Expected machine-check result if the fragment parses and all claims discharge:
`#Top`. This has not been run.

The open obligation file can be parsed/proved separately after adding the
required induction/product theory:

```sh
kprove fvk/sqf-combine-obligations.k \
  --definition fvk/mini-sqf-combine-kompiled \
  --spec-module SQF-COMBINE-OBLIGATIONS
```

## Test Recommendation

No tests were edited. Existing tests around constants, mixed-generator symbolic
products, `factor_list()`, and rational/fraction output should be kept until the
K claims are machine-checked and the escalation-bounded arbitrary-list theorem
is discharged or explicitly scoped.
