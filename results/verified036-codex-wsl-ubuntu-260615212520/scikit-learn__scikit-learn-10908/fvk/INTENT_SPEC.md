# Intent Spec

Status: constructed from public intent only; not machine-checked.

## Required behavior

I-001: For `CountVectorizer(vocabulary=V)` where `V` is a valid, non-empty constructor vocabulary and the vectorizer has not been fitted, `get_feature_names()` must not raise `NotFittedError`.

I-002: In the same fixed-vocabulary case, `get_feature_names()` must expose the feature names corresponding to the constructor vocabulary. For an iterable vocabulary, this is the iterable order because `_validate_vocabulary()` assigns consecutive indices by enumeration. For a mapping vocabulary, this is sorted by feature index.

I-003: A `CountVectorizer()` without a constructor vocabulary and without fitting remains outside the feature-name domain. `get_feature_names()` should continue to raise `NotFittedError` in that case.

I-004: Constructor vocabulary validation remains the existing validation contract: empty vocabularies, duplicate iterable terms, repeated mapping indices, or mappings with gaps are invalid and should raise the existing `ValueError` path rather than silently returning names.

I-005: The public API shape of `get_feature_names(self)` must not change. Subclasses and callers that invoke it without arguments should remain compatible.

