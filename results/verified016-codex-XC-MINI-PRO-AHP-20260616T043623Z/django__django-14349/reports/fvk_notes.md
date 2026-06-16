# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Decision

V1 stands unchanged.

The decisive finding is `fvk/FINDINGS.md` F-001: the root cause is the IDN fallback accepting a URL after patched `urlsplit()` strips LF/CR/tab. The decisive proof obligations are `fvk/PROOF_OBLIGATIONS.md` PO-001 through PO-004: reject LF/CR/tab, cover the reported examples, cover the complete public unsafe-character family, and do so before `urlsplit()`.

V1 satisfies those obligations with the existing source change in `repo/django/core/validators.py`: `unsafe_chars = frozenset('\t\r\n')` and the early `any(char in value for char in self.unsafe_chars)` `ValidationError` branch.

## Why no additional source edit was made

No additional edit is justified because F-002 and PO-003 show the V1 character set exactly matches the public family from the issue: tab, carriage return, and line feed.

No IPv6-specific edit is needed because F-003 and PO-006 show the reported IPv6 URL fails for the same LF reason before IPv6 parsing is reached, while existing IPv6 validation remains in place for inputs without unsafe characters.

No change to the IDN fallback is needed because F-004 and PO-005 show the new guard is a frame condition for values without unsafe characters; those values continue through the existing scheme, regex, fallback, IPv6, and hostname checks.

No form/model field edit is needed because F-005 and PO-007 show the public construction and call shape remain unchanged: `URLValidator()` still works as the default validator.

## Alternatives considered

Replacing `urllib.parse.urlsplit()` with Django's private `_urlsplit()` was rejected. F-004 and PO-005 support the smaller early guard because it fixes the normalization bug without changing the IDN fallback behavior for inputs that do not contain unsafe characters.

Extending `unsafe_chars` beyond `\t`, `\r`, and `\n` was rejected. F-002 and PO-003 tie the family to the public issue evidence; adding more characters would be speculative without a new intent-ledger entry.

Accepting Python's stripped result was rejected. F-001, PO-001, and PO-002 show that public tests and issue intent require `ValidationError` for the newline-containing examples.

## Residual risk

F-006 and PO-009 record the proof boundary: the K model proves branch ordering and unsafe-character rejection for the reported issue, not the full correctness of Django's URL regex, `urlsplit()`, punycode, IPv6 validation, or hostname-length logic. Broader tests should remain.
