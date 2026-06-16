# FVK Specification: sympy__sympy-17630

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Scope

Target source unit: `repo/sympy/matrices/expressions/blockmatrix.py`,
`BlockMatrix._blockmul`.

The audited behavior is the aligned `BlockMatrix * BlockMatrix` branch. The
fallback `return self * other` branch is a frame condition: this task provides no
public intent to change non-block or unaligned multiplication.

There are no loops in the target function, so the FVK proof has function-level
reachability obligations and no loop circularities.

## Intent-Only Requirements

- `I1`: Repeated block multiplication of a `BlockMatrix` containing
  `ZeroMatrix` blocks must not raise `AttributeError` from scalar zero blocks.
- `I2`: A `BlockMatrix` is comprised of matrix blocks. Returned blocks must be
  matrix-shaped objects with usable `.rows` and `.cols`.
- `I3`: Zero result blocks must carry the row and column dimensions of their
  position in the product, namely the left block row size and right block column
  size.
- `I4`: Public API compatibility is preserved: `_blockmul(self, other)` keeps the
  same signature and fallback behavior outside the aligned block-matrix case.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`block_collapse(b * b * b)` throws `AttributeError: 'Zero' object has no attribute 'cols'`" | Repeated multiplication must not create scalar block entries that later size queries inspect. | Encoded by PO-3 and PO-5. |
| E2 | `benchmark/PROBLEM.md` | "`type(b._blockmul(b).blocks[0, 1])` is `sympy.core.numbers.Zero`" | The first multiplication must preserve shaped zero blocks, not scalar `Zero`. | Encoded by PO-3. |
| E3 | `BlockMatrix` docstring | "A `BlockMatrix` is a Matrix comprised of other matrices." | Returned `BlockMatrix.blocks` entries are matrices, including zero entries. | Encoded by PO-4 and PO-5. |
| E4 | `ZeroMatrix` implementation | `ZeroMatrix.shape` is `(rows, cols)` and `GenericZeroMatrix` has no specified shape. | A zero block in a concrete `BlockMatrix` must be `ZeroMatrix(row, col)`, not scalar zero or a shape-less zero placeholder. | Encoded by PO-3. |
| E5 | current source | `_blockmul` has an explicit non-aligned fallback `return self * other`. | Preserve fallback behavior and public dispatch shape. | Encoded by PO-7. |

## Contract

Preconditions for the verified branch:

- `self` and `other` are valid `BlockMatrix` instances.
- `self.colblocksizes == other.rowblocksizes`.
- Every input block has a usable matrix shape.

Postconditions for the verified branch:

- The result is a `BlockMatrix`.
- The result block grid shape is
  `(self.blockshape[0], other.blockshape[1])`.
- The result row block sizes are `self.rowblocksizes`.
- The result column block sizes are `other.colblocksizes`.
- For each result block position `(i, j)`, let
  `raw = (self.blocks * other.blocks)[i, j]`.
  - If `raw` is scalar zero or a matrix-zero placeholder, the stored block is
    `ZeroMatrix(self.rowblocksizes[i], other.colblocksizes[j])`.
  - Otherwise, the stored block is `raw`, and the matrix-expression shape rules
    require `raw.shape == (self.rowblocksizes[i], other.colblocksizes[j])`.
- Consequently, later uses of `rowblocksizes`, `colblocksizes`, `shape`, and
  repeated `_blockmul` do not encounter scalar or shape-less zero block entries.

Frame conditions:

- `_blockmul` signature is unchanged.
- If `other` is not a `BlockMatrix`, or block sizes do not align, behavior stays
  `return self * other`.
- No test files or unrelated matrix-expression arithmetic were changed.

## Formal Claim English

Claim `BM-MUL-NORMALIZES-ZEROS`: for all valid aligned block matrices `A` and
`B`, `_blockmul(A, B)` returns a valid `BlockMatrix` whose block dimensions are
the standard block-product dimensions. Every zero-like raw result block is
replaced by the uniquely shaped `ZeroMatrix` for that output position.

Claim `BM-MUL-PRESERVES-NONZERO-BLOCKS`: for all valid aligned block matrices
`A` and `B`, if a raw product entry is a non-zero matrix expression, `_blockmul`
stores that expression unchanged.

Claim `BM-MUL-FALLBACK-FRAME`: if the aligned block-matrix precondition is not
met, `_blockmul` follows the pre-existing fallback `self * other`.

## Adequacy Audit

| Claim | Intent coverage | Result |
| --- | --- | --- |
| `BM-MUL-NORMALIZES-ZEROS` | Matches E1, E2, E3, and E4. It proves the bug symptom is removed at the producer of invalid zero blocks. | Pass |
| `BM-MUL-PRESERVES-NONZERO-BLOCKS` | Matches the frame condition that block multiplication should still compute the same non-zero block expressions. | Pass |
| `BM-MUL-FALLBACK-FRAME` | Matches E5 and avoids broadening the patch beyond the issue. | Pass |

No claim depends on hidden tests, evaluator results, or upstream patches.

## Public Compatibility Audit

- Changed symbol: `BlockMatrix._blockmul`.
- Signature change: none.
- Return type for aligned block-matrix multiplication: still `BlockMatrix`.
- Return behavior for non-aligned or non-`BlockMatrix` input: unchanged.
- Public callsites inspected statically: `bc_matmul` invokes `_blockmul` and
  benefits from the stronger returned-block invariant.
- Subclass/override risk: `BlockDiagMatrix._blockmul` delegates to
  `BlockMatrix._blockmul` only in its fallback path; the strengthened zero
  normalization is compatible with that delegation.

## K Core

The constructed K-style model is written as an abstract mini semantics in:

- `fvk/mini-blockmatrix.k`
- `fvk/blockmatrix-spec.k`

These files model the property-bearing axis only: block row sizes, block column
sizes, raw product entries, and zero normalization. They intentionally do not
model full Python or full SymPy internals.
