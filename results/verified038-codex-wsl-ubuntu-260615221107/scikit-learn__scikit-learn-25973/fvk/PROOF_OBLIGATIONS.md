# Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - CV Input Domain

The SFS `cv` parameter must continue accepting integer/`None` defaults, CV
splitter objects, and non-string iterables yielding `(train, test)` splits.

- Evidence: E1, E5, E6, E7.
- Discharge: V1 leaves `_parameter_constraints["cv"]` unchanged and uses
  `check_cv`, which accepts the same family.

## PO-2 - Single Normalization Per Fit

`SequentialFeatureSelector.fit` must call `check_cv` on `self.cv` once before
the internal candidate-scoring loop.

- Evidence: E3, E4, E10.
- Discharge: V1 computes local `cv = check_cv(...)` immediately after cloning
  the estimator and before the `for _ in range(n_iterations)` loop.

## PO-3 - One-Shot Iterable Materialization

If `self.cv` is a non-string iterable without a `split` method, the checked CV
object must be backed by stored splits rather than the original one-shot
iterator.

- Evidence: E4, E8.
- Discharge: `check_cv` returns `_CVIterableWrapper(cv)`, whose constructor
  stores `self.cv = list(cv)`.

## PO-4 - Reuse in Every Candidate Score

Every candidate subset scored by `_get_best_new_feature_score` must pass the
same checked CV object to `cross_val_score`.

- Evidence: E2, E3, E9.
- Discharge: V1 changed `_get_best_new_feature_score` to accept `cv` and pass
  `cv=cv` to `cross_val_score` instead of `cv=self.cv`.

## PO-5 - Frame Existing CV Behavior

Integer, `None`, and splitter CV inputs must preserve existing behavior.

- Evidence: E5, E6, E9.
- Discharge: all are still routed through `check_cv`; splitter-like objects with
  `split` are returned unchanged by `check_cv`, and integer/`None` values become
  the same KFold/StratifiedKFold defaults that `cross_val_score` would use.

## PO-6 - Public API Compatibility

The repair must not change the public constructor, `fit`, public attributes, or
parameter validation contract.

- Evidence: E5, E7.
- Discharge: V1 changes only local fit behavior and a private helper signature;
  `self.cv` remains user-provided.

## PO-7 - Domain Boundaries Are Explicit

The proof must not claim behavior for empty split iterables, invalid CV values,
estimator/scorer failures, or repeated use of the same already-consumed generator
across separate fits.

- Evidence: F3, F4.
- Discharge: K claims require `S > 0` and only model a single fit.

## PO-8 - Adequacy and Compatibility Gates

The English meaning of the K claims must match public intent, and compatibility
must have no unhandled public callsite or override.

- Evidence: `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`,
  `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Discharge: all formal claims pass adequacy audit; compatibility audit found no
  public API blocker.
