# SPEC

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Target

`django.core.validators.URLValidator.__call__(value)` in `repo/django/core/validators.py`.

The audited V1 source change is:

- `URLValidator.unsafe_chars = frozenset('\t\r\n')`
- `__call__()` raises `ValidationError` if a string value contains any of those characters, before scheme parsing, regex validation, `urlsplit()`, or IDN fallback.

## Intent-only obligations

I-001. `URLValidator` rejects values that do not look like URLs.

I-002. Literal IPv6 addresses and Unicode domains remain supported for otherwise valid URLs.

I-003. A URL containing LF, CR, or tab is invalid input to `URLValidator`; those characters must not be silently removed by Python URL parsing and then accepted.

I-004. The `schemes` constructor/API behavior remains unchanged.

I-005. Form and model URL fields that use `URLValidator()` as a default validator must keep using the same public validator call shape.

## Public evidence ledger

E-001. Source: docs. Quote: "`URLValidator` ... ensures a value looks like a URL, and raises an error code of `'invalid'` if it doesn't." Semantic obligation: invalid-looking URL strings raise `ValidationError`. Status: encoded in claims C-UNSAFE, C-BAD-SCHEME, C-REGEX-REJECT, C-HOST-REJECT.

E-002. Source: docs. Quote: "Literal IPv6 addresses ... and Unicode domains are both supported." Semantic obligation: the fix must not remove the regex/IPv6/IDN fallback behavior for inputs without unsafe characters. Status: encoded as frame condition C-NO-UNSAFE-FRAME and compatibility obligation PO-005.

E-003. Source: public issue. Quote: "bpo-43882 fix changes URL splitting behavior to strip all instances of LF, CR and tab characters before splitting, so they never reach the validator." Semantic obligation: LF, CR, and tab form the complete public unsafe-character family for this issue. Status: encoded in C-UNSAFE and PO-003.

E-004. Source: public issue. Quote: test failures where `value='http://www.djangoproject.com/\n'` and `value='http://[::ffff:192.9.5.5]\n'` did not raise `ValidationError`. Semantic obligation: those newline-containing values must raise. Status: covered by C-UNSAFE because LF is in the unsafe family.

E-005. Source: public test evidence. Quote: comment "Trailing newlines not accepted" before the same two `URLValidator()` cases. Semantic obligation: trailing newline rejection is intended, not a legacy behavior to preserve as acceptance. Status: encoded in C-UNSAFE.

E-006. Source: code/API. Quote: `class URLValidator(RegexValidator)` and docs signature `URLValidator(schemes=None, regex=None, message=None, code=None)`. Semantic obligation: do not change constructor signature or inherited customization arguments. Status: compatibility audit passed; no signature change.

E-007. Source: code/callsites. Quote: `django/forms/fields.py` and `django/db/models/fields/__init__.py` both use `default_validators = [validators.URLValidator()]`. Semantic obligation: the fix must keep `URLValidator()` callable without new arguments and preserve the default-validator shape. Status: compatibility audit passed.

## In-domain behavior classes

The spec covers the observable validator result as `OK` or `VE` (`ValidationError`). It abstracts regex, URL splitting, punycode, IPv6 validation, and hostname-length validation as predicates because the FVK audit is focused on branch ordering and unsafe-character preservation across Python versions.

B-001. Non-string input: result `VE`.

B-002. String input with any character in `{TAB, CR, LF}`: result `VE`.

B-003. String input with no unsafe character and a scheme outside `self.schemes`: result `VE`.

B-004. String input with no unsafe character, allowed scheme, direct regex match, valid IPv6 if applicable, and hostname length at most 253: result `OK`.

B-005. String input with no unsafe character, allowed scheme, direct regex failure, successful `urlsplit()`, successful `punycode(netloc)`, reconstructed URL passing regex, and hostname length at most 253: result `OK`.

B-006. String input with no unsafe character where direct regex validation fails and the IDN fallback cannot split, cannot punycode, or the reconstructed URL still fails regex: result `VE`.

B-007. String input with no unsafe character that otherwise passes but has invalid IPv6 or hostname length greater than 253: result `VE`.

## Formal claims

The K formal core is in:

- `fvk/mini-urlvalidator.k`
- `fvk/urlvalidator-spec.k`

Claim summary:

C-NONSTR. For all values `V`, if `isStr(V)` is false, `validate(V)` rewrites to `VE`.

C-UNSAFE. For all values `V`, if `isStr(V)` and `hasUnsafe(V)`, `validate(V)` rewrites to `VE`.

C-BAD-SCHEME. For all values `V`, if `isStr(V)`, `not hasUnsafe(V)`, and `schemeAllowed(V)` is false, `validate(V)` rewrites to `VE`.

C-DIRECT-ACCEPT. For all values `V`, if `isStr(V)`, `not hasUnsafe(V)`, `schemeAllowed(V)`, `directRegexOK(V)`, `not ipv6Bad(V)`, and `not hostTooLong(V)`, `validate(V)` rewrites to `OK`.

C-FALLBACK-ACCEPT. For all values `V`, if `isStr(V)`, `not hasUnsafe(V)`, `schemeAllowed(V)`, direct regex fails, splitting succeeds, punycode succeeds, fallback regex succeeds, and `not hostTooLong(V)`, `validate(V)` rewrites to `OK`.

C-REGEX-REJECT. For all values `V`, if `isStr(V)`, `not hasUnsafe(V)`, `schemeAllowed(V)`, direct regex fails, and at least one fallback prerequisite fails, `validate(V)` rewrites to `VE`.

C-HOST-REJECT. For all values `V`, if `isStr(V)`, `not hasUnsafe(V)`, `schemeAllowed(V)`, the regex/fallback path otherwise accepts, but IPv6 is invalid or hostname is too long, `validate(V)` rewrites to `VE`.

C-NO-UNSAFE-FRAME. For all values `V` where `hasUnsafe(V)` is false, the V1 guard does not change which later regex, split, punycode, IPv6, or hostname branch is evaluated.

## Adequacy audit

A-001. C-UNSAFE matches I-003 exactly: the formal unsafe family is LF, CR, and tab, from E-003. Status: pass.

A-002. C-UNSAFE entails both reported failures in E-004 because both contain LF. Status: pass.

A-003. C-NO-UNSAFE-FRAME matches I-002 and I-004: values without unsafe characters proceed through existing URLValidator logic. Status: pass.

A-004. C-NONSTR and C-BAD-SCHEME preserve existing public invalid-input behavior from docs and public tests. Status: pass.

A-005. The abstraction does not prove Python's regex engine, `urlsplit()`, `punycode()`, or IPv6 validator. It proves the branch ordering and unsafe-character rejection property over those predicates. Status: intentional proof boundary; keep broader URL tests.

## Public compatibility audit

PC-001. Constructor signature unchanged: `URLValidator(schemes=None, regex=None, message=None, code=None)` still works. Status: pass.

PC-002. Default construction unchanged: `URLValidator()` still takes no arguments in form/model fields. Status: pass.

PC-003. Return/error shape unchanged: the validator still returns `None` on success and raises `ValidationError` on failure; the formal model records these as `OK` and `VE`. Status: pass.

PC-004. `URLField.to_python()` still performs its existing normalization before validators run. The V1 change only affects later validation by `URLValidator`. Status: pass.

PC-005. No public test files or signatures were modified. Status: pass.
