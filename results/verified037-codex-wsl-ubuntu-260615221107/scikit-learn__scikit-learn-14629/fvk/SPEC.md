# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target issue: `cross_val_predict(method='predict_proba')` raises
`AttributeError` when the estimator is `MultiOutputClassifier` because
`_fit_and_predict` expects `estimator.classes_` after fitting.

Audited production file: `repo/sklearn/multioutput.py`.

Audited source consumers:

- `repo/sklearn/model_selection/_validation.py`, list-prediction branch of
  `_fit_and_predict`;
- `repo/sklearn/multioutput.py`, `MultiOutputClassifier.predict_proba`;
- `repo/sklearn/multioutput.py`, `ClassifierChain.fit` as the local pattern for
  per-output `classes_`.

## Intent-Only Obligations

1. A successfully fitted `MultiOutputClassifier` exposes `classes_`.
2. `classes_` is indexed per output: entry `i` is the class-label array from
   fitted estimator `estimators_[i]`.
3. For list-valued multi-output probabilities, `_fit_and_predict` can read
   `estimator.classes_[i_label]` for every prediction output.
4. Existing fitting, `predict_proba`, delegated `partial_fit`, and regressor
   behavior remain compatible.
5. Wrapped classifiers are assumed to obey the scikit-learn classifier contract:
   after successful fitting, each exposes its own `classes_`.

The expanded intent-only artifact is `fvk/INTENT_SPEC.md`.

## Public Evidence Ledger

Critical evidence entries, mirrored from `fvk/PUBLIC_EVIDENCE_LEDGER.md`:

- E2: Expected result is prediction probabilities, not a missing-attribute
  error.
- E3: The reported `AttributeError` is the legacy symptom to remove.
- E4: The issue identifies `mo_clf.estimators_[i].classes_` as the needed
  per-output source.
- E5: Public hint: all classifiers should store `classes_` when fitted.
- E6: Public hint: add `classes_` to `MultiOutputClassifier` like
  `ClassifierChain`.
- E7: `_fit_and_predict` indexes `estimator.classes_[i_label]` for list
  predictions.
- E8: `MultiOutputClassifier.predict_proba` returns one list element per
  estimator in estimator order.

## Formal Model

The constructed K model is intentionally small and property-complete for this
bug. It does not model all of Python or all of scikit-learn; it models the state
axis the issue depends on:

- `estimators_`: ordered list of fitted per-output estimators;
- each fitted estimator's `classes_`;
- `MultiOutputClassifier.classes_`;
- the `_fit_and_predict` list branch that reads `classes_[i_label]`.

Machine-checkable core, not executed here:

- `fvk/mini-python.k`;
- `fvk/multioutput-classes-spec.k`.

Reproduction commands to run later in an environment with K:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell multioutput-classes-spec.k
kprove multioutput-classes-spec.k
```

Expected machine-check result after running the commands: `#Top`.

## Formal Claims

Claim `MOC-FIT-SETS-CLASSES`:

For any non-empty per-output class list `CS`, executing the abstract
`MultiOutputClassifier.fit` transition leaves the classifier state with
`classes_ == CS` and `estimators_` ordered consistently with `CS`.

Claim `MOC-PARTIAL-FIT-SETS-CLASSES`:

For any non-empty per-output class list `CS`, executing the abstract successful
`MultiOutputClassifier.partial_fit` transition leaves the classifier state with
`classes_ == CS` and `estimators_` ordered consistently with `CS`.

Claim `CVP-PREDICT-PROBA-CAN-INDEX-CLASSES`:

For any non-empty `CS` and prediction list `PREDS` with the same length,
executing the abstract fit followed by the list-valued `cross_val_predict`
probability branch can read `classes_[i]` for each output and feed those class
labels to prediction-order enforcement.

## Frame Conditions

- `MultiOutputRegressor` must not gain classifier-only `classes_`.
- `cross_val_predict` should not need a `MultiOutputClassifier` special case.
- `predict_proba` remains responsible for raising the existing `ValueError` when
  fitted base estimators do not implement `predict_proba`.
- The fix must not alter the probability values themselves; it only supplies
  fitted metadata needed to order them.

## Adequacy

The formal-English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the
intent obligations above. `fvk/SPEC_AUDIT.md` marks each obligation as pass, and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no unhandled public callsite,
signature, override, or producer/consumer incompatibility.
