# Constructed Proof

Status: constructed, not machine-checked. The K commands in this file were not
run because the task forbids executing K tooling.

## Claims

The K claims are in `hgb-scorer-spec.k`:

- `HGB-GET-Y-BASE`: base helper returns target vector unchanged.
- `HGB-GET-Y-CLASSIFIER`: classifier helper decodes valid class codes through
  `classes_`.
- `HGB-SCORER-CLASSIFIER-VAL`: classifier scorer path with validation decodes
  both training and validation targets.
- `HGB-SCORER-CLASSIFIER-NOVAL`: classifier scorer path without validation
  decodes the training target and does not score validation.
- `HGB-SCORER-BASE-VAL`: base/regression scorer path with validation preserves
  both target vectors.
- `HGB-SCORER-BASE-NOVAL`: base/regression scorer path without validation
  preserves the training target and does not score validation.

## Proof Sketch

1. For base mode, symbolic execution of `getYForScorer(base, CLASSES, Y)`
   applies the `getYForScorerValue(base, ..., Y) => Y` rule. The result is
   exactly the original target vector. This discharges PO-B1.

2. For classifier mode, symbolic execution of
   `getYForScorer(classifier, CLASSES, codes(YS))` applies the classifier
   helper rule. Under the side condition `validCodes(CLASSES, YS)`, each code
   lookup `labelAt(CLASSES, i)` is defined, and structural recursion of
   `decode` maps every code to the corresponding public label. This discharges
   PO-C1 and uses PO-C2.

3. For `_check_early_stopping_scorer` with validation enabled, symbolic
   execution applies the `checkEarlyStoppingScorer(..., true)` rule. The
   `trainArg` cell is rewritten to `getYForScorerValue(..., YTRAIN)` and the
   `validationArg` cell is rewritten to `getYForScorerValue(..., YVAL)`. The
   classifier helper claim then reduces these to decoded labels; the base claim
   reduces them to unchanged targets. This discharges PO-S1 and PO-S2.

4. For `_check_early_stopping_scorer` with validation disabled, symbolic
   execution applies the `checkEarlyStoppingScorer(..., false)` rule. The
   `trainArg` cell is rewritten through the helper and `validationUsed` becomes
   false while `validationArg` is framed unchanged. This discharges PO-S1 and
   PO-S3.

5. Frame obligations are checked by source inspection. V1 does not route
   `_check_early_stopping_loss` through `_get_y_for_scorer`, does not alter
   `predict`, and does not change public signatures. This discharges PO-L1,
   PO-P1, and PO-API1.

No loops or recursive functions are present in the modeled fragment, so no
circularity claim is needed. This proof is partial correctness over the scorer
target representation if the audited scorer path is reached.

## Pre-Fix Failure Derivation

For the issue reproducer, take `CLASSES = "x", "y", .Labels` and
`YTRAIN = 0, 1, .Codes`. Before V1, the scorer boundary passed
`codes(YTRAIN)` directly. Classifier `predict` returns public labels, modeled
as `labels(decode(CLASSES, YTRAIN)) = labels("x", "y", .Labels)`. The scorer
therefore observed mixed target domains: encoded numeric `y_true` and public
string `y_pred`.

V1 changes the scorer boundary so the same input reaches the scorer as
`labels(decode(CLASSES, YTRAIN))`, matching the prediction representation.

## Test Recommendation

Conditioned on later machine-checking, tests that only assert numeric-label
early-stopping scorer target representation would be subsumed by these claims.
No such test removal is recommended here because the proof has not been
machine-checked and the task forbids modifying tests.

Keep existing early-stopping integration tests because this proof does not
cover tree training quality, convergence, termination, or score thresholds.
Add a future regression test for string labels with scorer-based early stopping
when test edits are allowed.

## Reproduce the Machine Check Later

These commands are provided for a future environment with K installed:

```sh
kompile fvk/mini-hgb-scorer.k --backend haskell
kast --backend haskell fvk/hgb-scorer-spec.k
kprove fvk/hgb-scorer-spec.k
```

Expected result: `#Top` for all claims. Until then, this remains constructed,
not machine-checked.
