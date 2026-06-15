# FVK Spec

Status: constructed, not machine-checked. This audit covers the V1 fix currently in `repo/django/contrib/auth/validators.py`.

## Target

The audited public symbols are:

- `django.contrib.auth.validators.ASCIIUsernameValidator`
- `django.contrib.auth.validators.UnicodeUsernameValidator`

Both inherit `django.core.validators.RegexValidator.__call__()`, which evaluates `self.regex.search(str(value))` and raises `ValidationError` when no match exists.

## Intended Contract

For the string value passed to the regex engine after `str(value)`:

- `ASCIIUsernameValidator` accepts exactly non-empty strings whose characters are ASCII word characters or `.`, `@`, `+`, `-`.
- `UnicodeUsernameValidator` accepts exactly non-empty strings whose characters are Unicode word characters or `.`, `@`, `+`, `-`.
- Both validators reject strings with any other character, including a trailing `\n`.
- Both validators validate the whole string, not a prefix.

The existing error messages, class names, constructor behavior, deconstructible class shape, and flags are frame conditions.

## Public Intent Ledger

The standalone ledger is `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries mirrored here:

- E-001: The issue says the intent is "to only allow alphanumeric characters as well as ., @, +, and -." This supplies the allowed-character postcondition.
- E-002: The issue says `$` matches a trailing newline and therefore usernames ending with newline are accepted. This supplies the concrete rejected boundary case.
- E-003: The issue proposes `r'\A[\w.@+-]+\Z'`. This supplies the absolute-anchor repair.
- E-005/E-006: Django docs describe the ASCII and Unicode validator character families and support the existing `re.ASCII` versus Unicode flag split.
- E-007: `RegexValidator.__call__()` uses `search(str(value))`. This implementation fact makes full-string anchors necessary for prefix rejection.

## Formal Model

The mini semantics in `fvk/mini-python-regex.k` models the exact property under audit: whether a username string is accepted or rejected by an anchored username regex. It abstracts concrete Unicode code points into character categories but preserves the discriminator required by the issue:

- A passing instance, `cons(asciiWord, .Chars)`, is accepted.
- The corresponding failing instance, `appendLF(cons(asciiWord, .Chars))`, is rejected.

This abstraction is property-complete for the issue because newline, ASCII word, Unicode word, documented punctuation, and disallowed characters remain distinguishable.

## Claims

The K claims are in `fvk/username-validator-spec.k`:

- `ASCII_ACCEPT`: all non-empty ASCII-allowed character lists validate.
- `ASCII_REJECT`: empty or not-all-ASCII-allowed character lists fail.
- `ASCII_REJECT_TRAILING_LF`: appending final LF to an otherwise valid ASCII username fails.
- `UNICODE_ACCEPT`: all non-empty Unicode-allowed character lists validate.
- `UNICODE_REJECT`: empty or not-all-Unicode-allowed character lists fail.
- `UNICODE_REJECT_TRAILING_LF`: appending final LF to an otherwise valid Unicode username fails.

## V1 Mapping

V1 sets both validator regexes to `r'\A[\w.@+-]+\Z'`. With `RegexValidator.search(str(value))`, `\A` prevents the search from starting after the beginning, `[\w.@+-]+` consumes one or more allowed characters, and `\Z` requires the match to end at the true end of the string. A trailing newline is not an allowed character and can no longer be skipped by `$`.

The ASCII and Unicode differences are preserved by the unchanged `flags = re.ASCII` and `flags = 0`.
