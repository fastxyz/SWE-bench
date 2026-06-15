# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Artifacts

- Semantics fragment: `fvk/mini-python.k`
- Claim file: `fvk/minversion-spec.k`
- Human spec: `fvk/SPEC.md`
- Findings: `fvk/FINDINGS.md`
- Obligations: `fvk/PROOF_OBLIGATIONS.md`

## Claims Proved Constructively

### C1 - Reported Case

For installed version `1.14.3`, required version `1.14dev`, and
`inclusive=True`, `minversion` returns `True`.

Proof sketch:

1. `_version_to_looseversion("1.14.3")` matches numeric prefix `1.14.3`.
2. `_version_to_looseversion("1.14dev")` matches numeric prefix `1.14`.
3. Both `LooseVersion` operands contain only integer release components.
4. Numeric-list comparison gives `[1, 14, 3] >= [1, 14]`.
5. The inclusive branch returns that boolean, so the result is `True`.

Linked obligations: PO1, PO2, PO3, PO4.

### C2 - General Inclusive Claim

For any in-domain installed version `H` and required version `R`,
`minversion(module_with_version(H), R, inclusive=True)` returns
`loose_ge(numeric_prefix(H), numeric_prefix(R))`.

Proof sketch:

1. The module branch retrieves `have_version` and reaches the comparison block.
2. PO2 rewrites both versions to `LooseVersion` objects over numeric prefixes.
3. The inclusive branch applies `>=`.
4. PO3 ensures the comparison cannot enter the reported mixed-type failure.

Linked obligations: PO1 through PO4.

### C3 - General Exclusive Claim

For any in-domain installed version `H` and required version `R`,
`minversion(module_with_version(H), R, inclusive=False)` returns
`loose_gt(numeric_prefix(H), numeric_prefix(R))`.

Proof sketch mirrors C2, using the `else` branch and strict `>` comparison.

Linked obligations: PO1 through PO4.

### C4 - Missing Import Claim

For a module name that cannot be resolved, `minversion` returns `False` before
version comparison.

Proof sketch: the source catches `ImportError` from `resolve_name(module_name)`
and returns `False`; V1 did not modify that branch.

Linked obligations: PO5.

### C5 - Invalid Module Argument Claim

For an argument that is neither a module object nor a string import name,
`minversion` raises `ValueError`.

Proof sketch: the source reaches the existing `else` branch before version
lookup or normalization; V1 did not modify that branch.

Linked obligations: PO5.

## Machine Check Commands

These commands are emitted for later machine checking only. They were not run.

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/minversion-spec.k
kprove fvk/minversion-spec.k
```

Expected result after a real machine check: `#Top` for the claims in
`fvk/minversion-spec.k`, assuming the mini semantics and abstraction match the
source-level behavior described in `fvk/SPEC.md`.

## Residual Risk

- This is a partial-correctness proof; termination is not separately proved.
- The mini semantics abstracts Python import, attribute lookup, regex matching,
  and `LooseVersion` construction to the comparison-relevant behavior.
- The result is constructed, not machine-checked.
- Full PEP 440 parsing is intentionally outside the issue-derived proof scope.

## Test Guidance

No tests were run or modified. If the `.k` claims are later machine-checked, an
in-domain unit test asserting the reported case would be subsumed by C1.
Existing integration and compatibility tests should remain because this proof
models only the `minversion` comparison behavior.

