# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "bug with HNF removing rows" | HNF must not drop an independent part of the result. | Encoded |
| E2 | prompt | "I expect ... to give `[[5, 8, 0], [0, 0, 1]]` but instead I get `[[5, 8, 0]]`" | The transformed tall matrix must return two HNF columns, not one. | Encoded |
| E3 | prompt | "falsely identifying my matrix as rank-deficient" | Rank must be preserved; full-column-rank tall matrices must not be treated as lower rank. | Encoded |
| E4 | prompt hints | Position of the `1` changes whether the second column is retained. | Pivot discovery must be position-invariant across all rows, not just the bottom `n` rows. | Encoded |
| E5 | docstring | "Compute the Hermite Normal Form of ... A" and "The HNF of matrix A" | Output is a normal form of `A`, so it must preserve `A`'s integer column module and rank. | Encoded |
| E6 | implementation | The routine uses `_gcdex` and `add_columns`, then returns a suffix of the transformed matrix. | Proof must show each column operation is unimodular and that every dropped prefix column is zero. | Proof obligation |
| E7 | public test, suspect | Existing public test expects `Matrix([[2, 7], [0, 0], [0, 0]])` to return a `3 x 0` matrix. | This conflicts with rank/module preservation for a rank-one input; do not use it to preserve legacy behavior. | Finding F3 |

Critical ledger entries are mirrored in `hnf-spec.k` as `SPEC-PROVENANCE`
comments.
