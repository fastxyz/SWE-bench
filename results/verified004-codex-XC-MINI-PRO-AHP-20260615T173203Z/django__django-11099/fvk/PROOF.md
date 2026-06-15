# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were executed.

## What Is Proved

For the audited username validators:

- `ASCIIUsernameValidator` accepts exactly non-empty strings composed of ASCII word characters plus `.`, `@`, `+`, and `-`.
- `UnicodeUsernameValidator` accepts exactly non-empty strings composed of Unicode word characters plus `.`, `@`, `+`, and `-`.
- Both validators reject an otherwise valid username with a final `\n`.

The proof is partial correctness over the regex matching decision. There is no loop or recursion in the production code under audit, so termination is not a substantive proof obligation.

## Proof Sketch

1. `RegexValidator.__call__()` calls `self.regex.search(str(value))`. Therefore validation succeeds exactly when the compiled regex can find a match in the string.
2. In V1, both username validators use `r'\A[\w.@+-]+\Z'`.
3. `\A` can match only at absolute string start. This removes any later search start position.
4. `[\w.@+-]+` consumes one or more allowed characters. It cannot consume LF, CR, space, apostrophe, zero-width space, non-breaking space, en dash, or any other character outside the modeled allowed family.
5. `\Z` can match only at the absolute string end. This removes the pre-V1 `$` behavior where a match ending just before one final `\n` could still succeed.
6. Therefore an otherwise valid string followed by `\n` cannot match: the repetition stops before `\n`, and `\Z` is false at that position.
7. The unchanged `flags = re.ASCII` and `flags = 0` preserve the ASCII versus Unicode distinction for `\w`.

## K Claim Discharge

The mini semantics models character-category lists and the validator decision function:

- `fullMatch(V, .Chars) => false` models the `+` repetition requirement.
- `fullMatch(V, cons(C, REST)) => allowed(V, C) andBool allAllowed(V, REST)` models whole-string consumption.
- `appendLF(CS)` appends the LF category at the true end of the list.

For `ASCII_ACCEPT` and `UNICODE_ACCEPT`, symbolic simplification of `fullMatch()` under the precondition `CS =/=K .Chars andBool allAllowed(V, CS)` reaches `valid`.

For `ASCII_REJECT` and `UNICODE_REJECT`, symbolic simplification under the negated accepted-language precondition reaches `invalid`.

For `ASCII_REJECT_TRAILING_LF` and `UNICODE_REJECT_TRAILING_LF`, the `fullMatch(V, appendLF(CS)) => false` simplification lemma captures the recursive fact that appending LF makes the whole-string username predicate false. Since `validate()` returns `invalid` whenever `fullMatch()` is false, both trailing-LF claims reach `invalid`.

## Adequacy

The adequacy gate passes:

- `FORMAL_SPEC_ENGLISH.md` says exactly the intended allowed-language and trailing-newline behavior.
- `SPEC_AUDIT.md` marks all claims PASS against `INTENT_SPEC.md`.
- `PUBLIC_COMPATIBILITY_AUDIT.md` finds no unhandled public callsite, override, or signature change.

## Test Recommendation

No tests were removed or edited. If the K commands later machine-check to `#Top`, unit tests that only assert representative valid and invalid username character examples would be subsumed by the proven language contract. Integration tests, public API compatibility tests, and any tests outside this exact validator-language domain should remain.

The current task forbids modifying tests. A useful public test addition in a normal development setting would assert that both username validators reject `validname\n`.

## Machine-Check Commands

Recorded only. Not run in this benchmark session.

```sh
cd fvk
kompile mini-python-regex.k --backend haskell
kast --backend haskell username-validator-spec.k
kprove username-validator-spec.k
```

Expected machine-check result after a valid K run: `#Top` for all claims.

## Residual Risk

The proof uses a mini semantics for the regex language fragment rather than a full Python-in-K semantics. The abstraction is adequate for the issue because it keeps the relevant pass/fail axis visible: allowed characters, disallowed characters, non-empty repetition, absolute start, absolute end, and LF are distinct. The proof remains constructed, not machine-checked, until K tooling is run outside this no-execution environment.
