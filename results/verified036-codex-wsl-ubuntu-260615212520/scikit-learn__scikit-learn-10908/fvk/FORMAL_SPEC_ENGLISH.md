# Formal Spec English

Status: constructed, not machine-checked.

## PO-001

If a `CountVectorizer` has no `vocabulary_` yet but has a valid, non-empty constructor `vocabulary`, then `get_feature_names()` first validates and materializes that vocabulary, sets the fixed-vocabulary state, raises no exception, and returns the feature names ordered by their integer feature indices.

## PO-002

If a `CountVectorizer` already has a non-empty `vocabulary_`, then `get_feature_names()` raises no exception and returns the feature names ordered by their integer feature indices.

## PO-003

If a `CountVectorizer` has neither a constructor vocabulary nor an existing `vocabulary_`, then `get_feature_names()` raises `NotFittedError` and returns no feature-name list. The proof does not treat any `fixed_vocabulary_` side effect on this error path as public intent.

## PO-004

If a `CountVectorizer` has no `vocabulary_` yet and its constructor `vocabulary` is invalid or empty, then `get_feature_names()` follows the existing validation failure path and raises `ValueError` rather than returning feature names.

## PO-005

The public method remains `get_feature_names(self)` with no new arguments, no changed caller protocol, and the same list-like result shape.

