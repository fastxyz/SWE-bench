# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `sympy__sympy-15017`: rank-0 scalar arrays should have length one. The observable under proof is `NDimArray.__len__`, which returns the `_loop_size` cached by dense and sparse constructors.

## Public intent ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical entries are:

- E1-E4: the issue states that rank-0 array length `0` is the bug and that the correct scalar size is `1`.
- E5: the `__len__` docstring says length is the number of elements in the array.
- E6: nonempty shapes keep product-of-dimensions length.
- E7: the public test asserting `len(rank_zero_array) == 0` is SUSPECT because it encodes the reported bug.
- E8-E9: `__len__` returns `_loop_size`, and all dense/sparse mutable/immutable constructors compute that cached value independently.

## Contract

For well-formed arrays constructed through the dense or sparse constructors:

1. If `shape == ()`, the array is rank zero and its element count is `1`.
2. If `shape` is nonempty, the element count is the product of its dimensions.
3. `len(array)` returns the cached element count.
4. The same contract holds for dense and sparse arrays, and for mutable and immutable variants.

The product over an empty shape is defined as `1`; this is the product identity and matches the scalar-array size intent.

## Formal core

- `fvk/mini-sympy-array.k` defines the minimal semantics fragment: constructors cache `product(shape)`, and `len(array)` returns that cached size.
- `fvk/array-size-spec.k` states K claims C1-C5 for scalar rank-0 length and representative nonempty-shape preservation.

Exact commands to machine-check later:

```sh
cd fvk
kompile mini-sympy-array.k --backend haskell
kast --backend haskell array-size-spec.k
kprove array-size-spec.k
```

Expected result after machine checking: `kprove` returns `#Top` for all claims.

## Source mapping

- `repo/sympy/tensor/array/dense_ndim_array.py`: immutable and mutable dense constructors set `_loop_size`.
- `repo/sympy/tensor/array/sparse_ndim_array.py`: immutable and mutable sparse constructors set `_loop_size`.
- `repo/sympy/tensor/array/ndim_array.py`: `NDimArray.__len__` returns `_loop_size`.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each K claim. `fvk/SPEC_AUDIT.md` compares those paraphrases to the intent spec and marks the scalar length claims as pass.
