# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were executed.

## Claims Proved in the Model

- `SFS-SCORE-LOOP`: a checked reusable CV with `S > 0` splits can be used for
  `C >= 0` candidate score calls, producing exactly `C` successful scoring
  events.
- `SFS-FIT-ONESHOT`: one-shot CV iterables are normalized before scoring and
  therefore complete all candidate score calls in one fit.
- `SFS-FIT-ITERABLE`, `SFS-FIT-SPLITTER`, `SFS-FIT-INT`, `SFS-FIT-NONE`: other
  documented CV families preserve reusable scoring behavior.
- `SFS-RAW-ONESHOT-FAILS`: the pre-V1 shape can reach an empty-score failure
  when a one-shot CV source is scored repeatedly without normalization.

## Proof Sketch

1. `fit(CV, C)` takes one semantic step to set the local `<cv>` cell to
   `checkCv(CV)` and starts `scoreLoop(C)`.

2. For `oneShot(S)`, `iterable(S)`, and equivalent public CV families,
   `checkCv` rewrites to `checked(S)`; for `noneCv`, it rewrites to
   `checked(5)`. This models `check_cv` and `_CVIterableWrapper(list(cv))`.

3. The circularity/induction claim is `SFS-SCORE-LOOP`.
   - Base case: `scoreLoop(0)` rewrites to `done` and `scores` is unchanged.
   - Step case: for `C > 0`, `scoreLoop(C)` rewrites to
     `score ~> scoreLoop(C - 1)`. The `score` rule requires `S > 0`, increments
     `<scores>` by one, and leaves `<cv> checked(S)` unchanged. The circularity
     applies to `scoreLoop(C - 1)`.
   - Arithmetic VC: `1 + (C - 1) = C` under `C > 0`, discharged by integer
     arithmetic.

4. Composing steps 1-3 proves `SFS-FIT-ONESHOT`: the one-shot source is consumed
   only by the single `checkCv` materialization step, after which all candidate
   scoring sees `checked(S)`.

5. The raw counterexample claim uses the pre-V1 shape. `rawScore` on
   `oneShot(S)` with `S > 0` rewrites the CV state to `oneShot(0)`. If
   `C >= 2`, the next raw score call can rewrite to `failedEmptyScores`. This
   matches the issue's described failure mechanism.

## Source-Level Correspondence

- `checkCv(oneShot(S)) => checked(S)` corresponds to
  `check_cv(self.cv, y, classifier=is_classifier(cloned_estimator))` and
  `_CVIterableWrapper(cv).__init__` storing `list(cv)`.
- `scoreLoop(C)` corresponds to the repeated candidate scoring inside
  `SequentialFeatureSelector.fit` and `_get_best_new_feature_score`.
- The invariant that `<cv> checked(S)` is unchanged by `score` corresponds to
  passing the local checked `cv` object to `cross_val_score` for every candidate.

## Machine-Check Commands To Run Later

These commands are recorded only; they were not executed.

```sh
cd fvk
kompile mini-sfs-cv.k --backend haskell
kast --backend haskell sfs-cv-spec.k
kprove sfs-cv-spec.k
```

Expected machine-check result after any syntax adjustments required by a local K
installation: `kprove` discharges the claims to `#Top`.

## Residual Risk

- The proof is partial correctness only and does not prove estimator fitting,
  scoring correctness, feature ranking, or performance.
- The proof relies on adequacy of the mini semantics rather than full Python and
  full scikit-learn semantics.
- Empty split iterables and repeated use of the same already-consumed generator
  across separate fits remain outside the proven domain.
- Test removal is not recommended until the K commands are actually run and
  return `#Top`.

## Test Guidance

If tests were editable, a nonregression test should exercise a one-shot split
generator in `SequentialFeatureSelector.fit`. Once the proof is machine-checked,
such an in-domain unit test would be subsumed by `SFS-FIT-ONESHOT`; until then,
keep all tests. Integration, malformed-CV, empty-split, estimator/scorer failure,
and performance tests are not subsumed by this proof.
