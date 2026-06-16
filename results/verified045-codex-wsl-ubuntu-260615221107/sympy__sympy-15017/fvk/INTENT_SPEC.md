# Intent Spec

Status: constructed from public/user-provided evidence only.

## Required behavior

1. A scalar `sympy.Array(3)` is a rank-0 array with shape `()`.
2. `len` on a rank-0 scalar array must return `1`, not `0`.
3. The returned length must be the number of elements in the array. For the issue example, `len(Array(3))` must match the one element produced by iteration.
4. The convention is consistent with the cited NumPy scalar-array size behavior: scalar arrays have size `1`.
5. Existing non-rank-0 arrays must keep their existing element count: the product of shape dimensions.

## Domain assumptions

- Shape dimensions are integer extents. For nonempty shapes, the intended element count is the product of dimensions.
- The audit target is well-formed arrays produced by the public constructors from scalar values or valid shape/data pairs. Malformed explicit shape/data combinations without a matching element count are not specified by the issue.
- This FVK pass proves partial correctness of the length calculation and constructor cached-size assignment. It does not prove termination of Python library code or unrelated array operations.
