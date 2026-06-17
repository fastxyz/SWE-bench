# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source patch in `repo/sympy/combinatorics/homomorphisms.py` unchanged. The FVK audit found the original defect (`F1`) and showed that V1 discharges the relevant proof obligations (`PO1`, `PO2`, `PO4`) without introducing a public compatibility problem (`PO5`) or a non-permutation regression (`PO3`).

## Why No Further Source Change Is Justified

- Reintroducing `r[i] in gens` would re-create the public issue from `F1`.
- Mapping inverse presentation-generator objects directly would create the ambiguity described in `F2`.
- Removing the fallback `elif s**-1 in images` is unnecessary for the public path and would be an unrelated tightening of an internal helper.
- Changing `PermutationGroup.presentation()` or the presentation simplifier would exceed the localized issue and is not justified by a finding here.

## Recommended Tests For A Normal Development Environment

Do not add tests in this benchmark task. In a normal development branch, add focused tests for:

- identity homomorphism on `DihedralGroup(3)` using `homomorphism(D3, D3, D3.generators, D3.generators)`;
- a permutation-group relator containing a negative syllable;
- the existing invalid-map case from `test_check_homomorphism()` to ensure rejection still works;
- an `FpGroup` relator with a negative power to confirm non-permutation behavior remains intact.

## Residual Risk

The proof is constructed, not machine-checked (`F5`, `PO6`). It also relies on the existing positional relationship between `PermutationGroup.presentation().generators` and `domain.generators`; this was already required by the old implementation and is explicitly tracked in `PO1`.
