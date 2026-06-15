# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

### `django.core.mail.utils.punycode`

- Kind: new helper function.
- Compatibility: additive. It is not added to `django.core.mail.__all__`; no existing caller can be broken by its presence.
- Use sites: `CachedDnsName.get_fqdn()` and `EmailMessage.message()`.
- Verdict: PASS.

### `django.core.mail.utils.CachedDnsName.get_fqdn`

- Signature: unchanged.
- Return type: unchanged string.
- Behavioral change: non-ASCII hostnames are returned as ASCII-compatible IDNA/punycode instead of raw Unicode.
- Public-intent basis: E2/E3 require exactly this change for mail DNS names.
- Public callers found: `EmailBackend.open()` uses the value as SMTP `local_hostname`; `CachedDnsName.__str__()` delegates to it.
- Verdict: PASS.

### `django.core.mail.utils.CachedDnsName.__str__`

- Signature: unchanged.
- Behavioral change: follows `get_fqdn()`, so non-ASCII cached hostnames stringify as IDNA/punycode.
- Public-intent basis: `EmailMessage.message()` passes `DNS_NAME` into message-id generation through string formatting behavior.
- Verdict: PASS.

### `django.core.mail.message.EmailMessage.message`

- Signature: unchanged.
- Behavioral change: only the default `Message-ID` branch normalizes `DNS_NAME` before `make_msgid()`.
- Explicit `Message-ID` override: preserved.
- Other headers and payload construction: unchanged.
- Verdict: PASS.

## Public callsite search summary

Search terms: `DNS_NAME`, `get_fqdn(`, `make_msgid(`, and `CachedDnsName`.

Relevant callsites:

- `django/core/mail/message.py`: default `Message-ID` generation. Updated.
- `django/core/mail/backends/smtp.py`: SMTP `local_hostname` via `DNS_NAME.get_fqdn()`. Covered by utility normalization.
- `django/core/mail/__init__.py`: re-exports `DNS_NAME` and `CachedDnsName`; no signature change.

No public subclass override or virtual dispatch compatibility issue is introduced.
