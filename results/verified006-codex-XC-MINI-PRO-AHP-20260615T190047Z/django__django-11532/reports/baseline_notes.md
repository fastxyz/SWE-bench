# Baseline Notes

## Root cause

`EmailMessage.message()` creates a default `Message-ID` with `email.utils.make_msgid(domain=DNS_NAME)`. `DNS_NAME` is a cached wrapper around `socket.getfqdn()`, and before this change it returned the hostname exactly as reported by the system.

When the system hostname contains non-ASCII characters and the email message uses a non-Unicode encoding such as `iso-8859-1`, the generated `Message-ID` header contains that Unicode hostname. Header assignment then routes the non-address header through `email.header.Header(val, encoding).encode()`, which attempts to encode the entire `Message-ID` with the message encoding and raises `UnicodeEncodeError` for characters outside that charset.

Domain names in email headers should be ASCII-compatible. The missing normalization was in the cached DNS name layer, not in the header encoder.

## Files changed

`repo/django/core/mail/utils.py`

The cached FQDN is now checked for ASCII when it is first read from `socket.getfqdn()`. If it contains non-ASCII characters, it is converted to IDNA/punycode with `encode('idna').decode('ascii')` before being cached. This ensures that `DNS_NAME.__str__()` and `DNS_NAME.get_fqdn()` both return an ASCII-compatible domain for `Message-ID` generation and other mail uses such as SMTP `local_hostname`.

## Assumptions and alternatives considered

I assumed the correct behavior is to preserve ASCII hostnames unchanged and convert only non-ASCII hostnames to their IDNA ASCII form. That matches Django's existing handling of non-ASCII email address domains in `sanitize_address()`.

I considered changing `EmailMessage.message()` to pass an IDNA-encoded value only for `make_msgid()`, but rejected that because `DNS_NAME` is the shared source of the mail hostname and the same Unicode hostname can also flow into SMTP connection setup.

I considered changing `forbid_multi_line_headers()` to special-case `Message-ID`, but rejected that because the header encoding code is not the source of the invalid domain; it is correctly failing on a non-ASCII value that should have been normalized before becoming part of a structured message identifier.
