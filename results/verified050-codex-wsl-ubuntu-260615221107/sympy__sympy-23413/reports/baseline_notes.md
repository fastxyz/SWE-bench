# Baseline Notes

## Root cause

The non-modular Hermite normal form implementation in
`sympy/polys/matrices/normalforms.py` only processed `min(m, n)` rows from the
bottom of an `m x n` matrix. For tall matrices, this can miss an independent
column whose pivot is only visible in a row above that bottom window.

In the reported examples, the matrix has more rows than columns and full column
rank, but the bottom `n` rows look rank-deficient to the pivot search. The
routine then returns only the columns found in that truncated search, dropping
one HNF column and causing the row-style HNF workaround based on flips and
transposes to lose a row.

## Changed files

`repo/sympy/polys/matrices/normalforms.py`

The `_hermite_normal_form` loop now continues upward past the original
bottom-row window when pivots are still missing. It keeps a snapshot of the
old result at the original cutoff and only uses the extended search result if
all columns are recovered as pivots. If the matrix remains column-rank
deficient after the extended search, it restores the old truncated result.

This targets the reported full-column-rank tall-matrix case while avoiding a
broader change to existing rank-deficient behavior.

## Assumptions and alternatives considered

I assumed the issue is specifically the false loss of a column for tall matrices
that actually have full column rank, matching the public hint where the position
of the `1` determines whether a second pivot is discovered.

I considered changing the loop to process every row unconditionally and return
every pivot found. That would also fix the reported matrix, but it would change
rank-deficient tall matrices whose current HNF result has fewer columns. I
rejected that as broader than necessary for this issue.

I also considered adding an explicit rational rank computation before HNF. That
would make the full-column-rank condition direct, but it would add extra rank
work to the default HNF path. The implemented snapshot-and-continue approach
detects the needed full-column-rank recovery using the same column operations
already being performed.

No tests or project code were run, per the task instructions.
