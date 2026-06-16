# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `CountVectorizer.get_feature_names()` in `repo/sklearn/feature_extraction/text.py`, including the helper behavior it relies on in `_validate_vocabulary()` and `_check_vocabulary()`. It does not attempt to verify all of scikit-learn.

## Intent summary

The public issue says that an unfitted `CountVectorizer` with a valid constructor `vocabulary` can already use `transform()` because `transform()` calls `_validate_vocabulary()` and creates `vocabulary_`. The requested behavior is that `get_feature_names()` should support the same fixed-vocabulary case and not raise `NotFittedError`.

## Public intent ledger

- E-001: A supplied constructor vocabulary is enough state for vocabulary-dependent operations that do not require corpus fitting.
- E-002: `NotFittedError` from `get_feature_names()` on a valid fixed vocabulary is the reported bug.
- E-003: The intended repair direction is to use the same lazy validation/materialization path as `transform()`.
- E-004: Existing vocabulary validation rules still apply: valid vocabularies are non-empty, unique, and gapless by feature index.
- E-005: `get_feature_names()` returns the array/list of feature names ordered by feature integer index.
- E-006: Without a constructor vocabulary and without fitting, a vectorizer remains not fitted.
- E-007: Public compatibility requires preserving the no-argument method signature.

The full ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Formal model

The formal core is intentionally small:

- `fvk/mini-python-count-vectorizer.k` models only the observable state needed for this issue: constructor vocabulary, whether `vocabulary_` exists, the stored vocabulary map, fixed-vocabulary state, result, and exception.
- `fvk/count-vectorizer-spec.k` states four reachability claims for the relevant branches of `get_feature_names()`.

There are no loops in the audited code path, so there are no loop circularities.

## Function contract

For every valid, non-empty constructor vocabulary `P`, if `vocabulary_` is absent when `get_feature_names()` is called, the method must:

1. run the same vocabulary normalization/validation path used by `transform()`;
2. create `vocabulary_ = normalize(P)`;
3. mark the vocabulary as fixed;
4. return `orderByIndex(normalize(P))`;
5. raise no exception.

For already materialized vocabularies, it must return `orderByIndex(vocabulary_)`.

For unfitted vectorizers without a constructor vocabulary, it must raise `NotFittedError`.

For invalid or empty constructor vocabularies, it must raise `ValueError` through the existing validation path.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `fvk/SPEC_AUDIT.md` compares those paraphrases against `fvk/INTENT_SPEC.md`; all entries pass. The proof remains constructed, not machine-checked.

