# Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Claims proved in the constructed model

The formal claims are in `fvk/count-vectorizer-spec.k`; the supporting mini semantics is in `fvk/mini-python-count-vectorizer.k`.

PO-001 proves the reported fixed-vocabulary case: if `vocabulary_` is absent and `self.vocabulary` is valid and non-empty, `getFeatureNames` rewrites to `maybeValidate ~> checkVocabulary ~> returnFeatureNames`. `maybeValidate` invokes `validateVocabulary`; validation stores `normalizeVocab(P)` as `vocabulary`, marks fixed-vocabulary state, and returns to the sequence. `checkVocabulary` then succeeds because the vocabulary is present and non-empty. `returnFeatureNames` stores `featureList(orderByIndex(normalizeVocab(P)))` with no exception.

PO-002 proves the already-materialized case: if `has-vocabulary` is true and the map is non-empty, `maybeValidate` is a no-op, `checkVocabulary` succeeds, and `returnFeatureNames` returns `orderByIndex(V)`.

PO-003 proves the no-constructor-vocabulary boundary: if no vocabulary exists and the constructor parameter is `noneVocab`, `validateVocabulary` does not create a vocabulary, so `checkVocabulary` reaches `raise(notFittedError)`. The result remains `noResult`.

PO-004 proves validation preservation: if the constructor vocabulary is invalid or normalizes to empty, `validateVocabulary` reaches `raise(valueError)`, and no feature-name result is produced.

There are no loops or recursive calls on this path, so no circularity claims are required. The proof is a straight symbolic execution over conditionals and helper calls.

## Verification conditions

VC-001: For PO-001, `P != noneVocab`, `validVocab(P)`, and `not emptyVocab(normalizeVocab(P))` imply the validation-success rule fires before `_check_vocabulary`.

VC-002: For PO-001 and PO-002, `not emptyVocab(V)` implies `checkVocabulary` cannot raise `ValueError` and reaches `returnFeatureNames`.

VC-003: For PO-003, `noneVocab` and absent `vocabulary_` imply validation does not create `vocabulary_`, so `checkVocabulary` raises `notFittedError`.

VC-004: For PO-004, invalid or empty constructor vocabulary implies validation raises `valueError` before `_check_vocabulary` can return feature names.

VC-005: The result expression `orderByIndex(V)` matches the source return expression `sorted(six.iteritems(self.vocabulary_), key=itemgetter(1))` projected to terms.

## Adequacy result

`fvk/SPEC_AUDIT.md` marks all formal paraphrases as passing against `fvk/INTENT_SPEC.md`. No claim is supported only by candidate behavior; each normative claim is traced to public issue text, source docstrings, or compatibility evidence in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Commands not executed

These are the exact commands to run in a future environment with K installed:

```sh
kompile fvk/mini-python-count-vectorizer.k --backend haskell
kast --backend haskell fvk/count-vectorizer-spec.k
kprove fvk/count-vectorizer-spec.k
```

Expected machine-check result after the constructed proof is encoded correctly: `#Top`.

## Test recommendation

No tests were read, modified, or run. Because the proof is constructed but not machine-checked, no test removal is recommended. Keep all tests until the K commands above discharge and ordinary project tests pass in a real execution environment.

