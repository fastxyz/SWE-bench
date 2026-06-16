# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Fixed vocabulary, unfitted vectorizer

Input class: `CountVectorizer(vocabulary=P)` where `P` is valid and non-empty, and `vocabulary_` is absent.

Expected: `get_feature_names()` validates/materializes `P`, sets `vocabulary_` to the normalized mapping, sets fixed-vocabulary state, returns names ordered by feature index, and raises no exception.

Evidence: E-001, E-002, E-003, E-004, E-005.

V1 status: discharged by the added guard and call to `_validate_vocabulary()` before `_check_vocabulary()`.

## PO-002: Existing vocabulary

Input class: `vocabulary_` already exists and is non-empty.

Expected: `get_feature_names()` returns names ordered by feature index and does not revalidate constructor state.

Evidence: E-005 and existing fitted behavior.

V1 status: discharged; the new guard is skipped when `vocabulary_` exists.

## PO-003: No constructor vocabulary and unfitted

Input class: `CountVectorizer()` with no `vocabulary_`.

Expected: `get_feature_names()` raises `NotFittedError` and returns no names.

Evidence: E-006.

V1 status: discharged; `_validate_vocabulary()` does not create `vocabulary_` when `self.vocabulary is None`, so `_check_vocabulary()` raises the existing fittedness error.

## PO-004: Invalid constructor vocabulary

Input class: constructor vocabulary is empty, has duplicate iterable terms, repeated mapping indices, or mapping index gaps.

Expected: `get_feature_names()` raises `ValueError` through the existing validation path.

Evidence: E-004.

V1 status: discharged; the new lazy validation invokes the existing `_validate_vocabulary()` implementation and does not duplicate or weaken it.

## PO-005: Public compatibility

Input class: public callers and subclasses invoking `get_feature_names()` with no arguments.

Expected: method signature and result shape remain compatible.

Evidence: E-007.

V1 status: discharged; the patch changes only method internals.

