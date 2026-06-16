# FVK Proof Obligations

Status: constructed, not machine-checked.

## O-1: String-domain precondition

For every audited call, `s` is a Python `str`.

Provenance: E5 and parameter documentation.

Status: discharged for the issue domain. Non-string behavior is outside scope.

## O-2: Unconditional NFKD normalization

The implementation must compute `normalized = unicodedata.normalize('NFKD', s)` for every in-domain input.

Provenance: E1, E4, E6.

Status: discharged by `repo/sklearn/feature_extraction/text.py`.

## O-3: Unconditional combining-character filtering

The returned string must be `''.join(c for c in normalized if not unicodedata.combining(c))`, where `normalized` is the NFKD form of `s`.

Provenance: E1, E4, E5, E6.

Status: discharged by the current source.

## O-4: Already-NFKD inputs are still filtered

If `unicodedata.normalize('NFKD', s) == s`, the implementation must still apply O-3 rather than returning `s` merely because normalization was a no-op.

Provenance: E1, E3.

Status: discharged by removal of the early return.

## O-5: Non-combining code points are preserved in order

Every code point from `normalized` with combining class zero appears exactly once in the result and in the same relative order; no combining code point from `normalized` appears.

Provenance: E5, E6, E7.

Status: discharged by the list-comprehension filter and `join` shape.

## O-6: Precomposed/decomposed n-with-tilde equivalence

For `s1 = chr(241)` and `s2 = chr(110) + chr(771)`, both calls must return `chr(110)`.

Provenance: E2.

Status: discharged by O-2 through O-5.

## O-7: Public compatibility

The fix must not change the public function name, public signature, or vectorizer dispatch for `strip_accents='unicode'`.

Provenance: E8.

Status: discharged. The function remains one-argument, and `build_preprocessor` still selects it for `'unicode'`.

## O-8: No test file edits

The repair must not modify test files in this benchmark run.

Provenance: user instruction and F-005.

Status: discharged. No test files were changed.

## O-9: Honesty gate

The proof artifacts must be labeled constructed, not machine-checked, because no K commands were run.

Provenance: FVK `verify.md` honesty gate and user instruction not to run K tooling.

Status: discharged by artifact labeling and by listing commands only.

## O-10: FVK artifact completeness

The FVK audit must include the requested five artifacts plus the formal-core and adequacy artifacts required by the FVK docs.

Provenance: F-006 and FVK `AGENTS.md` non-negotiable artifact contract.

Status: discharged by the files under `fvk/`.
