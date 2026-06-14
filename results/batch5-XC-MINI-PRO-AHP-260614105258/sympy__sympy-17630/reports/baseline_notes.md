# Baseline notes — sympy__sympy-17630

## Issue

Block-multiplying a `BlockMatrix` that contains `ZeroMatrix` blocks works once but
throws on the second multiplication:

```python
a = MatrixSymbol("a", 2, 2)
z = ZeroMatrix(2, 2)
b = BlockMatrix([[a, z], [z, z]])

block_collapse(b * b)        # OK -> Matrix([[a**2, 0], [0, 0]])
block_collapse(b * b * b)    # AttributeError: 'Zero' object has no attribute 'cols'
```

The reporter correctly observed that the off-diagonal blocks of `b._blockmul(b)`
are `sympy.core.numbers.Zero` (the scalar `S.Zero`) rather than `ZeroMatrix`.

## Root cause

`BlockMatrix._blockmul` computes `self.blocks * other.blocks`, where `blocks` is an
`ImmutableDenseMatrix` whose entries are matrix expressions. The dense
multiplication routine (`DenseMatrix._eval_matrix_mul`, `sympy/matrices/dense.py:174`)
forms each result entry with the **core** `Add`:

```python
new_mat[i] = Add(*vec)   # vec is a generator of products of the block entries
```

For an off-diagonal entry of `b.blocks * b.blocks` the products all reduce to
`ZeroMatrix(2, 2)` (a `MatMul` containing a zero block evaluates to `ZeroMatrix`),
so the call is effectively

```python
Add(ZeroMatrix(2, 2), ZeroMatrix(2, 2))
```

`Add` does not know about matrices directly; matrix results are produced by the
constructor post-processor registered for `MatrixExpr`
(`get_postprocessor` in `sympy/matrices/expressions/matexpr.py`). With both
arguments being matrices and no scalar terms, the post-processor reached its final
line:

```python
return mat_class(cls._from_args(nonmatrices), *matrices).doit(deep=False)
```

Here `nonmatrices == []`, and `Add._from_args([])` returns the scalar additive
identity `S.Zero`. So the post-processor actually built `MatAdd(S.Zero, Z, Z)`.
During `MatAdd` canonicalization the `rm_id` rule
(`rm_id(lambda x: x == 0 or isinstance(x, ZeroMatrix))`) sees that **every** arg is
an identity and, per its "if only identities then keep one" behaviour
(`sympy/strategies/rl.py:36-37`), keeps `args[0]`, which is the spurious scalar
`S.Zero`. `unpack` then reduces `MatAdd(0)` to the scalar `S.Zero`.

Net effect: `Add(ZeroMatrix, ZeroMatrix)` collapses to scalar `S.Zero` instead of
`ZeroMatrix`. That scalar lands in the product matrix, so `b._blockmul(b)` returns a
`BlockMatrix` whose blocks include `S.Zero`. The next `_blockmul` calls
`colblocksizes`/`rowblocksizes`, which do `block.cols` / `block.rows`, and
`S.Zero` has no `cols`/`rows` attribute → `AttributeError`.

(Block *addition* does not hit this: it uses the `+` operator, i.e.
`MatAdd(Z, Z).doit()` directly, which never injects the scalar `0` and correctly
yields `ZeroMatrix`. Only multiplication, via the core `Add(*vec)`, triggers it.)

## Fix

`sympy/matrices/expressions/matexpr.py`, `get_postprocessor(cls)._postprocessor`:

When the post-processor has only matrix arguments (`nonmatrices` is empty) and is
building a `MatAdd`, build it directly from the matrices instead of prepending the
scalar additive identity:

```python
if mat_class == MatAdd:
    return mat_class(*matrices).doit(deep=False)
return mat_class(cls._from_args(nonmatrices), *matrices).doit(deep=False)
```

With this, `Add(ZeroMatrix(2, 2), ZeroMatrix(2, 2))` becomes
`MatAdd(Z, Z).doit()` → `ZeroMatrix(2, 2)` (the all-identity `rm_id` branch now
keeps a `ZeroMatrix`, not a scalar). Block products therefore keep proper
`ZeroMatrix` blocks, and `block_collapse(b*b*b)` /
`b._blockmul(b)._blockmul(b)` work and return `Matrix([[a**3, 0], [0, 0]])`.

### Why this is the right place

The genuine defect is that summing zero matrices was yielding the scalar `0`; that
is wrong regardless of block matrices (adding two `n×m` zero matrices is an `n×m`
zero matrix). Fixing it at the source repairs every caller, including the dense
multiply path that block matrices rely on, rather than papering over the symptom.

### Why the change is safe / surgical

- The branch is only reached when `nonmatrices` is empty (the `nonmatrices`
  non-empty case for `Add` returns earlier, preserving the documented
  `Add(scalar, matrix)` capability) so no scalar term is ever dropped.
- The `MatMul` path is left byte-for-byte unchanged (`MatMul`'s scalar identity
  `S.One` is harmless and is the case that previously needed the
  `cls._from_args(nonmatrices)` prefix).
- For `MatAdd`, `MatAdd(*matrices).doit()` and the old
  `MatAdd(S.Zero, *matrices).doit()` produce identical results in every case
  except the all-zero one, because `rm_id` strips the scalar `0` early whenever at
  least one non-identity term is present. The only behavioural change is the
  intended one: all-zero sums now return `ZeroMatrix` instead of scalar `0`.

## Assumptions / alternatives considered and rejected

- **Make `colblocksizes`/`rowblocksizes` tolerate scalar `Zero`.** Rejected: it
  hides the real problem. A `BlockMatrix` whose blocks contain a scalar is
  malformed — `shape`, `_entry`, `_eval_transpose`, etc. all assume matrix blocks —
  so this would only move the crash elsewhere.

- **Post-process the product in `BlockMatrix._blockmul`** (rebuild scalar-`Zero`
  entries into correctly sized `ZeroMatrix` blocks). Rejected: more code, fixes
  only block-matrix multiplication, and leaves the underlying
  `Add(ZeroMatrix, ZeroMatrix) == 0` bug in place to bite other callers.

- **Change the `rm_id`/`MatAdd` canonicalization rules** so the kept identity is
  always a matrix. Rejected: `rm_id` is a generic strategy used widely; the cleaner
  and more localized fix is to not feed the scalar identity into `MatAdd` in the
  first place.

I assumed the intended semantics is that `Add`/`MatAdd` of `ZeroMatrix` terms is a
`ZeroMatrix` of the same shape (consistent with `MatAdd(Z, Z).doit()` already
returning `ZeroMatrix` and with `ZeroMatrix.is_ZeroMatrix`-based checks elsewhere).
