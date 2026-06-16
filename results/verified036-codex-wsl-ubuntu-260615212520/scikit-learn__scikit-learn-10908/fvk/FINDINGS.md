# Findings

Status: constructed, not machine-checked.

## F-001: Original fixed-vocabulary defect is resolved

Classification: code bug found in pre-V1, resolved by V1.

Input -> observed vs expected:

- Input: `CountVectorizer(vocabulary=['and', 'document', 'first']).get_feature_names()` before fitting.
- Pre-V1 observed: `NotFittedError`, because `get_feature_names()` called `_check_vocabulary()` before any lazy materialization.
- Expected: feature names ordered by vocabulary index, with no `NotFittedError`.
- V1 observed by static proof: `_validate_vocabulary()` runs first when `vocabulary_` is absent, creates `vocabulary_`, then `_check_vocabulary()` succeeds.

Related obligations: PO-001.

Recommended action: keep V1 behavior.

## F-002: Existing fitted/materialized behavior is preserved

Classification: compatibility and frame condition, resolved.

Input -> observed vs expected:

- Input: a vectorizer whose `vocabulary_` already exists.
- Expected: return names ordered by integer feature index.
- V1 static proof: the added guard is skipped, so the previous `_check_vocabulary()` and sorted return path are unchanged.

Related obligations: PO-002.

Recommended action: no code change.

## F-003: No-vocabulary unfitted behavior remains NotFittedError

Classification: boundary behavior, resolved.

Input -> observed vs expected:

- Input: `CountVectorizer()` with no constructor vocabulary and no fitting.
- Expected: `NotFittedError`, not a feature-name list.
- V1 static proof: `_validate_vocabulary()` does not create `vocabulary_` for `self.vocabulary is None`; `_check_vocabulary()` raises the existing fittedness error.

Related obligations: PO-003.

Recommended action: no code change. The proof does not rely on any public guarantee about `fixed_vocabulary_` side effects on this error path.

## F-004: Invalid constructor vocabularies still use existing validation errors

Classification: validation behavior, resolved.

Input -> observed vs expected:

- Input: empty vocabulary, duplicate terms, repeated mapping indices, or index gaps.
- Expected: existing `ValueError` validation behavior.
- V1 static proof: `get_feature_names()` now reaches `_validate_vocabulary()` for these unfitted fixed-vocabulary inputs, so invalid vocabularies are rejected by the same helper used by `transform()` and `fit_transform()`.

Related obligations: PO-004.

Recommended action: no code change.

## F-005: Public compatibility has no unresolved issue

Classification: API compatibility, resolved.

Input -> observed vs expected:

- Input: public source callers invoking `get_feature_names()` without arguments, including inherited use by `TfidfVectorizer`.
- Expected: same signature and list-like feature-name result.
- V1 static proof: method signature and return expression are unchanged.

Related obligations: PO-005.

Recommended action: no code change.

## F-006: Proof is constructed, not machine-checked

Classification: proof process limitation.

The K semantics, claims, and proof were constructed but not run through `kompile`, `kast`, or `kprove`, per task constraints. No tests or Python code were executed.

Related obligations: all.

Recommended action: keep tests. If a future environment permits it, run the commands in `fvk/PROOF.md` and require `kprove` to return `#Top` before treating tests as proof-redundant.

