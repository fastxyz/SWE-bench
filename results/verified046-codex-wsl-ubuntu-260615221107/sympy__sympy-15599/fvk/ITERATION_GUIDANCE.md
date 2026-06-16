# FVK Iteration Guidance

Status: V1 stands unchanged.

## Source Decision

Do not edit `repo/sympy/core/mod.py` further for this issue. Findings F1-F3
and obligations PO1-PO5 support the V1 guard and arithmetic transformation:
it fixes `Mod(3*i, 2)` while avoiding the denominator, float, symbolic-divisor,
and non-integer-tail cases highlighted by public evidence.

## Suggested Tests for a Future Test-Writing Pass

Do not modify tests in this benchmark task. For a normal development pass,
add or keep tests for:

- `Mod(3*i, 2) == Mod(i, 2)` with `i` integer;
- a broader integer coefficient point such as `Mod(5*i, 3) == Mod(2*i, 3)`;
- a negative coefficient point such as `Mod(-3*i, 2) == Mod(i, 2)`;
- `Mod(e/2, 2).subs(e, 6) == Mod(3, 2)` with `e` even;
- non-integer symbol frame behavior such as `Mod(3*x, 2)` remaining outside
  the integer-tail reduction when `x` is not known integer;
- float and symbolic-divisor examples already represented in public tests.

## Proof Follow-Up

A future environment with K installed can run:

```sh
kompile fvk/mini-sympy-mod.k --backend haskell
kast --backend haskell fvk/sympy-mod-spec.k
kprove fvk/sympy-mod-spec.k
```

Until those commands return `#Top`, do not delete tests based on the proof.

## Open Scope

The mini-K proof does not certify all of `Mod.eval`. If future work targets
other branches such as existing product denesting, additive simplification,
gcd extraction, or float normalization, write separate intent ledgers and proof
obligations for those branches before changing code.
