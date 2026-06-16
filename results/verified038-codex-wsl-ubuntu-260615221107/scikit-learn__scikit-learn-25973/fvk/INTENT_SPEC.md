# Intent Spec

Status: constructed from public intent before accepting candidate behavior.

## Required Behavior

1. `SequentialFeatureSelector` accepts the documented `cv` family: integer or
   `None` defaults, CV splitter objects, and non-string iterables yielding
   `(train, test)` index splits.

2. A one-shot iterable of splits, including the generator returned by a CV
   splitter's `split(...)` method, is in scope for a single
   `SequentialFeatureSelector.fit(X, y)` call.

3. During a single `fit`, every candidate feature subset evaluated by the
   sequential search must be scored over the same intended CV splits. Later
   candidates must not observe an already-consumed split iterable and must not
   fail with the reported empty-score `IndexError`.

4. The fix should follow the existing scikit-learn CV API rather than reject
   generators or emit a new warning: use `check_cv`, whose documented contract
   accepts iterables and returns a splitter-like object.

5. Existing behavior for reusable CV objects, integer/`None` CV defaults,
   scoring, `n_jobs`, feature-selection direction, and estimator parameters
   should be preserved except for eliminating repeated consumption of one-shot
   CV iterables within one fit.

6. Public estimator parameters should remain inspectable as user-provided
   constructor values. Normalized fit-local objects should not overwrite
   `self.cv`.

## Domain Assumptions

- The split iterable yields a finite number of splits.
- The split iterable yields at least one split for scoring. Empty split
  iterables are malformed for this scoring path and are not the reported issue.
- Partial correctness only: the FVK proof addresses the absence of CV exhaustion
  in the scoring loop if the surrounding estimator/scorer calls return.
- Reusing the exact same one-shot generator object across separate calls to
  `fit` is not guaranteed by this intent; a one-shot object is only required to
  work for the single fit in which it is first supplied, matching the behavior of
  other `check_cv` users.
