# Findings

Status: constructed, not machine-checked. Findings do not depend on executing tests or K tooling.

## F1: V1 missed the direct `DNS_NAME` substitution path

- Classification: code bug in V1, resolved in V2.
- Evidence: E4 and PO5.
- Input: `DNS_NAME` at the `django.core.mail.message` use site is the Unicode domain `"漢字"`; `EmailMessage.encoding = "iso-8859-1"`; no explicit `Message-ID` header.
- V1 observed behavior by source reasoning: `EmailMessage.message()` passed `DNS_NAME` directly to `make_msgid()`. If `DNS_NAME` was a raw string rather than `CachedDnsName`, the default `Message-ID` contained raw `"漢字"`, and assignment through `SafeMIMEText.__setitem__()` could reproduce the `UnicodeEncodeError` path from the issue.
- Expected behavior: the generated `Message-ID` contains `"xn--p8s937b"` and does not crash due to the domain.
- V2 change: `EmailMessage.message()` now calls `make_msgid(domain=punycode(DNS_NAME))`.
- Status: RESOLVED.

## F2: V1 correctly handled the real cached hostname path

- Classification: positive finding retained in V2.
- Evidence: E2, E3, E6, PO3.
- Input: first `DNS_NAME.get_fqdn()` sees `socket.getfqdn()` return a non-ASCII hostname such as `"正宗"` or `"漢字"`.
- V1/V2 expected behavior: the cached `_fqdn` value is IDNA/punycode ASCII.
- V2 change: the logic is factored through `punycode()` to avoid duplicating the conversion rule.
- Status: CONFIRMED.

## F3: Invalid IDNA hostnames remain outside the specified domain

- Classification: missing public requirement / residual risk.
- Evidence: domain assumptions in `INTENT_SPEC.md`.
- Input: a hostname whose `str()` form is non-ASCII and rejected by Python's IDNA codec.
- Observed behavior by source reasoning: `punycode()` would propagate the codec error.
- Expected behavior: unspecified by the public issue, which only describes valid Unicode hostnames and punycode conversion.
- Recommended next question: Should invalid hostnames be rejected with a Django-specific error, left to propagate the IDNA codec error, or handled by a fallback?
- Status: OPEN, out of scope for this fix.

## F4: Proof artifacts are constructed, not machine-checked

- Classification: proof process limitation.
- Evidence: FVK honesty gate.
- Input: the emitted `.k` files and proof commands.
- Observed behavior: commands were recorded but not executed, as required by this task.
- Expected behavior before deleting or weakening tests: run `kompile` and `kprove` and require `#Top`.
- Status: OPEN verification caveat; no source-code change required.
