# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK run specifies the dropped-estimator routing core of
`repo/sklearn/ensemble/voting.py::_BaseVoting.fit`, as called by
`VotingClassifier.fit` and `VotingRegressor.fit`.

The proof model represents each configured estimator as
`est(name, dropped, supportsSampleWeight)`. It verifies which estimators are
checked for sample-weight support, which estimators are fitted, and which names
populate the fitted-name view. It abstracts base-estimator learning, cloning
internals, label encoding, numpy arrays, and joblib scheduling.

## Public Intent Ledger

| ID | Evidence | Obligation |
|---|---|---|
| E1 | Issue says weighted fit fails when an estimator is `None`. | Weighted fit with dropped estimators is in-domain. |
| E2 | Issue says the `sample_weight` support check does not check for `None`. | Support checking must range over non-dropped estimators only. |
| E3 | Prompt example drops `lr` and refits with weights. | The dropped estimator is neither inspected nor fitted; remaining estimators are fitted. |
| E4 | Traceback is `AttributeError` from `None.fit`. | The traceback is the legacy defect to eliminate. |
| E5 | Voting docstring says `estimators_` are fitted sub-estimators not `None`. | `estimators_` is ordered active estimators only. |
| E6 | Voting docstring says `named_estimators_` accesses fitted estimators. | `named_estimators_` must align names with the same active fitted list. |
| E7 | Public tests preserve unsupported active-estimator errors with sample weights. | Non-dropped unsupported estimators still raise the existing ValueError. |
| E8 | Public tests preserve all-estimators-None ValueError. | All dropped estimators remain an error. |

The standalone ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

Let `active(estimators)` be the original estimator sequence with every
`None`/dropped entry removed, preserving order.

For valid estimator names and weights length:

1. If `sample_weight is not None`, sample-weight support is checked for every
   estimator in `active(estimators)` and for no dropped estimator.
2. If any active estimator lacks `sample_weight` support, fit raises the
   existing unsupported-estimator `ValueError` naming that active estimator.
3. If `active(estimators)` is empty, fit raises the existing all-dropped
   `ValueError`.
4. Otherwise, fit clones and fits exactly the estimators in
   `active(estimators)`, preserving order and passing `sample_weight` exactly
   when supplied.
5. `estimators_` contains the fitted clones from `active(estimators)`.
6. `named_estimators_` maps each active estimator name to the corresponding
   fitted clone in `estimators_`.
7. Existing validations for invalid `estimators`, weights length, and names are
   preserved.

## Formal Claims

The machine-oriented claims are in `fvk/voting-fit-spec.k`:

- `FIT-SAMPLE-WEIGHT-ACTIVE`
- `FIT-REPORTED-EXAMPLE`
- `FIT-ACTIVE-UNSUPPORTED`
- `FIT-ALL-DROPPED`
- `FIT-NO-SAMPLE-WEIGHT`

The mini semantics are in `fvk/mini-python.k`.

## Abstraction Boundary

This proof is about routing and fitted-name alignment. It does not prove:

- estimator-specific learning correctness;
- numpy input validation;
- `LabelEncoder` behavior;
- joblib implementation internals beyond ordered result collection;
- termination or performance.
