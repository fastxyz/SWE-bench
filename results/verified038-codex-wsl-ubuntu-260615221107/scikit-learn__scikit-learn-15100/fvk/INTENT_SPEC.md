# Intent-Only Specification

Current implementation behavior is not used as expected behavior in this file.

1. `strip_accents_unicode` accepts Python strings and strips accents from Unicode text.
2. The Unicode strategy uses NFKD normalization.
3. Combining marks must be removed after NFKD normalization, even when the input was already in NFKD form.
4. Precomposed `chr(241)` and decomposed `chr(110) + chr(771)` must both return `chr(110)`.
5. Vectorizer preprocessing with `strip_accents='unicode'` must keep using the same public helper behavior.
6. The task forbids modifying test files.

