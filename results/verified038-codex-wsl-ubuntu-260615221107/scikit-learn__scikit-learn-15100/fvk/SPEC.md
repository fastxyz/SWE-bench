# FVK Specification: `strip_accents_unicode`

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited production unit is `repo/sklearn/feature_extraction/text.py::strip_accents_unicode`, as used directly and through `strip_accents='unicode'` in vectorizer preprocessing. The function has no explicit loop; the list comprehension is modeled as an abstract finite string filter over Unicode code points.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "`strip_accents=\"unicode\"` ... does not work ... if those strings are already in NFKD form" | Already-NFKD strings are in domain and must still have accents removed. | Encoded by O-4. |
| E2 | problem | "`s1` and `s2` should both be normalized to the same string, `\"n\"`" | Precomposed `chr(241)` and decomposed `chr(110) + chr(771)` must both return `"n"`. | Encoded by O-6. |
| E3 | problem | "`s2` is not changed, because ... does nothing if the string is already in NFKD form" | The old `normalized == s` early return is suspect legacy behavior, not a contract. | Finding F-001. |
| E4 | public hint | "remove the `if` branch from `strip_accents_unicode`" | The fix may unconditionally filter combining characters after normalization. | Encoded by O-2/O-3. |
| E5 | docstring | "Transform accentuated unicode symbols into their simple counterpart" | Accent marks should be removed from Unicode text, not only from precomposed characters. | Encoded by O-3/O-5. |
| E6 | API docs | "`unicode` is a slightly slower method that works on any characters" and both modes use NFKD normalization | The Unicode mode contract is broad Unicode handling using NFKD. | Encoded by O-1/O-3. |
| E7 | public tests | Existing tests expect Latin and Arabic accented characters to lose marks. | Precomposed/non-decomposed behavior must remain unchanged. | Encoded by O-5/O-6. |
| E8 | implementation/API | `build_preprocessor` dispatches `'unicode'` to `strip_accents_unicode`; no signature changed. | Public API and vectorizer call path must stay compatible. | Encoded by O-7. |

## Contract

Precondition: input `s` is a Python `str`. Non-string behavior is outside this helper's public contract; the documented parameter is a string.

Let:

- `N = unicodedata.normalize('NFKD', s)`.
- `combining(c)` mean `unicodedata.combining(c) != 0`.
- `filter_non_combining(N)` mean the finite sequence of code points from `N` for which `combining(c)` is false, preserving original order.

Postcondition:

`strip_accents_unicode(s) == ''.join(filter_non_combining(N))`.

Consequences:

- The result contains no combining code point from `N`.
- Every non-combining code point from `N` appears exactly once in the same relative order.
- If `s` is already NFKD-normalized, the same filter still applies.
- For `s1 = chr(241)` and `s2 = chr(110) + chr(771)`, both results are `chr(110)`.

Frame conditions:

- The public function name and one-argument signature are unchanged.
- `strip_accents='unicode'` in vectorizers continues to route through this helper.
- `strip_accents_ascii` and unrelated preprocessing/tokenization behavior are out of scope and unchanged.

## Formal Core

Formal artifacts:

- `fvk/mini-python-unicode.k`
- `fvk/strip-accents-unicode-spec.k`

The mini semantics abstracts Python Unicode library behavior through `nfkd`, `isCombining`, and `removeCombining`. This is intentionally property-complete for the audited defect: it distinguishes the passing implementation `removeCombining(nfkd(S))` from the failing legacy branch that returns `S` whenever `nfkd(S) == S`.

