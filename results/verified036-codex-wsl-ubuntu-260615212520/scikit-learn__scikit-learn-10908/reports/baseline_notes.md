# Baseline Notes

## Root cause

`CountVectorizer.transform` handles an explicit constructor `vocabulary` lazily: if `vocabulary_` has not been created yet, it calls `_validate_vocabulary()`, which validates the supplied vocabulary and assigns `vocabulary_`. `CountVectorizer.get_feature_names` did not do this. It called `_check_vocabulary()` immediately, so an unfitted vectorizer with a valid `vocabulary` parameter raised `NotFittedError` even though `transform` could already use that same vocabulary.

## Changed files

- `repo/sklearn/feature_extraction/text.py`: updated `CountVectorizer.get_feature_names()` to call `_validate_vocabulary()` when `vocabulary_` is missing, matching the lazy validation path already used by `transform()`. This allows fixed vocabularies supplied at construction time to expose feature names before fitting, while preserving the existing fitted check for vectorizers without a supplied vocabulary.

## Assumptions and alternatives considered

- I assumed the intended behavior applies to fixed constructor vocabularies only; vectorizers without a supplied vocabulary should still raise `NotFittedError` until fitted.
- I considered changing `_check_vocabulary()` to perform lazy validation globally, but rejected that because it would affect every caller of `_check_vocabulary()` rather than the issue-specific `get_feature_names()` path.
- I considered validating the vocabulary in `__init__`, but rejected that because the existing implementation intentionally validates lazily in `fit_transform()` and `transform()`.

## Verification

No tests or code were run, per the task constraints.
