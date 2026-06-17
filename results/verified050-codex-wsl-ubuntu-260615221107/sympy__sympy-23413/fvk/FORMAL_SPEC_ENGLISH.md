# Formal Spec English

Status: constructed, not machine-checked.

## HNF-TOTAL-CORRECT-SHAPE

For every integer matrix `A`, executing the modeled non-modular HNF routine
returns a matrix `H` with the same number of rows as `A`, with column count
equal to `rank(A)`, in column-style HNF, and generating the same integer column
module as `A`.

## HNF-ISSUE-INSTANCE

For the concrete transformed issue matrix `[[1, 12], [0, 8], [0, 5]]`, the
modeled routine returns `[[1, 0], [0, 8], [0, 5]]`.

## HNF-RANK-DEFICIENT-TALL

For a tall matrix whose rank is positive but less than its number of columns,
the modeled routine still returns `rank(A)` columns. In particular, a rank-one
tall matrix may not return a zero-column matrix solely because the nonzero row
is above the bottom `n` rows.

## OUTER-LOOP-CIRCULARITY

At each outer-loop step, either all columns have already become pivots and the
loop stops, or the next row is processed. Processing a row preserves the
integer column module by a unimodular column operation sequence. If the row
contains a nonzero value in the active prefix, the pivot count increases by
one; otherwise the active column index is restored and the search continues to
the next row above.

## INNER-LEFT-REDUCTION-CIRCULARITY

For a fixed row and active pivot column `k`, repeatedly combining column `k`
with each column `j < k` replaces the row entries in those columns with zero
and keeps column `k` equal to the gcd of the processed prefix. The pairwise
column transformation has determinant `1`, so it preserves the column module.

## RIGHT-REDUCTION-CIRCULARITY

For a nonzero pivot `b`, reducing columns to the right by quotient multiples of
the pivot column preserves the column module and makes each pivot-row entry to
the right a division remainder modulo `b`.
