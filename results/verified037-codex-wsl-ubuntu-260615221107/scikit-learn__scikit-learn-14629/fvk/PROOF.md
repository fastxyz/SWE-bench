# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Machine-Check Commands

These commands are emitted for a later environment with K installed:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell multioutput-classes-spec.k
kprove multioutput-classes-spec.k
```

Expected result after successful machine checking: `#Top`.

## Trusted Base

- Adequacy of the mini semantics in `fvk/mini-python.k` for the audited state
  axis: ordered fitted estimators, per-estimator `classes_`,
  `MultiOutputClassifier.classes_`, and the `_fit_and_predict` list consumer.
- The scikit-learn classifier convention that fitted classifiers expose their
  own `classes_`.
- K reachability proof rules, simplification rules, and the Haskell backend
  once run in a suitable environment.

## Claim 1: Fit Sets Classes

Claim:

`moc_fit(SELF, CS)` reaches a state where `SELF` maps to
`MOC(estimatorsFromClasses(CS), CS)` for every non-empty per-output class list
`CS`.

Proof sketch:

1. `moc_fit` represents the V1 method body after public input validation and
   successful delegated fitting.
2. The delegated `super().fit(...)` path constructs one fitted estimator per
   output. In the model this is `estimatorsFromClasses(CS)`.
3. V1 then evaluates the list comprehension
   `[estimator.classes_ for estimator in self.estimators_]`.
4. The simplification lemma
   `classesFromEstimators(estimatorsFromClasses(CS)) => CS` discharges the
   structural induction over that estimator list: empty list maps to empty list,
   and a non-empty list preserves head class labels and recursively preserves
   the tail.
5. The final state therefore contains `classes_ == CS` in estimator order.

Obligations discharged: PO-1, PO-2.

Findings addressed: F-1.

## Claim 2: Partial Fit Sets Classes

Claim:

`moc_partial_fit(SELF, CS)` reaches a state where `SELF` maps to
`MOC(estimatorsFromClasses(CS), CS)` for every non-empty per-output class list
`CS`.

Proof sketch:

The proof is the same as Claim 1 after substituting the successful delegated
incremental fit transition for the full fit transition. V1 preserves delegated
availability with `@if_delegate_has_method('estimator')`, delegates to the
shared implementation, and then runs the same list comprehension over
`self.estimators_`.

Obligations discharged: PO-4, PO-5.

Findings addressed: F-2, F-5.

## Claim 3: Cross-Validation Probability Path Can Read Classes

Claim:

After `moc_fit(SELF, CS)`, `cvp_predict_proba(SELF, PREDS)` reaches a state
whose result is `enforceListOrder(CS, PREDS)` whenever `PREDS` has the same
length as `CS`.

Proof sketch:

1. By Claim 1, the fitted classifier state contains `classes_ == CS`.
2. `MultiOutputClassifier.predict_proba` constructs its prediction list by
   iterating over `self.estimators_`.
3. V1 constructs `classes_` by iterating over the same `self.estimators_`.
4. Therefore, for each index `i_label` used by `_fit_and_predict`,
   `predictions[i_label]` and `classes_[i_label]` refer to the same output.
5. The modeled consumer `cvp_predict_proba` can pass `CS` and `PREDS` to
   `enforceListOrder` instead of failing on a missing `classes_` attribute.

Obligations discharged: PO-2, PO-3, PO-7.

Findings addressed: F-1, F-3, F-5.

## Adequacy And Completeness Check

The proof covers the full public issue behavior: the missing fitted
`classes_` attribute on `MultiOutputClassifier` and the consumer that indexes
it. It also covers successful `partial_fit` because the public hint states a
classifier fitted state should store `classes_`.

The proof intentionally does not prove numerical probability values or
`_enforce_prediction_order` internals. Those are frame conditions: the issue is
the missing metadata attribute, and V1 does not change probability computation
or ordering code.

## Test Guidance

No tests are deleted. After machine-checking, tests that only assert
`MultiOutputClassifier.classes_[i] == estimator.classes_` for successful fit
would be subsumed by the proof, but integration tests for
`cross_val_predict(..., method='predict_proba')` should be kept because they
exercise real scikit-learn wiring outside the mini semantics.
