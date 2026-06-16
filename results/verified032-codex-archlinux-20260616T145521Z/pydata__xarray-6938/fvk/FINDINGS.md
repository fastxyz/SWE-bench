# FVK Findings

Status: constructed, not machine-checked.

## F-001: Pre-V1 alias mutation in promoted `IndexVariable` branch

- Classification: code bug, resolved by V1.
- Input shape: a dataset whose replacement variable is already represented as an `IndexVariable` object but is stored as a data variable with old dimensions, matching the issue's `ds2["lev"]` case.
- Observed before V1: `Dataset.swap_dims(z="lev")` obtains `var = v.to_index_variable()`. Because `v` is an `IndexVariable`, this returns `v` itself. The following `var.dims = ("lev",)` mutates the original dataset's `lev` variable dimensions.
- Expected: the returned dataset may contain `lev` with dimensions `("lev",)`, but the input dataset's `lev` variable must keep dimensions `("z",)`.
- Evidence: E-001, E-002, E-003, E-007.
- Proof obligations: PO-001, PO-002.
- Status: resolved by `v.to_index_variable().copy(deep=False)` before assigning `var.dims`.

## F-002: `to_index_variable()` cannot be treated as an ownership transfer

- Classification: proof-derived implementation finding, resolved by V1.
- Input shape: any branch that plans to mutate the result of `to_index_variable()`.
- Observed before V1: the method sometimes returns a fresh object (`Variable.to_index_variable`) and sometimes returns `self` (`IndexVariable.to_index_variable`).
- Expected: code that will mutate `.dims` must first own a distinct variable object regardless of which implementation is called.
- Evidence: E-007, E-009.
- Proof obligations: PO-002, PO-006.
- Status: resolved by copying the converted index variable before `.dims` assignment.

## F-003: Potential extra shallow copy is acceptable and not a required V2 change

- Classification: non-bug audit note.
- Input shape: ordinary `Variable` replacement variables, where `Variable.to_index_variable()` already returns a fresh object.
- Observed in V1: `.copy(deep=False)` also copies that freshly created `IndexVariable`.
- Expected: public behavior requires no input mutation and correct returned dimensions; it does not require preserving internal object identity or avoiding this shallow metadata copy.
- Evidence: E-004, E-005, E-009.
- Proof obligations: PO-002, PO-006.
- Status: no production-code change. A narrower `if var is v: var = var.copy(deep=False)` would be a micro-optimization, not a correctness requirement.

## F-004: Formal proof is constructed, not machine-checked

- Classification: proof capability limitation.
- Input shape: all claims in this FVK pass.
- Observed: this workspace forbids running K tooling, tests, or Python code.
- Expected: artifacts must include the commands and reasoning, while clearly labeling the proof as constructed, not machine-checked.
- Evidence: FVK method docs and task constraints.
- Proof obligations: PO-007.
- Status: no code change. Do not delete tests or claim machine-checked status until `kprove` is run externally.

## Unresolved findings

None that require a source change under the public issue intent.
