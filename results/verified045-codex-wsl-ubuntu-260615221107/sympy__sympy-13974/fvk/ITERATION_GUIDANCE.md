# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Code Decision

V1 stands unchanged. The FVK audit found no unresolved code bug in the stated
intent domain.

Keep:

- `TensorProduct._eval_expand_tensorproduct_pow`
- `tensor_product_simp_Pow`
- the `Pow` dispatch in `tensor_product_simp`
- the gated `Pow._eval_expand_tensorproduct` hook

Do not add `TensorProduct._eval_power` in this iteration. The public issue
requires explicit simplification and expansion paths, and broad automatic
construction-path evaluation would be a larger public behavior change.

## Future Tests To Add In A Normal Development Setting

The benchmark forbids modifying tests, but a normal follow-up should add tests
covering:

- `tensor_product_simp(TensorProduct(1, 1)*TensorProduct(1, 1))`
- `(TensorProduct(1, 1)*TensorProduct(1, 1)).expand(tensorproduct=True)`
- `tensor_product_simp(TensorProduct(1, Pauli(3))*TensorProduct(1, Pauli(3)))`
- `(TensorProduct(1, Pauli(3))*TensorProduct(1, Pauli(3))).expand(tensorproduct=True)`
- a non-tensor `Pow` expanded with `tensorproduct=True`, to confirm it remains
  unchanged

## Machine-Check Follow-Up

The constructed proof should be materialized into K files and checked with:

```sh
kompile fvk/mini-sympy-tensorproduct.k --backend haskell
kast --backend haskell fvk/tensorproduct-power-spec.k
kprove fvk/tensorproduct-power-spec.k
```

Until `kprove` returns `#Top`, keep the proof labeled constructed, not
machine-checked, and do not remove tests based on it.

## If New Public Intent Appears

If a future issue or maintainer explicitly requires bare
`TensorProduct(...)**n` construction to evaluate immediately, then add a new
FVK obligation for construction-path behavior and reconsider a targeted
`TensorProduct._eval_power` implementation. That change is intentionally not
part of this iteration.
