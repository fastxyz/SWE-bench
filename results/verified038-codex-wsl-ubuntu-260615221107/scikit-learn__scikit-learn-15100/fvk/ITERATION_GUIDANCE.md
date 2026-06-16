# FVK Iteration Guidance

Status: V1 stands. No further production source edit is justified by the FVK audit.

## Decision

Keep `repo/sklearn/feature_extraction/text.py::strip_accents_unicode` as V1:

```python
normalized = unicodedata.normalize('NFKD', s)
return ''.join([c for c in normalized if not unicodedata.combining(c)])
```

This satisfies F-001 and F-002 by discharging O-2, O-3, O-4, O-5, and O-6.

## Do Not Regress

- Do not reintroduce `if normalized == s: return s`; F-003 explains why that optimization conflicts with O-4.
- If a future performance optimization is needed, it must still prove O-3 for already-NFKD inputs with combining marks.
- Do not change public signature or vectorizer dispatch without a new compatibility audit; O-7 is currently discharged because they are unchanged.

## Recommended Tests Outside This Benchmark

Do not edit tests in this task. In a normal development flow, add:

- `strip_accents_unicode(chr(110) + chr(771)) == chr(110)`.
- A vectorizer preprocessing case with `strip_accents='unicode'` and decomposed accented input.

These map to F-005 and O-8.

## Machine Check Later

When an execution environment with K is available, run:

```sh
kompile fvk/mini-python-unicode.k --backend haskell
kast --backend haskell fvk/strip-accents-unicode-spec.k
kprove fvk/strip-accents-unicode-spec.k
```

Keep test-removal recommendations conditional on `kprove` returning `#Top`.

