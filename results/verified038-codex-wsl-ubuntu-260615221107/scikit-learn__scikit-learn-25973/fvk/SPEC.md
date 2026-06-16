# FVK Spec

Status: constructed, not machine-checked.

## Unit Under Audit

`repo/sklearn/feature_selection/_sequential.py`

- Public unit: `SequentialFeatureSelector.fit`
- Internal helper changed by V1: `_get_best_new_feature_score`
- Relevant dependency contracts: `check_cv`, `_CVIterableWrapper`,
  `cross_val_score`

## Human-Readable Contract

For a single `SequentialFeatureSelector.fit(X, y)` call, if `cv` is any valid
CV input accepted by the public `cv` parameter contract and it yields `S > 0`
splits, then every candidate feature subset scored during that fit must be
scored against a reusable checked CV object with the same `S` splits. In
particular, if `cv` is a one-shot iterable/generator, the first candidate may
not consume the only split source such that a later candidate sees zero splits
and triggers the reported `IndexError`.

The contract is partial: it does not prove estimator fitting, scoring quality,
feature ranking optimality, or termination/performance. It only proves that the
sequential search's repeated candidate scoring no longer reuses a consumable CV
iterator directly.

## Public Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- E1/E2/E6: one-shot iterable splits supplied as `cv` must work within one SFS
  fit.
- E3: the modeled bug is repeated consumption of the same generator by the
  internal candidate loop.
- E4/E8/E10: the intended repair is to call `check_cv` once per fit.
- E5/E7: generators remain accepted; no new warning or rejection is justified.
- E9: passing a checked CV object to `cross_val_score` preserves reuse.

## Formal Model Scope

The K model in `mini-sfs-cv.k` abstracts away estimator fitting and score values.
It preserves the property axis that matters for the issue:

- one-shot CV values versus reusable checked CV values;
- the one-time normalization step;
- repeated candidate scoring calls in a single fit;
- whether every candidate observes a positive split count.

The model has a discriminator: `rawFit(oneShot(S), C)` with `S > 0` and `C >= 2`
can reach `failedEmptyScores`, while `fit(oneShot(S), C)` first rewrites through
`checkCv` and reaches `done` after exactly `C` successful score calls.

## Preconditions

- `S > 0`: the iterable produces at least one split.
- `C >= 0`: the candidate-scoring loop has a non-negative number of score calls.
- The input is one of the public CV families represented in the formal model:
  `oneShot(S)`, `iterable(S)`, `splitter(S)`, `intCv(S)`, or `noneCv`.

## Postconditions

- For `oneShot(S)`, `fit(oneShot(S), C)` ends with a checked reusable CV value
  containing `S` splits and `scores == C`.
- The same postcondition shape holds for list-like iterables, splitter objects,
  integer CV values, and `None` after their corresponding `checkCv` rewrite.
- The candidate loop never transitions to `failedEmptyScores` under those
  preconditions.

## Frame Conditions

- `self.cv` remains the constructor-supplied parameter; normalization is local to
  `fit`.
- Public method signatures are unchanged.
- Parameter validation remains unchanged and continues accepting iterable CV
  inputs.
- Existing integer/`None` and splitter CV behavior is preserved modulo the local
  variable now holding the already-normalized CV object.
