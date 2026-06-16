# Public Evidence Ledger

Status: constructed, not machine-checked.

## E-001: Issue report, fixed vocabulary should work before fitting

Source: `benchmark/PROBLEM.md`

Evidence: "if you provide the `vocabulary` at the initialization of the vectorizer you could transform a corpus without a prior training"

Obligation: A supplied constructor vocabulary is sufficient public state for vocabulary-dependent operations that do not need learned document statistics.

Encoded in: PO-001.

## E-002: Issue report, reported defect

Source: `benchmark/PROBLEM.md`

Evidence: "`vectorizer.get_feature_names()` -> `NotFittedError: CountVectorizer - Vocabulary wasn't fitted.`"

Obligation: That `NotFittedError` is the symptom to remove for valid fixed vocabularies.

Encoded in: PO-001, F-001.

## E-003: Issue report, intended repair direction

Source: `benchmark/PROBLEM.md`

Evidence: "`transform` calls `_validate_vocabulary` method which sets the `vocabulary_` instance variable. In the same manner ... `get_feature_names` should not raise"

Obligation: `get_feature_names()` should lazily call the same vocabulary validation/materialization path before checking fittedness.

Encoded in: PO-001.

## E-004: Existing public docstring for `vocabulary`

Source: `repo/sklearn/feature_extraction/text.py`

Evidence: "`vocabulary` : Mapping or iterable, optional ... Indices in the mapping should not be repeated and should not have any gap"

Obligation: The valid-input domain for fixed vocabularies is non-empty iterable terms or mappings with unique, gapless indices.

Encoded in: PO-001, PO-004.

## E-005: Existing method docstring

Source: `repo/sklearn/feature_extraction/text.py`

Evidence: "`get_feature_names`: Array mapping from feature integer indices to feature name"

Obligation: Returned names are ordered by feature integer index.

Encoded in: PO-001, PO-002.

## E-006: Existing no-vocabulary behavior

Source: `benchmark/PROBLEM.md`

Evidence: `CountVectorizer().transform(corpus)` raises "`Vocabulary wasn't fitted.`"

Obligation: No-constructor-vocabulary, unfitted vectorizers remain not fitted for vocabulary-dependent operations.

Encoded in: PO-003.

## E-007: Source compatibility evidence

Source: `repo/sklearn` source search excluding tests

Evidence: `TfidfVectorizer` subclasses `CountVectorizer` and does not override `get_feature_names`; `pipeline.py` calls `trans.get_feature_names()` without arguments.

Obligation: Keep the zero-argument method signature and return shape.

Encoded in: PO-005.

