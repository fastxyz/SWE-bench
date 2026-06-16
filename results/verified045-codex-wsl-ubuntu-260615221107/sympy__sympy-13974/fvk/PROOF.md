# FVK Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## What Is Proved

For the explicit tensor-product simplification and expansion paths, V1 proves:

- `tensor_product_simp(TensorProduct(a, b, ...)**n)` returns
  `TensorProduct(a**n, b**n, ...)`.
- If a power's base first simplifies to a `TensorProduct`, the exponent is
  applied to each resulting tensor-product argument.
- `expand(tensorproduct=True)` on a `Pow` delegates to the same component-wise
  power rule exactly when the base supports that tensor-product power hook.
- Non-target powers remain unchanged by the tensor-product expansion hook.

## Symbolic Execution Proof

PO-001 follows immediately from the implementation of
`TensorProduct._eval_expand_tensorproduct_pow`:

```python
return TensorProduct(*[arg**exp for arg in self.args])
```

The right side is exactly `TensorProduct(a**n, b**n, ...)` for the receiver's
argument list.

PO-002 symbolically executes `tensor_product_simp_Pow` on `Pow(B, E)`:

1. Bind `base = tensor_product_simp(B)`.
2. Case split on `isinstance(base, TensorProduct)`.
3. In the true branch, invoke PO-001 with `base.args` and `E`.
4. Therefore the result is `TensorProduct(*[arg**E for arg in base.args])`.

PO-003 is the false branch of the same case split. Since `base` is not a
`TensorProduct`, V1 returns `base**E`, which is the same recursive behavior the
old `Pow` handling had after simplifying the base.

PO-004 symbolically executes `Pow._eval_expand_tensorproduct`:

1. Case split on whether `self.base` has `_eval_expand_tensorproduct_pow`.
2. In the true branch, call that hook with `self.exp`; for `TensorProduct` this
   is PO-001.
3. In the false branch, return `self`, preserving non-target powers.

PO-005 instantiates PO-002 with `base = TensorProduct(1, 1)` and `exp = 2`.
The component powers are `1**2` and `1**2`, both simplifying to `1`, so the
result is `TensorProduct(1, 1)`.

PO-006 instantiates PO-002 with `base = TensorProduct(1, Pauli(3))` and
`exp = 2`. The component powers are `1**2` and `Pauli(3)**2`. The Pauli class
already defines positive integer powers modulo 2, so `Pauli(3)**2` simplifies
to `1`; the result is `TensorProduct(1, 1)`.

## Adequacy

The proof obligations match the public intent:

- The issue explicitly requires `tensor_product_simp` and
  `expand(tensorproduct=True)` to evaluate tensor-product powers.
- The public hint gives the exact component-wise rewrite used in PO-001 and
  PO-002.
- The proof does not rely on pre-fix displays as expected behavior; those
  displays are treated as symptoms.
- The proof does not require automatic construction-path evaluation because the
  public hint targets `tensor_product_simp_Pow`.

## Residual Risk

This proof is partial correctness over a small symbolic rewrite model, not full
SymPy or full Python semantics. It assumes ordinary SymPy constructors perform
their existing local simplifications, such as `1**2 -> 1` and
`Pauli(3)**2 -> 1`.

The proof is constructed, not machine-checked. The task forbids running:

```sh
kompile fvk/mini-sympy-tensorproduct.k --backend haskell
kast --backend haskell fvk/tensorproduct-power-spec.k
kprove fvk/tensorproduct-power-spec.k
```

Expected machine-check result after materializing the embedded mini-semantics
and claims from `PROOF_OBLIGATIONS.md`: `#Top`.

## Test Recommendation

Do not remove or edit tests. If this proof were machine-checked, focused tests
for the two public examples would be subsumed by PO-005 and PO-006, but this
benchmark forbids test edits and the proof has not been machine-checked.
