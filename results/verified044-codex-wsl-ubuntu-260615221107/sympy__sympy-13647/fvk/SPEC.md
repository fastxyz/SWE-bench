# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change to
`repo/sympy/matrices/common.py::MatrixShaping._eval_col_insert` and the public
`MatrixShaping.col_insert` guards that supply its preconditions.

There are no loops or recursive calls in the changed code, so the proof
obligations are branch and arithmetic obligations rather than loop
circularities.

## Intent-only contract

Let:

- `A` be the original matrix with `R` rows and `C` columns;
- `B` be the inserted matrix with `R` rows and `K` columns;
- `P` be the normalized insertion position with `0 <= P <= C`;
- `M = A.col_insert(P, B)`.

The intended result has shape `R x (C + K)`. For every valid result entry
`(i, j)`:

```text
if j < P:
    M[i, j] = A[i, j]
elif P <= j < P + K:
    M[i, j] = B[i, j - P]
else:
    M[i, j] = A[i, j - K]
```

The right-hand case is the critical bug fix: it shifts the result column back
by the inserted width `K`, not by both `P` and `K`.

## Public intent ledger

The full ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

| ID | Evidence summary | Obligation |
|---|---|---|
| E1 | The issue says `Matrix.col_insert()` no longer works. | Treat legacy output as suspect. |
| E2 | The reproduction inserts two columns at position 3. | Cover interior multi-column insertion. |
| E3 | The issue says the identity block to the right is shifted to the wrong rows. | Preserve right-side original entries and row placement. |
| E4 | The public hint says "`pos` shouldn't be here" at the old index. | The post-insertion source column is `j - other.cols`. |
| E5 | The docstring says "Insert one or more columns at the given column position." | Specify ordinary insertion shape and entry mapping. |
| E6 | Public source normalizes `pos` and checks equal row counts. | Helper preconditions are normalized `P` and matching rows. |
| E7 | Sparse implementation shifts columns by `other.cols`. | Supporting compatibility evidence for the same mapping. |
| E8 | Existing public tests cover one-column insertion into zeros. | They support basic insertion but leave a nonzero right-frame gap. |
| E9 | Source comment preserves null-matrix construction behavior. | Keep the existing null-matrix branch unchanged. |

## Formal claims

The constructed K artifacts are:

- `fvk/mini-matrix.k`
- `fvk/col-insert-spec.k`

They define a minimal matrix-entry semantics and five claims:

- `C-SHAPE-ROWS`: result rows are `rows(A)`;
- `C-SHAPE-COLS`: result columns are `cols(A) + cols(B)`;
- `C-LEFT`: entries with `j < P` equal `A[i, j]`;
- `C-INSERT`: entries with `P <= j < P + cols(B)` equal
  `B[i, j - P]`;
- `C-RIGHT`: entries with `P + cols(B) <= j < cols(A) + cols(B)` equal
  `A[i, j - cols(B)]`.
- `C-NULL`: public null-matrix branch remains unchanged and bypasses the helper.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the claims, and
`fvk/SPEC_AUDIT.md` compares them to `fvk/INTENT_SPEC.md`. All claims pass the
adequacy audit. No formal claim relies solely on V1 behavior.

## Trusted base

The proof assumes:

- existing `col_insert` position normalization and row-shape guard are executed
  as written;
- `_new(rows, cols, entry)` constructs a matrix whose observable entries are
  supplied by `entry(i, j)`;
- matrix indexing and row/column attributes behave according to the existing
  matrix protocol.

These assumptions are outside the changed line and match existing public matrix
infrastructure.
