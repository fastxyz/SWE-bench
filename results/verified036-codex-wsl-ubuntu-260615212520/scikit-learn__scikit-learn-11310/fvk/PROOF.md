# Constructed Proof

Status: constructed, not machine-checked.

The benchmark forbids running K tooling, so this proof is a constructed
reachability proof over the emitted K claims. It must be machine-checked later
with:

```sh
kompile fvk/mini-python-refit.k --backend haskell
kast --backend haskell fvk/searchcv-refit-spec.k
kprove fvk/searchcv-refit-spec.k
```

Expected result after machine checking: `#Top`.

## Claim REFIT-TRUE

Initial state:

- `<k> fitTail(true, HASY) </k>`
- no best estimator, no refit time, no recorded `y` branch
- clock cells contain `TStart` and `TEnd`
- side condition `TEnd >= TStart`

Symbolic execution:

1. Apply the `fitTail(true, HASY)` rule. The computation becomes
   `cloneBest ~> startClock ~> fitBest(HASY) ~> storeRefitTime`.
2. Apply `cloneBest`. The best-estimator state changes from absent to cloned.
   This occurs before timing starts.
3. Apply `startClock`. The start sample becomes `TStart`.
4. Apply `fitBest(HASY)`. The best-estimator state changes from cloned to
   fitted and the model records whether the branch used `y`.
5. Apply `storeRefitTime`. Under `TEnd >= TStart`, the refit-time state changes
   from absent to `TEnd - TStart`.
6. The computation reaches `.K`; framed cells such as `cvState` are unchanged.

This discharges PO1, PO3, and the relevant part of PO5 for normal completion.

## Claim REFIT-FALSE

Initial state:

- `<k> fitTail(false, HASY) </k>`
- arbitrary existing best-estimator, refit-time, start-sample, and branch state

Symbolic execution:

1. Apply the `fitTail(false, HASY)` rule.
2. The computation reaches `.K` without changing any modeled state.

This discharges PO2 and the relevant frame part of PO5.

## Source Correspondence

`repo/sklearn/model_selection/_search.py` implements `REFIT-TRUE` in the
`if self.refit:` branch by cloning and parameterizing `best_estimator_`,
sampling `time.time()` immediately before the final `fit`, and assigning
`self.refit_time_` immediately after final fit returns.

`repo/sklearn/grid_search.py` implements the same proof obligation in its
deprecated duplicate `_fit` branch after V2.

Both source files implement `REFIT-FALSE` by skipping the refit branch when the
public `refit` flag is false.

## Residual Risk

The proof is partial correctness for the modeled final-refit tail. It does not
prove termination of candidate search, correctness of scoring, behavior after a
final estimator `fit` exception, or wall-clock monotonicity beyond the explicit
`TEnd >= TStart` side condition.

Test removal is not justified because the proof was not machine-checked.
Recommended tests to keep or add are listed in `fvk/ITERATION_GUIDANCE.md`.
