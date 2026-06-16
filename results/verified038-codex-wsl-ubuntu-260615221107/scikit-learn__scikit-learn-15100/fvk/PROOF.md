# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## Claims

The formal claims are written in `fvk/strip-accents-unicode-spec.k` over the mini semantics in `fvk/mini-python-unicode.k`.

Main claim:

For every in-domain Unicode string `S`, `strip_accents_unicode(S)` reaches a result equal to `removeCombining(nfkd(S))`.

Example claims:

- `strip_accents_unicode(precomposedNTilde())` reaches `plainN()`.
- `strip_accents_unicode(decomposedNTilde())` reaches `plainN()`.
- The already-NFKD decomposed input is filtered, not returned unchanged.

## Proof Sketch

1. Start with any Python string `S` satisfying O-1.
2. The source executes `normalized = unicodedata.normalize('NFKD', s)`, giving `N = nfkd(S)` by the mini semantics. This discharges O-2.
3. The next and only return expression traverses `N` and joins exactly those code points `C` where `unicodedata.combining(C)` is false. By the abstract `removeCombining` semantics, the result is `removeCombining(N)`. This discharges O-3 and O-5.
4. There is no branch on `N == S`. Therefore the proof path is identical when `S` is already NFKD-normalized. This discharges O-4.
5. For the issue examples, both `nfkd(precomposedNTilde())` and `nfkd(decomposedNTilde())` are `decomposedNTilde()`, and `removeCombining(decomposedNTilde())` is `plainN()`. This discharges O-6.
6. Source inspection shows no signature or dispatch change. This discharges O-7.

The legacy implementation would fail step 4: under `S = decomposedNTilde()`, `nfkd(S) == S`, and the old early return would produce `decomposedNTilde()` instead of `plainN()`.

## Verification Conditions

VC-1: `normalize('NFKD', S)` is evaluated before filtering.

- Source evidence: assignment to `normalized` before the return expression.
- Status: discharged by source shape and mini semantics.

VC-2: The filter removes all and only combining code points from `nfkd(S)`.

- Source evidence: list-comprehension predicate `not unicodedata.combining(c)`.
- Status: discharged by `removeCombining` abstraction; trusted base includes Python `unicodedata.combining`.

VC-3: Already-normalized strings are not exempt from VC-2.

- Source evidence: no `if normalized == s` branch remains.
- Status: discharged by source shape.

VC-4: Precomposed and decomposed n-with-tilde collapse to the same stripped result.

- Source evidence: public issue expected result.
- Status: discharged by the Unicode axioms in the spec file.

## Adequacy Gate

The English formal claims in `fvk/FORMAL_SPEC_ENGLISH.md` match the intent-only obligations in `fvk/INTENT_SPEC.md`. `fvk/SPEC_AUDIT.md` marks all required obligations pass. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records no unhandled public callsite or signature change.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They were not run.

```sh
kompile fvk/mini-python-unicode.k --backend haskell
kast --backend haskell fvk/strip-accents-unicode-spec.k
kprove fvk/strip-accents-unicode-spec.k
```

Expected result after any syntax adjustments required by a local K installation: `#Top` for the claims.

## Test Redundancy Recommendation

Recommendation only, conditioned on successful machine checking. Do not delete tests in this benchmark task.

- Existing direct tests for precomposed Latin/Arabic accent stripping are covered by O-3/O-5 when in domain, but should be kept until the K claims are actually machine-checked.
- Integration tests for vectorizer analyzers should be kept because the proof target is the helper and dispatch compatibility, not the full tokenization pipeline.
- A decomposed n-with-tilde regression test should be added in a normal development setting; it is omitted here because test files are fixed.

## Residual Risk

The proof is partial correctness and constructed only. Its trusted base includes the adequacy of the mini Unicode model, Python string finiteness, and the standard behavior of `unicodedata.normalize` and `unicodedata.combining`. It does not prove performance, object identity preservation, or behavior for non-string inputs.

