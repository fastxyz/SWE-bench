# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Accepted-language equivalence

For each validator, prove that a username is accepted iff it is non-empty and every character belongs to that validator's allowed character family.

Evidence: E-001, E-005, E-006.

Formal claims: `ASCII_ACCEPT`, `ASCII_REJECT`, `UNICODE_ACCEPT`, `UNICODE_REJECT`.

## PO-002: Trailing newline rejection

For both validators, prove that appending `\n` to an otherwise valid username makes the value invalid.

Evidence: E-002, E-003.

Formal claims: `ASCII_REJECT_TRAILING_LF`, `UNICODE_REJECT_TRAILING_LF`.

## PO-003: Anchor and `search()` interaction

Prove that, under `RegexValidator.search(str(value))`, the fixed regex validates the whole string: `\A` prevents later start positions and `\Z` prevents `$`-style matching before a final newline.

Evidence: E-003, E-007, E-010.

Formal support: `fullMatch()` in `mini-python-regex.k` and all six validator claims.

## PO-004: ASCII flag preservation

Prove that the ASCII validator remains stricter than the Unicode validator for non-ASCII word characters.

Evidence: E-005, E-008, public tests with `Eric` using an accented first character as invalid for ASCII.

Formal support: `allowed(asciiUsername, unicodeWord) => false`.

## PO-005: Unicode flag preservation

Prove that the Unicode validator continues to allow Unicode word characters while still rejecting disallowed separators and newline.

Evidence: E-006, E-008, public tests with Arabic and accented names as valid for Unicode.

Formal support: `allowed(unicodeUsername, unicodeWord) => true` plus Unicode reject claims.

## PO-006: Public compatibility

Prove or audit that the repair changes only the accepted language required by the bug report, not public API shape.

Evidence: E-004, docs for `username_validator`, model use in `AbstractUser`, migrations importing validator classes.

Artifact: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-007: Honesty gate

Record that the proof is constructed but not machine-checked, and do not delete tests or claim `kprove` success.

Evidence: FVK docs and benchmark no-execution constraint.

Artifact: `fvk/PROOF.md` commands section and PF-001.

## Commands To Machine-Check Later

These commands are recorded only. They were not run.

```sh
cd fvk
kompile mini-python-regex.k --backend haskell
kast --backend haskell username-validator-spec.k
kprove username-validator-spec.k
```
