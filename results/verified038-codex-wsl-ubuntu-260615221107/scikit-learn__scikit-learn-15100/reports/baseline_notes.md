# Baseline Notes

## Root cause

`strip_accents_unicode` normalized input with `unicodedata.normalize('NFKD', s)` and then returned the original string unchanged when normalization did not alter the input. That shortcut is incorrect because text that is already in NFKD form can still contain combining marks, such as `n` followed by a combining tilde. In that case normalization is a no-op, but the combining mark still needs to be removed.

## Changed files

`repo/sklearn/feature_extraction/text.py`

- Removed the `normalized == s` early return from `strip_accents_unicode`.
- The function now always filters combining characters after NFKD normalization, so both precomposed accented characters and already-decomposed accented sequences are handled consistently.

## Assumptions

- The intended behavior of `strip_accents_unicode` is to remove accent marks from all Unicode inputs after NFKD normalization, including inputs that are already normalized.
- Returning a newly joined string with the same contents for already-normalized, accent-free input is acceptable; callers should depend on string value, not object identity.
- No test files were modified because the benchmark instructions require the fixed test suite to remain unchanged.

## Alternatives considered

- Add a special branch that checks for combining characters only when `normalized == s`. I rejected this because it keeps unnecessary branching and duplicates the filtering decision.
- Preserve the early return for performance on already-normalized strings. I rejected this because the branch is the direct source of the bug and cannot distinguish accent-free NFKD text from NFKD text that still contains combining marks.
