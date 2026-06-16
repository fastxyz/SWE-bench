# Formal Spec in English

Paraphrase of `fvk/strip-accents-unicode-spec.k`.

1. For any Unicode string `S`, running `strip_accents_unicode(S)` terminates with result `removeCombining(nfkd(S))`.
2. `removeCombining(nfkd(S))` is the NFKD-normalized string with every combining code point removed and every non-combining code point preserved in order.
3. `precomposedNTilde()` normalizes to `decomposedNTilde()`.
4. `decomposedNTilde()` is already NFKD-normalized.
5. Removing combining marks from `decomposedNTilde()` yields `plainN()`.
6. Therefore both issue inputs, precomposed and decomposed n-with-tilde, yield `plainN()`.
7. There is no claim that non-string inputs are handled, no claim about object identity, and no machine-checked claim about performance.

