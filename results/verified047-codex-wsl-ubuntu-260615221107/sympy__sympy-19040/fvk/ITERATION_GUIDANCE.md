# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands unchanged.

The FVK audit found the original root cause and confirmed that V1 addresses it:
lower-variable content is split out before square-free preprocessing and is
recursively factored/lifted into the final factor list. No additional
source-code change is justified by the current public intent and proof
obligations.

## Why No V2 Code Edit Was Applied

- `FINDINGS.md::F1` identifies the bug as loss of leading-variable content under
  `dmp_sqf_part`.
- `FINDINGS.md::F2` and `PROOF_OBLIGATIONS.md::PO3-PO5` show that V1 preserves
  that content.
- `FINDINGS.md::F3` and `PROOF_OBLIGATIONS.md::PO6-PO8` show that primitive
  factors and multiplicities still flow through the existing norm/trial-division
  path.
- `FINDINGS.md::F4` and `PROOF_OBLIGATIONS.md::PO11` show no compatibility
  problem from the body-only change.

## Next Code-Generation Prompt, If Another Iteration Is Needed

Keep V1's content split. Do not move the fix into `dmp_sqf_part` unless public
intent changes, because `dmp_sqf_part` has broader leading-variable semantics.
If a later proof or test reveals a regression, inspect the helper contracts
first: recursive `dmp_factor_list` coefficient handling, lifting `[g]`, and
trial division against the original monic `F`.

## Tests To Add In A Normal Development Setting

Do not edit tests in this benchmark task. In normal development, add focused
tests for:

1. The public issue example: `(x - 1)*(y - 1)` with `extension=[I]`.
2. A polynomial independent of the leading generator but factored with multiple
   generators and an algebraic extension.
3. Repeated lower-variable content combined with repeated primitive factors.

## Machine-Check Commands For Later

```sh
kompile fvk/mini-sympy-factor.k --backend haskell
kast --backend haskell fvk/dmp-ext-factor-spec.k
kprove fvk/dmp-ext-factor-spec.k
```

These commands were intentionally not executed in this session.

