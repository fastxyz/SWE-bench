# FVK Spec

Status: constructed, not machine-checked. The exact commands to check the K artifacts are recorded in `PROOF.md` and were not executed.

## Scope

The audited observable is default email `Message-ID` generation when its domain comes from Django's mail DNS-name value, plus the shared cached hostname helper that supplies that value. There are no loops in the changed code.

Audited source files:

- `repo/django/core/mail/utils.py`
- `repo/django/core/mail/message.py`

Formal companion files:

- `fvk/mini-mail-dns.k`
- `fvk/mail-dns-spec.k`

## Public Intent Ledger Summary

- E1/E5 require that a non-ASCII hostname must not make `EmailMessage.message()` crash under encodings such as `iso-8859-1`.
- E2/E3 require that hostname-derived domains are converted to ASCII-compatible IDNA/punycode before use.
- E4 makes the `message.py` use site part of the intent, not just the `socket.getfqdn()` cache path.
- E6 requires preserving lazy caching.
- E7 requires preserving explicit user-provided `Message-ID` override behavior.
- E8 confirms that IDNA is already Django's mail-domain normalization convention.

## Functional Contracts

### `punycode(domain)`

Precondition: `str(domain)` is a DNS-name-like value, and if it is non-ASCII it is accepted by Python's IDNA codec.

Postconditions:

- If `str(domain)` is ASCII, return it unchanged.
- If `str(domain)` is non-ASCII, return `str(domain).encode('idna').decode('ascii')`.
- The returned value is ASCII for all in-domain inputs.

### `CachedDnsName.get_fqdn()`

Precondition: if `_fqdn` is absent, `socket.getfqdn()` returns an in-domain DNS-name-like value.

Postconditions:

- On a cache miss, call `socket.getfqdn()`, normalize the returned hostname with `punycode()`, store that normalized value in `_fqdn`, and return it.
- On a cache hit produced by this method, return the cached normalized value without calling `socket.getfqdn()` again.
- ASCII hostnames remain unchanged; non-ASCII hostnames are cached in IDNA/punycode form.

### `EmailMessage.message()` default `Message-ID` branch

Precondition: no case-insensitive `message-id` key is present in `extra_headers`, and `DNS_NAME` stringifies to an in-domain DNS-name-like value.

Postconditions:

- The domain passed to `make_msgid()` is `punycode(DNS_NAME)`.
- The generated `Message-ID` header's domain component is ASCII-compatible.
- For a Unicode `DNS_NAME` value denoting `"漢字"`, the generated `Message-ID` contains `"xn--p8s937b"`.
- Header assignment is not forced into a non-ASCII `Message-ID` encoding failure by the domain.

### `EmailMessage.message()` explicit `Message-ID` override branch

Precondition: `extra_headers` contains a case-insensitive `message-id` key.

Postcondition: Django does not generate a default `Message-ID`; the user-supplied header remains the source of the message id.

## Frame Conditions

- Public method signatures are unchanged.
- `EmailMessage.message()` still sets `Date`, `Subject`, address headers, and extra headers through the existing control flow.
- The SMTP backend still obtains `local_hostname` from `DNS_NAME.get_fqdn()`, now with the same intended ASCII-compatible normalization.

## Out of Scope

Invalid hostnames that Python's IDNA codec cannot encode are outside the public issue's stated domain. The proof does not establish total correctness, performance bounds beyond preserving lazy `socket.getfqdn()` lookup, or behavior of arbitrary user-supplied explicit `Message-ID` values.
