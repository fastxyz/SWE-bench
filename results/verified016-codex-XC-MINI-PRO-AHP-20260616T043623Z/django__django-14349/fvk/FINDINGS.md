# FINDINGS

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F-001: Root cause confirmed

Input: `http://www.djangoproject.com/\n`

Observed in the issue on Python versions patched for bpo-43882: `URLValidator` did not raise `ValidationError`.

Expected from public intent: `ValidationError`, because the public test evidence says trailing newlines are not accepted and the issue identifies LF, CR, and tab as forbidden characters that `urlsplit()` can strip before validation.

Cause: pre-V1 control flow allowed a regex failure to enter the IDN fallback. Patched `urlsplit()` removed the newline, `urlunsplit()` reconstructed a clean URL, and the second regex pass accepted that clean URL. V1 adds an early unsafe-character guard before the fallback.

Classification: code bug fixed by V1.

Related obligations: PO-001, PO-002, PO-003, PO-004.

## F-002: Unsafe-character family is complete for the public issue

Input family: any string containing `\n`, `\r`, or `\t`.

Observed in V1 source: `unsafe_chars = frozenset('\t\r\n')` and `any(char in value for char in self.unsafe_chars)` runs before scheme validation and `urlsplit()`.

Expected from public intent: reject exactly the LF, CR, and tab family described by the issue. The public report says Python strips "all instances of LF, CR and tab characters before splitting."

Classification: V1 satisfies the public unsafe-character family.

Related obligations: PO-003, PO-004.

## F-003: Reported IPv6 newline case is covered by the same guard

Input: `http://[::ffff:192.9.5.5]\n`

Observed in V1 source: the LF is detected before direct regex validation, IDN fallback, IPv6 netloc parsing, or hostname-length checks.

Expected from public intent: `ValidationError`.

Classification: code bug fixed by V1; no separate IPv6-specific source edit is needed.

Related obligations: PO-002, PO-004, PO-006.

## F-004: Valid URL and IDN paths are framed for inputs without unsafe characters

Input family: strings with no LF, CR, or tab.

Observed in V1 source: after the new guard evaluates false, the previous scheme, regex, IDN fallback, IPv6 validation, and hostname-length control flow is unchanged.

Expected from docs: literal IPv6 addresses and Unicode domains remain supported.

Classification: compatibility/frame condition satisfied; V1 can stand unchanged.

Related obligations: PO-005, PO-007.

## F-005: Public API compatibility passed

Input/callsite family: `URLValidator()`, `URLValidator(EXTENDED_SCHEMES)`, form/model default validators.

Observed in V1 source: no constructor signature, call signature, return type, exception type, or default-validator callsite changed.

Expected from docs and public callsites: existing usage stays valid.

Classification: compatibility passed.

Related obligations: PO-007.

## F-006: Proof capability boundary

Input family: arbitrary URL strings whose validity depends on the full regular expression, `urlsplit()`, IDN punycode, IPv6 parsing, or hostname-length details.

Observed in FVK model: those components are represented by predicates such as `directRegexOK(V)`, `splitOK(V)`, `punycodeOK(V)`, `fallbackRegexOK(V)`, `ipv6Bad(V)`, and `hostTooLong(V)`.

Expected from FVK methodology: minimal semantics must still represent the property under verification. The unsafe-character property is represented directly by `hasUnsafe(V)`, so the proof is property-complete for the reported issue, but not a full proof of URL syntax correctness.

Classification: proof capability boundary; keep broader URL syntax and integration tests.

Related obligations: PO-008, PO-009.

## Overall verdict

The FVK audit confirms V1. No additional source edit is justified by the public intent or proof obligations.
