# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V2 should keep the source change that removes V1's snapshot fallback. This is
justified by Finding F1 and proof obligations PO5-PO8.

## Tests to add or expect in a normal development environment

Do not edit tests in this task. In a normal development pass, add coverage for:

1. The user's full flip/transpose expression returning
   `[[5, 8, 0], [0, 0, 1]]`.
2. The direct transformed matrix `[[1, 12], [0, 8], [0, 5]]` returning
   `[[1, 0], [0, 8], [0, 5]]`.
3. A rank-positive but rank-deficient tall matrix returning `rank(A)` columns,
   not a zero-column matrix.
4. Existing square and wide HNF examples, to confirm the all-row loop did not
   change cases where the old bottom-row window already contained all pivots.

## Commands to run later

Per task instructions, these were not run:

```sh
cd fvk
kompile mini-hnf.k --backend haskell
kast --backend haskell hnf-spec.k
kprove hnf-spec.k
```

Project tests were also not run. In a normal environment, run the relevant HNF
test modules after applying V2.

## If a later proof or test fails

1. First inspect PO3 and PO5: a failure there means the abstraction or the
   dropped-prefix argument is too weak.
2. If only canonical HNF shape fails while rank/module preservation holds,
   refine the `isColumnHNF` obligation without reintroducing the bottom-window
   scan.
3. Do not restore the V1 fallback unless public intent is clarified to define
   rank-positive tall matrices outside the HNF contract.
