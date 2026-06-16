# Baseline Notes

## Root cause

Rank-0 arrays use the empty shape tuple `()`. The dense and sparse array
constructors cached `_loop_size` with `0` whenever `shape` was empty:

```python
functools.reduce(lambda x,y: x*y, shape) if shape else 0
```

That made `NDimArray.__len__`, which returns `_loop_size`, report zero
elements for scalar arrays even though a rank-0 scalar array contains one
element.

## Files changed

- `repo/sympy/tensor/array/dense_ndim_array.py`: changed the `_loop_size`
  calculation for immutable and mutable dense arrays to use `1` as the
  product identity. This makes scalar dense arrays report one element while
  leaving non-empty shapes unchanged.
- `repo/sympy/tensor/array/sparse_ndim_array.py`: made the same `_loop_size`
  calculation change for immutable and mutable sparse arrays so rank-0 array
  sizing stays consistent across storage implementations.

## Assumptions and alternatives considered

- I treated the number of elements in a rank-0 array as the product of its
  dimensions, where the product over an empty shape is `1`.
- I changed the cached `_loop_size` rather than special-casing
  `NDimArray.__len__`, because `_loop_size` is the shared source of element
  count information and sparse iteration also depends on it.
- I did not modify tests or run code, in accordance with the task constraints.
- I considered changing only dense arrays because the issue example uses
  `Array(3)`, but rejected that because sparse arrays share the same
  `NDimArray.__len__` behavior and had the same root cause.
