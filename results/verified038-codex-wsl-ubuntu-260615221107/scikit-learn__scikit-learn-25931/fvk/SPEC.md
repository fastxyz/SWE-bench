# FVK Spec

Status: constructed, not machine-checked.

## Target

The audited patch is V1 in `repo/sklearn/ensemble/_iforest.py`.
It changes `IsolationForest.fit` so the non-auto contamination branch computes
`offset_` with a private `_score_samples` helper instead of the public
`score_samples` method. Public `score_samples` still validates user input and
then delegates to the helper.

## Public intent ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical
entries are:

- E-001/E-003: DataFrame `fit` with valid feature names and fixed
  contamination must not emit the invalid-feature-names warning.
- E-004: The root cause is the public `score_samples` validation running on an
  internal array after `fit` recorded feature names from the original
  DataFrame.
- E-005: The public maintainer-suggested repair shape is a private scorer
  without validation, public validation that delegates to it, and an internal
  `fit` call to the private scorer.
- E-008/E-013: Public feature-name validation warnings remain intended for
  public post-fit calls.
- E-010/E-012: Sparse input remains part of the supported surface.

## Domain

The proof domain is accepted `IsolationForest` input after existing validation
preconditions hold:

- DataFrame-style inputs with all-string column names are modeled as
  `df(N)`, where `N > 0`.
- Array-like inputs without feature names are modeled as `arr(N)`.
- Sparse inputs are modeled as `csc(N)` or `csr(N)`.
- Fixed contamination is modeled as `fixed(C)`, where `C > 0`; the proof does
  not model the exact floating-point interval because parameter validation is
  outside the changed code path.

Invalid shapes, invalid feature-name dtypes, and invalid constructor
parameters remain delegated to existing validation code.

## Observable property

The property under verification is not the numeric IsolationForest scoring
algorithm. The property is the validation and warning control flow:

- which path validates user input;
- whether that path can append the invalid-feature-names warning;
- which validated representation is scored to define `offset_`;
- whether sparse scoring receives CSR.

The K model keeps those observables explicit through cells:

- `<namesSeen>`: whether `feature_names_in_` has been recorded;
- `<warnings>`: warnings emitted by feature-name validation;
- `<offset>`: abstract offset expression;
- `<fitted>`: fitted-state marker.

## Formal files

- `fvk/mini-iforest.k`: minimal K semantics for the validation/scoring fragment.
- `fvk/iforest-fit-spec.k`: reachability claims for the V1 obligations.

The model abstracts `raw(...)` tree scores and `percentile(...)` as symbolic
values. This is adequate because the issue concerns an unexpected warning, not
a changed score formula. The offset claim still enforces that V1 scores the
same validated training representation.

## Function contracts

`IsolationForest.fit` with `contamination != "auto"`:

- validates the original user input once with reset semantics;
- records feature names if the original input has valid DataFrame names;
- trains on the validated internal representation;
- computes `offset_` from `_score_samples` on the already validated training
  representation;
- does not call public `score_samples` and therefore does not perform
  reset=False feature-name validation on the transformed array.

`IsolationForest.fit` with `contamination == "auto"`:

- retains the existing branch behavior, setting the auto offset without the
  non-auto scoring path.

`IsolationForest.score_samples`:

- checks fitted state;
- validates public user input with `reset=False`;
- preserves the expected public warning when a fitted-with-names estimator is
  scored on data without valid feature names;
- delegates numeric scoring to `_score_samples`.

`IsolationForest._score_samples`:

- assumes its input has already been validated by either `fit` or public
  `score_samples`;
- converts sparse input to CSR before scoring;
- returns the opposite of the chunked raw score through the existing
  computation.

## Conclusion

The V1 code satisfies the intent-level contract. No additional production-code
edit is justified by this FVK pass.
