# FVK Findings

Status: constructed, not machine-checked.

## F-001: Boost wrapper hid phrase slop from the helper

Classification: code bug in the pre-V1 implementation, resolved by V1.

Input: abstract query `boost(phrase("hello world", 0), "1.5")` with requested slop `1`, corresponding
to the issue's `MultiFieldQueryParser(fields, analyzer, boosts).parse("\"hello world\"~1")`.

Observed before V1: the boost wrapper reached `applySlop`, but the helper only recognized
`PhraseQuery` and `MultiPhraseQuery`, so it returned the boosted query with the inner phrase slop
unchanged. This matches the issue's output with the slop missing.

Expected: `boost(phrase("hello world", 1), "1.5")`, corresponding to output that contains both
`~1` and `^1.5`.

Evidence: intent ledger I-001, I-002, I-003. Proof obligations PO-003 and PO-005.

Resolution: V1 adds the `BoostQuery` case in `applySlop`, recursively applies the existing slop logic
to the wrapped query, and rewraps the result with the original boost.

## F-002: V1 covers the sibling MultiPhraseQuery wrapper case

Classification: completeness check, resolved by V1.

Input: abstract query `boost(multiPhrase("synonym phrase", 0), "2.0")` with requested slop `3`.

Observed before V1: a `BoostQuery` wrapped around `MultiPhraseQuery` would bypass the existing
`MultiPhraseQuery` slop branch for the same reason as F-001.

Expected: `boost(multiPhrase("synonym phrase", 3), "2.0")`.

Evidence: source behavior in intent ledger I-004 and wrapper transparency from I-003. Proof
obligations PO-002 and PO-003.

Resolution: V1's recursive `BoostQuery` branch delegates to the existing `MultiPhraseQuery` branch,
so the sibling case is covered without a separate code path.

## F-003: No additional source change is justified by the FVK audit

Classification: confirmation of V1 against the specified obligations.

Input family: null query, non-phrase query, direct phrase, direct multi-phrase, boosted phrase,
boosted multi-phrase, and boosted non-phrase.

Observed in V1 by static inspection: direct phrase and multi-phrase behavior is unchanged; boosted
phrase-like queries are unwrapped and rewrapped; null and non-phrase inputs remain structurally
unchanged except for equivalent reconstruction of a `BoostQuery` wrapper when already boosted.

Expected: exactly the behavior in SPEC-C-001 through SPEC-C-006.

Evidence: proof obligations PO-001 through PO-008.

Resolution: V1 stands unchanged. No test files were edited, and no command execution was attempted.

## F-004: Proof is constructed but not machine-checked

Classification: proof capability and environment limitation, not a source-code bug.

Input: the K artifacts and claims in `fvk/mini-queryparser.k` and
`fvk/multifield-queryparser-spec.k`.

Observed: this benchmark forbids running K tooling, tests, Python, or project code.

Expected: artifacts include exact commands for later machine checking, but no claim is represented
as actually proved by `kprove` in this run.

Evidence: task no-exec instruction and proof obligations PO-009/PO-010.

Resolution: retain the "constructed, not machine-checked" caveat. Do not remove tests based on this
proof until the emitted commands are run in a suitable environment.
