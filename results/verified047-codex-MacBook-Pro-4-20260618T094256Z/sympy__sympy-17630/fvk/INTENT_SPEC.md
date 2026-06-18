# Intent Spec

Status: constructed, not machine-checked.

Target under audit: `BlockMatrix._blockmul` in
`repo/sympy/matrices/expressions/blockmatrix.py`.

## Intent-Derived Obligations

1. A `BlockMatrix` is composed of matrix blocks, so every stored block entry must
   expose matrix shape information such as `.rows` and `.cols`.

2. If both operands are `BlockMatrix` instances and the left column block sizes
   equal the right row block sizes, `_blockmul` should return a `BlockMatrix`
   representing the block product.

3. The result of compatible block multiplication has row block sizes inherited
   from the left operand and column block sizes inherited from the right operand.

4. When a block product entry is exactly scalar zero because all contributing
   block terms are zero, that result entry must be a shaped `ZeroMatrix` with
   the corresponding result block dimensions, not scalar `0`.

5. Nonzero matrix-valued block product entries must be preserved. The fix must
   not alter algebraic block multiplication results that are already matrix
   expressions.

6. Repeated block multiplication must not fail because a prior product stored
   scalar `0` in a block position. In particular, the issue example
   `b._blockmul(b)._blockmul(b)` and the `block_collapse(b*b*b)` path must not
   encounter an entry without `.rows` or `.cols`.

7. Existing fallback behavior is a frame condition: if the right operand is not
   a `BlockMatrix`, or if two `BlockMatrix` operands have incompatible block
   sizes, `_blockmul` should continue returning the ordinary multiplication
   expression `self * other`.

## Out Of Scope

This audit does not prove termination or performance. There are no loops or
recursive calls in the changed code path.

The K artifacts model the relevant block-entry type and shape invariants. They
do not model full Python object identity, all SymPy simplification rules, or the
entire explicit matrix multiplication implementation.

The raw-entry domain is limited to the behavior implicated by the public issue:
a block-grid product entry is either already matrix-shaped or is the exact
scalar zero artifact produced when all contributing matrix terms vanish.
