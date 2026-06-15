# Intent Spec

Status: constructed from public evidence only. Current implementation behavior is recorded only as a candidate to check.

## Required Behavior

I-001: `ASCIIUsernameValidator` accepts a non-empty username only when every character is an ASCII word character or one of `.`, `@`, `+`, `-`.

I-002: `UnicodeUsernameValidator` accepts a non-empty username only when every character is a Unicode word character or one of `.`, `@`, `+`, `-`.

I-003: Both validators reject any username containing a newline character, including a final `\n`.

I-004: Both validators must validate the whole username string. A valid prefix followed by a disallowed trailing character is invalid.

I-005: The fix is scoped to `ASCIIUsernameValidator` and `UnicodeUsernameValidator` in `django.contrib.auth.validators`; public class names, messages, flags, constructor shape, and integration with `RegexValidator` should remain compatible.

I-006: The username validator domain is the string value being validated. Django's inherited `RegexValidator.__call__()` converts the input with `str(value)` before matching; this audit specifies behavior over that resulting string.

## Default-Domain Assumptions

D-001: Python regular-expression `\A` matches only the absolute start of the string and `\Z` matches only the absolute end of the string.

D-002: Python regular-expression `+` requires one or more repetitions, so the empty string is not accepted by either username validator.

D-003: With `re.ASCII`, `\w` is restricted to ASCII word characters. With flags `0`, `\w` follows Python's Unicode word-character behavior.
